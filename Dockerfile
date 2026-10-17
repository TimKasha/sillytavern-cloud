FROM ghcr.io/sillytavern/sillytavern:latest

USER root
WORKDIR /home/node/app

# Доустанавливаем git и bash для бэкапов
RUN (apt-get update && apt-get install -y --no-install-recommends git bash ca-certificates) || \
    (apk update && apk add --no-cache git bash ca-certificates)

# Заранее создаем config.yaml с отключенным автообновлением контента
RUN if [ -f "./default/config.yaml" ]; then cp ./default/config.yaml ./config.yaml; fi && \
    sed -i 's/skipContentCheck: false/skipContentCheck: true/g' ./config.yaml 2>/dev/null || true

# Полная предсборка библиотек webpack на этапе сборки образа (здесь нет лимита в 4 минуты)
RUN node ./src/fast-stats.js || true

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
