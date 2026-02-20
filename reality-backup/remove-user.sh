#!/bin/bash

# === Удаление пользователя из VLESS Reality ===

CONFIG_FILE="/opt/xray-reality/config.json"

if [ -z "$1" ]; then
    echo "Использование: ./remove-user.sh UUID"
    echo ""
    echo "Список пользователей:"
    jq -r '.inbounds[0].settings.clients[].id' "$CONFIG_FILE" 2>/dev/null
    exit 1
fi

UUID_TO_REMOVE="$1"

# Проверяем что UUID существует
if ! jq -e ".inbounds[0].settings.clients[] | select(.id == \"$UUID_TO_REMOVE\")" "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Ошибка: UUID не найден"
    exit 1
fi

# Удаляем пользователя
jq "del(.inbounds[0].settings.clients[] | select(.id == \"$UUID_TO_REMOVE\"))" "$CONFIG_FILE" > /tmp/config.json.tmp
mv /tmp/config.json.tmp "$CONFIG_FILE"

# Перезапускаем сервис
systemctl restart xray-reality

echo "Пользователь $UUID_TO_REMOVE удалён"
