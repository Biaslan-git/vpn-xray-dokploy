#!/bin/bash

# === VLESS + Reality в одну команду ===
# Маскировка под gosuslugi.ru

set -e

# Генерируем ключи
echo "Генерация ключей..."
KEYS=$(docker run --rm ghcr.io/xtls/xray-core:latest x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public" | awk '{print $3}')

# Генерируем UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# Создаём директорию
mkdir -p /opt/xray-reality
cd /opt/xray-reality

# Создаём конфиг
cat > config.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "dest": "www.gosuslugi.ru:443",
        "serverNames": ["www.gosuslugi.ru", "gosuslugi.ru"],
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["", "0123456789abcdef"]
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

# Запускаем контейнер
docker rm -f xray-reality 2>/dev/null || true
docker run -d \
  --name xray-reality \
  --restart unless-stopped \
  --network host \
  -v /opt/xray-reality/config.json:/etc/xray/config.json:ro \
  ghcr.io/xtls/xray-core:latest

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me)

echo ""
echo "=========================================="
echo "         ГОТОВО!"
echo "=========================================="
echo ""
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "Server IP: $SERVER_IP"
echo ""
echo "Ссылка для клиента:"
echo ""
echo "vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.gosuslugi.ru&fp=chrome&pbk=$PUBLIC_KEY&type=tcp#Reality-Gosuslugi"
echo ""
echo "=========================================="
