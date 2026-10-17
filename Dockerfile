FROM ghcr.io/sillytavern/sillytavern:latest

USER root
WORKDIR /home/node/app

# Доустанавливаем git и bash для бэкапов
RUN (apt-get update && apt-get install -y --no-install-recommends git bash ca-certificates) || \
    (apk update && apk add --no-cache git bash ca-certificates)

# Предсборка ассетов прямо во время сборки Dockerfile:
# Запускаем server-init с переменной окружения на 60 секунд. 
# На серверах сборщика Render мощный CPU — Webpack скомпилирует всё за 15-20 секунд и сохранит в слой образа.
RUN timeout 90s node src/server-init.js || true

# Копируем entrypoint
COPY entrypoint.sh /home/node/app/entrypoint.sh
RUN chmod +x /home/node/app/entrypoint.sh

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=480"
ENV PORT=8000
ENV SILLYTAVERN_PORT=8000
ENV SILLYTAVERN_LISTEN=true
ENV SILLYTAVERN_WHITELISTMODE=false

EXPOSE 8000

CMD ["/bin/bash", "/home/node/app/entrypoint.sh"]
