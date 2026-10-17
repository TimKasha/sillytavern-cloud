#!/bin/bash
set -e

DATA_DIR="/home/node/app/data"
BACKUP_DIR="/tmp/backup_repo"

# Функция отправки данных в GitHub
push_backup() {
    if [ -n "$GITHUB_TOKEN" ] && [ -n "$BACKUP_REPO" ] && [ -d "$BACKUP_DIR/.git" ]; then
        echo "==> [Backup] Создание резервной копии данных..."
        mkdir -p "$DATA_DIR"
        cp -ru "$DATA_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true

        cd "$BACKUP_DIR"
        git config user.email "bot@sillytavern.cloud"
        git config user.name "SillyTavern AutoBackup"

        if [ -n "$(git status --porcelain)" ]; then
            git add -A
            git commit -m "Auto-backup $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
            git push origin main || echo "==> [Backup] Ошибка git push, повторим в следующий цикл."
            echo "==> [Backup] Успешно сохранено в GitHub!"
        else
            echo "==> [Backup] Изменений нет, пуш пропущен."
        fi
        cd /home/node/app
    fi
}

# 1. Восстановление данных при старте
if [ -n "$GITHUB_TOKEN" ] && [ -n "$BACKUP_REPO" ]; then
    echo "==> [Restore] Клонирование бэкапа из github.com/${BACKUP_REPO}..."
    rm -rf "$BACKUP_DIR"
    git clone "https://${GITHUB_TOKEN}@github.com/${BACKUP_REPO}.git" "$BACKUP_DIR" || echo "==> [Restore] Репозиторий пуст или ошибка доступа."

    if [ -d "$BACKUP_DIR" ]; then
        mkdir -p "$DATA_DIR"
        cp -ru "$BACKUP_DIR"/* "$DATA_DIR/" 2>/dev/null || true
        # Убираем .git из рабочей папки таверны, чтобы не мешался
        rm -rf "$DATA_DIR/.git"
        echo "==> [Restore] Данные успешно восстановлены в data/"
    fi
fi

# 2. Перехват сигналов остановки контейнера (SIGTERM / SIGINT)
cleanup() {
    echo "==> [Shutdown] Получен сигнал завершения. Экстренный бэкап перед сном контейнера..."
    push_backup
    if [ -n "$APP_PID" ]; then
        kill -TERM "$APP_PID" 2>/dev/null || true
        wait "$APP_PID"
    fi
    exit 0
}
trap cleanup SIGTERM SIGINT

# 3. Фоновый процесс периодического бэкапа (раз в 15 минут)
(
    while true; do
        sleep 900
        push_backup
    done
) &

# 4. Запуск SillyTavern
echo "==> Запуск SillyTavern сервера..."
node src/server-init.js &
APP_PID=$!
wait "$APP_PID"
