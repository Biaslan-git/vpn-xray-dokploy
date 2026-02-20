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

# Создаём вспомогательные скрипты напрямую (без внешних загрузок)

# add-user.sh
cat > /opt/xray-reality/add-user.sh << 'SCRIPT'
#!/bin/bash
set -e
CONFIG_FILE="/opt/xray-reality/config.json"
PUBLIC_KEY_FILE="/opt/xray-reality/public.key"
[ ! -f "$CONFIG_FILE" ] && echo "Конфиг не найден" && exit 1
USER_NAME="${1:-User}"
NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")
SERVER_IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -s ifconfig.me)
[[ "$SERVER_IP" == *":"* ]] && SERVER_IP="[$SERVER_IP]"
jq ".inbounds[0].settings.clients += [{\"id\": \"$NEW_UUID\", \"flow\": \"xtls-rprx-vision\"}]" "$CONFIG_FILE" > /tmp/config.json.tmp
mv /tmp/config.json.tmp "$CONFIG_FILE"
systemctl restart xray-reality
echo ""
echo "Пользователь добавлен: $USER_NAME"
echo "UUID: $NEW_UUID"
echo ""
echo "Ссылка:"
echo "vless://$NEW_UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.gosuslugi.ru&fp=chrome&pbk=$PUBLIC_KEY&type=tcp#$USER_NAME"
SCRIPT

# list-users.sh
cat > /opt/xray-reality/list-users.sh << 'SCRIPT'
#!/bin/bash
CONFIG_FILE="/opt/xray-reality/config.json"
PUBLIC_KEY_FILE="/opt/xray-reality/public.key"
[ ! -f "$CONFIG_FILE" ] && echo "Конфиг не найден" && exit 1
SERVER_IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -s ifconfig.me)
[[ "$SERVER_IP" == *":"* ]] && SERVER_IP="[$SERVER_IP]"
PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE" 2>/dev/null || echo "UNKNOWN")
echo ""
echo "=== Пользователи ==="
echo "Статус: $(systemctl is-active xray-reality)"
echo ""
i=1
for UUID in $(jq -r '.inbounds[0].settings.clients[].id' "$CONFIG_FILE"); do
    echo "[$i] $UUID"
    echo "    vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.gosuslugi.ru&fp=chrome&pbk=$PUBLIC_KEY&type=tcp#User$i"
    echo ""
    ((i++))
done
echo "Всего: $((i-1))"
SCRIPT

# remove-user.sh
cat > /opt/xray-reality/remove-user.sh << 'SCRIPT'
#!/bin/bash
CONFIG_FILE="/opt/xray-reality/config.json"
[ -z "$1" ] && echo "Использование: ./remove-user.sh UUID" && jq -r '.inbounds[0].settings.clients[].id' "$CONFIG_FILE" 2>/dev/null && exit 1
UUID_TO_REMOVE="$1"
jq -e ".inbounds[0].settings.clients[] | select(.id == \"$UUID_TO_REMOVE\")" "$CONFIG_FILE" > /dev/null 2>&1 || { echo "UUID не найден"; exit 1; }
jq "del(.inbounds[0].settings.clients[] | select(.id == \"$UUID_TO_REMOVE\"))" "$CONFIG_FILE" > /tmp/config.json.tmp
mv /tmp/config.json.tmp "$CONFIG_FILE"
systemctl restart xray-reality
echo "Пользователь $UUID_TO_REMOVE удалён"
SCRIPT

chmod +x /opt/xray-reality/*.sh
