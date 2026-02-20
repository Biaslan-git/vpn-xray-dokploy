FROM ghcr.io/xtls/xray-core:latest AS xray

FROM alpine:latest

# Устанавливаем envsubst
RUN apk add --no-cache gettext

# Копируем xray из официального образа
COPY --from=xray /usr/bin/xray /usr/bin/xray

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
