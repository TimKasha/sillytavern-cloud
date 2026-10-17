#!/bin/bash

DATA_DIR="/home/node/app/data"
BACKUP_DIR="/tmp/backup_repo"

# Разрешаем git работать под root с любыми директориями
git config --global --add safe.directory '*'

# 1. Восстановление данных при старте
if [ -n "$GITHUB_TOKEN" ] && [ -n "$BACKUP_REPO" ]; then
    echo "==> [Restore] Проверка бэкапа из https://github.com/${BACKUP_REPO}..."
    rm -rf "$BACKUP_DIR"
    git clone --depth 1 "https://${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_DIR" 2>/dev/null

    if [ -d "$BACKUP_DIR" ]; then
        mkdir -p "$DATA_DIR"
        find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -rf {} "$DATA_DIR/" \; 2>/dev/null
        echo "==> [Restore] Данные успешно подтянуты из GitHub!"
    else
        echo "==> [Restore] Репозиторий пока пуст или не найден. Начнем с чистой базы."
    fi
fi

# 2. Функция сохранения
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
                git push origin main 2>/dev/null || echo "==> [Backup] Push не удался, повторим позже."
                echo "==> [Backup] Успешно отправлено в GitHub!"
            fi
            cd /home/node/app || return
        fi
    fi
}

# 3. Автосохранение каждые 15 минут в фоне
(
    while true; do
        sleep 900
        push_backup
    done
) &

# 4. Запуск сервера напрямую из рабочей директории
cd /home/node/app
echo "==> Запуск SillyTavern сервера..."
exec node src/server-init.js
