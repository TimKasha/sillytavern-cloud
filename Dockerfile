FROM ghcr.io/sillytavern/sillytavern:latest

# Оставляем root — официальный образ Таверны требует прав root для записи конфигов
USER root

# Доустанавливаем git и bash для автобэкапа
RUN (apt-get update && apt-get install -y --no-install-recommends git bash ca-certificates) || \
    (apk update && apk add --no-cache git bash ca-certificates)

# Предсборка вебпака прямо во время сборки образа (чтобы не жрало время при старте)
RUN node -e "const webpack = require('webpack'); const config = require('./webpack.config.js'); webpack(config).run((err) => { if (err) console.error(err); else console.log('Webpack pre-compiled!'); process.exit(0); });" || true

# Копируем скрипт запуска
COPY entrypoint.sh /home/node/app/entrypoint.sh
RUN chmod +x /home/node/app/entrypoint.sh

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=480"
ENV PORT=8000
ENV SILLYTAVERN_PORT=8000
ENV SILLYTAVERN_LISTEN=true
ENV SILLYTAVERN_WHITELISTMODE=false

EXPOSE 8000

ENTRYPOINT ["/home/node/app/entrypoint.sh"]
