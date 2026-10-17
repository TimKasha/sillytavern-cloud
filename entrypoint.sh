#!/bin/bash

DATA_DIR="/home/node/app/data"
BACKUP_DIR="/tmp/backup_repo"

# 1. Восстановление данных при старте (если репозиторий задан)
if [ -n "$GITHUB_TOKEN" ] && [ -n "$BACKUP_REPO" ]; then
    echo "==> [Restore] Проверка бэкапа из https://github.com/${BACKUP_REPO}..."
    rm -rf "$BACKUP_DIR"
    git clone --depth 1 "https://${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_DIR" 2>/dev/null
    
    if [ -d "$BACKUP_DIR" ]; then
        mkdir -p "$DATA_DIR"
        # Копируем всё кроме служебной папки .git
        find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -rf {} "$DATA_DIR/" \; 2>/dev/null
        echo "==> [Restore] Данные перенесены в data/"
    else
        echo "==> [Restore] Не удалось склонировать (возможно, репозиторий пока пуст). Стартуем с чистой базой."
    fi
fi

# 2. Функция создания резервной копии
push_backup() {
    if [ -n "$GITHUB_TOKEN" ] && [ -n "$BACKUP_REPO" ]; then
        if [ ! -d "$BACKUP_DIR/.git" ]; then
            git clone --depth 1 "https://${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_DIR" 2>/dev/null
        fi

        if [ -d "$BACKUP_DIR/.git" ] && [ -d "$DATA_DIR" ]; then
            echo "==> [Backup] Синхронизация данных с GitHub..."
            find "$DATA_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -rf {} "$BACKUP_DIR/" \; 2>/dev/null
            
            cd "$BACKUP_DIR" || return
            git config user.email "bot@sillytavern.cloud"
            git config user.name "SillyTavern AutoBackup"

            if [ -n "$(git status --porcelain)" ]; then
                git add -A
                git commit -m "Auto-backup $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
                git push origin main 2>/dev/null || echo "==> [Backup] Push failed, retry later."
                echo "==> [Backup] Успешно отправлено в GitHub!"
            fi
            cd /home/node/app || return
        fi
    fi
}

# 3. Фоновый процесс синхронизации раз в 15 минут
(
    while true; do
        sleep 900
        push_backup
    done
) &

# 4. Запуск сервера как основного процесса (PID 1)
echo "==> Запуск SillyTavern сервера..."
exec node src/server-init.js
