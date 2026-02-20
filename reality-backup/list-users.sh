#!/bin/bash

# === Список всех пользователей VLESS Reality ===

CONFIG_FILE="/opt/xray-reality/config.json"
PUBLIC_KEY_FILE="/opt/xray-reality/public.key"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Ошибка: конфиг не найден"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    apt-get update && apt-get install -y jq
fi

SERVER_IP=$(curl -s ifconfig.me)
PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE" 2>/dev/null || echo "UNKNOWN")

echo ""
echo "=========================================="
echo "         Все пользователи"
echo "=========================================="
echo ""

# Получаем всех клиентов
CLIENTS=$(jq -r '.inbounds[0].settings.clients[].id' "$CONFIG_FILE")

i=1
for UUID in $CLIENTS; do
    echo "[$i] UUID: $UUID"
    echo "    Ссылка: vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.gosuslugi.ru&fp=chrome&pbk=$PUBLIC_KEY&type=tcp#User$i"
    echo ""
    ((i++))
done

echo "=========================================="
echo "Всего пользователей: $((i-1))"
echo "=========================================="
