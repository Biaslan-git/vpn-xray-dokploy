FROM ghcr.io/xtls/xray-core:latest

# Устанавливаем envsubst (из gettext)
RUN apk add --no-cache gettext

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
