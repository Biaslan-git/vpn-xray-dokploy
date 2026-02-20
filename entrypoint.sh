#!/bin/sh

# Подставляем переменные окружения в шаблон конфига
envsubst '${UUID} ${WS_PATH}' < /etc/xray/config.template.json > /tmp/config.json

# Запускаем XRay
exec xray run -c /tmp/config.json
