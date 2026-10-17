FROM ghcr.io/sillytavern/sillytavern:latest

USER root
WORKDIR /home/node/app

# Доустанавливаем git и bash для бэкапов
RUN (apt-get update && apt-get install -y --no-install-recommends git bash ca-certificates) || \
    (apk update && apk add --no-cache git bash ca-certificates)

# Копируем дефолтный конфиг сразу, чтобы убрать warning и исключить падение
RUN if [ -f "./default/config.yaml" ]; then cp ./default/config.yaml ./config.yaml; fi

# Штатная компиляция фронтенда через webpack-cli проекта
RUN npx webpack --mode production || true

# Копируем и даем права на entrypoint
COPY entrypoint.sh /home/node/app/entrypoint.sh
RUN chmod 777 /home/node/app/entrypoint.sh

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=480"
ENV PORT=8000
ENV SILLYTAVERN_PORT=8000
ENV SILLYTAVERN_LISTEN=true
ENV SILLYTAVERN_WHITELISTMODE=false

EXPOSE 8000

CMD ["/bin/bash", "/home/node/app/entrypoint.sh"]
