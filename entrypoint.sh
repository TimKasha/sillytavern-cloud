#!/bin/bash

# Переходим жестко в корень проекта
cd /home/node/app || exit 1

DATA_DIR="/home/node/app/data"
BACKUP_DIR="/tmp/backup_repo"

git config --global --add safe.directory '*'

# 1. Восстановление данных из репозитория
if [ -n "$GITHUB_TOKEN" ] && [ -n "$BACKUP_REPO" ]; then
    echo "==> [Restore] Проверка бэкапа из https://github.com/${BACKUP_REPO}..."
    rm -rf "$BACKUP_DIR"
    git clone --depth 1 "https://${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_DIR" 2>/dev/null

    if [ -d "$BACKUP_DIR" ]; then
        mkdir -p "$DATA_DIR"
        find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -rf {} "$DATA_DIR/" \; 2>/dev/null
        echo "==> [Restore] Данные перенесены!"
    else
        echo "==> [Restore] Репозиторий пуст, начинаем с нуля."
    fi
fi

# 2. Фоновый цикл автобэкапа (раз в 15 минут)
(
    while true; do
        sleep 900
        if [ -n "$GITHUB_TOKEN" ] && [ -n "$BACKUP_REPO" ]; then
            if [ ! -d "$BACKUP_DIR/.git" ]; then
                git clone --depth 1 "https://${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_DIR" 2>/dev/null
            fi

            if [ -d "$BACKUP_DIR/.git" ] && [ -d "$DATA_DIR" ]; then
                find "$DATA_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' -exec cp -rf {} "$BACKUP_DIR/" \; 2>/dev/null
                cd "$BACKUP_DIR" || continue
                git config user.email "bot@sillytavern.cloud"
                git config user.name "SillyTavern AutoBackup"

                if [ -n "$(git status --porcelain)" ]; then
                    git add -A
                    git commit -m "Auto-backup $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
                    git push origin main 2>/dev/null || true
                    echo "==> [Backup] Успешно сохранено!"
                fi
                cd /home/node/app || continue
            fi
        fi
    done
) &

# 3. Запуск сервера напрямую
echo "==> Запуск SillyTavern..."
exec node server.js
