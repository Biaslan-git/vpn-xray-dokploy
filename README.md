# XRay VLESS + Reality VPN

VPN-сервер с обфускацией трафика под HTTPS. Обходит DPI и белые списки.

Маскируется под gosuslugi.ru — гарантированно в белом списке РФ.

## Настройка

### 1. Сгенерируйте ключи на сервере

```bash
docker run --rm ghcr.io/xtls/xray-core:latest xray x25519
```

Вывод:
```
Private key: <PRIVATE_KEY>
Public key: <PUBLIC_KEY>
```

### 2. Замените ключ в config/config.json

Замените `REPLACE_WITH_PRIVATE_KEY` на ваш Private key.

### 3. Деплой в Dokploy

1. Создайте репозиторий на GitHub
2. В Dokploy: Create → Compose → укажите репозиторий
3. Порт 443 должен быть открыт

## Подключение клиента

### Данные для подключения

| Параметр | Значение |
|----------|----------|
| Address | IP вашего сервера |
| Port | 443 |
| UUID | `dee46f90-cbe4-4474-a4ac-cae0e4149eb4` |
| Flow | xtls-rprx-vision |
| Security | reality |
| SNI | www.gosuslugi.ru |
| Fingerprint | chrome |
| Public Key | (ваш PUBLIC_KEY) |
| shortId | (пусто или `0123456789abcdef`) |

### Клиенты

- **Android**: v2rayNG, NekoBox
- **iOS**: Shadowrocket, Streisand
- **Windows**: Nekoray, v2rayN
- **macOS**: Nekoray, V2Box
- **Linux**: Nekoray

### VLESS ссылка (для импорта)

```
vless://dee46f90-cbe4-4474-a4ac-cae0e4149eb4@YOUR_SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.gosuslugi.ru&fp=chrome&pbk=YOUR_PUBLIC_KEY&type=tcp#MyVPN
```

Замените:
- `YOUR_SERVER_IP` — IP сервера
- `YOUR_PUBLIC_KEY` — Public key (из шага 1)
