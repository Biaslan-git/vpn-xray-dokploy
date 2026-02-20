#!/bin/bash

# === VLESS + Reality в одну команду ===
# Маскировка под gosuslugi.ru

set -e

# Устанавливаем Docker если нет
if ! command -v docker &> /dev/null; then
    echo "Docker не найден, устанавливаю..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "Docker установлен"
fi

# Генерируем ключи
echo "Генерация ключей..."
KEYS=$(docker run --rm ghcr.io/xtls/xray-core:latest x25519 2>&1)

# Парсим ключи (формат: PrivateKey: xxx / Public key: xxx или Password: xxx)
PRIVATE_KEY=$(echo "$KEYS" | grep -i "private" | awk -F': ' '{print $2}' | tr -d ' \r')
PUBLIC_KEY=$(echo "$KEYS" | grep -iE "public|password" | awk -F': ' '{print $2}' | tr -d ' \r')

# Проверяем что ключи получены
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "Ошибка генерации ключей. Вывод:"
    echo "$KEYS"
    exit 1
fi

echo "Private Key: $PRIVATE_KEY"
echo "Public Key: $PUBLIC_KEY"

# Генерируем UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# Создаём директорию
mkdir -p /opt/xray-reality
cd /opt/xray-reality

# Сохраняем public key для add-user.sh
echo "$PUBLIC_KEY" > /opt/xray-reality/public.key

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

# Получаем IP сервера (предпочитаем IPv4)
SERVER_IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -s ifconfig.me)

# Если IPv6 - оборачиваем в скобки
if [[ "$SERVER_IP" == *":"* ]]; then
    SERVER_IP="[$SERVER_IP]"
fi

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
echo "Управление пользователями:"
echo "  cd /opt/xray-reality"
echo "  ./add-user.sh Имя      - добавить юзера"
echo "  ./list-users.sh        - список юзеров"
echo "  ./remove-user.sh UUID  - удалить юзера"
echo ""

# Скачиваем вспомогательные скрипты
curl -sL https://raw.githubusercontent.com/Biaslan-git/vpn-xray-dokploy/master/reality-backup/add-user.sh -o /opt/xray-reality/add-user.sh
curl -sL https://raw.githubusercontent.com/Biaslan-git/vpn-xray-dokploy/master/reality-backup/list-users.sh -o /opt/xray-reality/list-users.sh
curl -sL https://raw.githubusercontent.com/Biaslan-git/vpn-xray-dokploy/master/reality-backup/remove-user.sh -o /opt/xray-reality/remove-user.sh
chmod +x /opt/xray-reality/*.sh
