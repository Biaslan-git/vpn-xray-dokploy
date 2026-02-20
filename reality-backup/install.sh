#!/bin/bash

# === VLESS + Reality в одну команду ===
# Маскировка под gosuslugi.ru

set -e

echo "=== Установка XRay Reality VPN ==="

# Устанавливаем зависимости
apt-get update
apt-get install -y curl unzip jq

# Скачиваем xray
echo "Скачиваю XRay..."
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then ARCH="64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64-v8a"; fi
curl -sL -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${ARCH}.zip"
unzip -o /tmp/xray.zip -d /usr/local/bin/
chmod +x /usr/local/bin/xray
rm /tmp/xray.zip

# Генерируем ключи
echo "Генерация ключей..."
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep -i "private" | sed 's/.*: *//' | tr -d ' \r\n')
PUBLIC_KEY=$(echo "$KEYS" | grep -iE "public|password" | head -1 | sed 's/.*: *//' | tr -d ' \r\n')

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "Ошибка генерации ключей"
    echo "$KEYS"
    exit 1
fi

# Генерируем UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# Создаём директорию
mkdir -p /opt/xray-reality

# Сохраняем public key
echo "$PUBLIC_KEY" > /opt/xray-reality/public.key

# Создаём конфиг
cat > /opt/xray-reality/config.json << EOF
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

# Создаём systemd сервис
cat > /etc/systemd/system/xray-reality.service << 'EOF'
[Unit]
Description=Xray Reality VPN
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/xray run -c /opt/xray-reality/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Останавливаем старый Docker контейнер если есть
docker rm -f xray-reality 2>/dev/null || true

# Запускаем сервис
systemctl daemon-reload
systemctl enable xray-reality
systemctl restart xray-reality

# Получаем IP сервера
SERVER_IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -s ifconfig.me)
if [[ "$SERVER_IP" == *":"* ]]; then
    SERVER_IP="[$SERVER_IP]"
fi

# Ждём запуска
sleep 2

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
echo ""
echo "Статус: $(systemctl is-active xray-reality)"
echo ""
echo "Управление:"
echo "  systemctl status xray-reality  - статус"
echo "  systemctl restart xray-reality - перезапуск"
echo "  journalctl -u xray-reality -f  - логи"
echo ""
echo "Управление пользователями:"
echo "  cd /opt/xray-reality"
echo "  ./add-user.sh Имя      - добавить юзера"
echo "  ./list-users.sh        - список юзеров"
echo "  ./remove-user.sh UUID  - удалить юзера"
echo ""

# Скачиваем вспомогательные скрипты
curl -sL "https://cdn.jsdelivr.net/gh/Biaslan-git/vpn-xray-dokploy@master/reality-backup/add-user.sh" -o /opt/xray-reality/add-user.sh
curl -sL "https://cdn.jsdelivr.net/gh/Biaslan-git/vpn-xray-dokploy@master/reality-backup/list-users.sh" -o /opt/xray-reality/list-users.sh
curl -sL "https://cdn.jsdelivr.net/gh/Biaslan-git/vpn-xray-dokploy@master/reality-backup/remove-user.sh" -o /opt/xray-reality/remove-user.sh
chmod +x /opt/xray-reality/*.sh
