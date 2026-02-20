FROM alpine:latest

# Устанавливаем зависимости
RUN apk add --no-cache gettext ca-certificates curl unzip

# Скачиваем xray
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="64"; \
    elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64-v8a"; fi && \
    curl -L -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${ARCH}.zip" && \
    unzip /tmp/xray.zip -d /usr/local/bin && \
    rm /tmp/xray.zip && \
    chmod +x /usr/local/bin/xray

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
