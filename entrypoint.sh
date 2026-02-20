#!/bin/sh

# Формируем JSON массив клиентов из списка UUID
# UUID может быть: "uuid1" или "uuid1,uuid2,uuid3"

CLIENTS=""
UUID_LIST=""
IFS=','
for id in $UUID; do
    # Убираем пробелы
    id=$(echo "$id" | tr -d ' ')
    if [ -n "$id" ]; then
        if [ -n "$CLIENTS" ]; then
            CLIENTS="$CLIENTS,"
        fi
        CLIENTS="$CLIENTS{\"id\":\"$id\"}"
        UUID_LIST="$UUID_LIST $id"
    fi
done

# Экспортируем для envsubst
export CLIENTS="[$CLIENTS]"
export WS_PATH="${WS_PATH:-/ws}"

# Подставляем переменные в шаблон
envsubst '${CLIENTS} ${WS_PATH}' < /etc/xray/config.template.json > /tmp/config.json

# Выводим ссылки для подключения
echo ""
echo "=========================================="
echo "       XRAY VLESS + WebSocket + TLS"
echo "=========================================="
echo ""
echo "Domain: ${DOMAIN}"
echo "Path: ${WS_PATH}"
echo ""
echo "Ссылки для подключения:"
echo ""

i=1
for id in $UUID_LIST; do
    echo "[$i] vless://${id}@${DOMAIN}:443?encryption=none&security=tls&type=ws&path=${WS_PATH}#User${i}"
    echo ""
    i=$((i+1))
done

echo "=========================================="
echo ""

# Запускаем XRay
exec /usr/local/bin/xray run -c /tmp/config.json
