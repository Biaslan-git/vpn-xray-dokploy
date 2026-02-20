#!/bin/bash

# === Добавление нового пользователя в VLESS Reality ===

set -e

CONFIG_FILE="/opt/xray-reality/config.json"

# Проверяем что конфиг существует
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Ошибка: конфиг не найден: $CONFIG_FILE"
    echo "Сначала запусти install.sh"
    exit 1
fi

# Имя пользователя (опционально)
USER_NAME="${1:-User}"

# Генерируем UUID
NEW_UUID=$(cat /proc/sys/kernel/random/uuid)

# Получаем public key из конфига (нужен для ссылки)
# Его нет в конфиге, нужно хранить отдельно или получить заново
PUBLIC_KEY_FILE="/opt/xray-reality/public.key"

if [ ! -f "$PUBLIC_KEY_FILE" ]; then
    echo "Ошибка: файл с public key не найден: $PUBLIC_KEY_FILE"
    echo "Введи public key вручную:"
    read -r PUBLIC_KEY
    echo "$PUBLIC_KEY" > "$PUBLIC_KEY_FILE"
else
    PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")
fi

# Получаем IP сервера
SERVER_IP=$(curl -s ifconfig.me)

# Добавляем пользователя в конфиг с помощью jq
if ! command -v jq &> /dev/null; then
    echo "Устанавливаю jq..."
    apt-get update && apt-get install -y jq
fi

# Создаём нового клиента и добавляем в массив
jq ".inbounds[0].settings.clients += [{\"id\": \"$NEW_UUID\", \"flow\": \"xtls-rprx-vision\"}]" "$CONFIG_FILE" > /tmp/config.json.tmp
mv /tmp/config.json.tmp "$CONFIG_FILE"

# Перезапускаем контейнер
docker restart xray-reality

echo ""
echo "=========================================="
echo "       Пользователь добавлен!"
echo "=========================================="
echo ""
echo "Имя: $USER_NAME"
echo "UUID: $NEW_UUID"
echo ""
echo "Ссылка для клиента:"
echo ""
echo "vless://$NEW_UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.gosuslugi.ru&fp=chrome&pbk=$PUBLIC_KEY&type=tcp#$USER_NAME"
echo ""
echo "=========================================="
