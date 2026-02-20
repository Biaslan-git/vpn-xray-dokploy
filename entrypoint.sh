#!/bin/sh

# Формируем JSON массив клиентов из списка UUID
# UUID может быть: "uuid1" или "uuid1,uuid2,uuid3"

CLIENTS=""
IFS=','
for id in $UUID; do
    # Убираем пробелы
    id=$(echo "$id" | tr -d ' ')
    if [ -n "$id" ]; then
        if [ -n "$CLIENTS" ]; then
            CLIENTS="$CLIENTS,"
        fi
        CLIENTS="$CLIENTS{\"id\":\"$id\"}"
    fi
done

# Экспортируем для envsubst
export CLIENTS="[$CLIENTS]"
export WS_PATH="${WS_PATH:-/ws}"

# Подставляем переменные в шаблон
envsubst '${CLIENTS} ${WS_PATH}' < /etc/xray/config.template.json > /tmp/config.json

# Запускаем XRay
exec xray run -c /tmp/config.json
