FROM ghcr.io/sillytavern/sillytavern:latest

USER root

# Доустанавливаем git и bash для работы автобэкапа
RUN (apt-get update && apt-get install -y --no-install-recommends git bash ca-certificates) || \
    (apk update && apk add --no-cache git bash ca-certificates)

# Предкомпиляция ассетов на этапе сборки образа (решает проблему с таймаутом Render)
RUN npm run build || true

# Копируем скрипт автозапуска и синхронизации
COPY entrypoint.sh /home/node/app/entrypoint.sh
RUN chmod +x /home/node/app/entrypoint.sh && chown node:node /home/node/app/entrypoint.sh

USER node

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=480"
ENV PORT=8000
ENV SILLYTAVERN_PORT=8000
ENV SILLYTAVERN_LISTEN=true
ENV SILLYTAVERN_WHITELISTMODE=false

EXPOSE 8000

ENTRYPOINT ["/home/node/app/entrypoint.sh"]
