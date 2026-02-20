# XRay VLESS VPN

Два варианта VPN для обхода блокировок:

| Вариант | Маскировка | Для чего |
|---------|------------|----------|
| **Cloudflare** | Обычный HTTPS | Основной, через Dokploy |
| **Reality** | Госуслуги | Backup, жёсткие белые списки |

---

## Вариант 1: Cloudflare + Dokploy

VPN через Traefik + Cloudflare CDN.

### Деплой

1. В Dokploy: **Create** → **Compose** → укажи этот репозиторий
2. В **Environment** добавь:
   ```
   DOMAIN=vpn.твой-домен.com
   UUID=твой-uuid-сюда
   WS_PATH=/ws
   ```
   UUID сгенерировать: `uuidgen`
3. **Deploy**

Несколько пользователей — UUID через запятую: `UUID=uuid1,uuid2,uuid3`

### Подключение

```
vless://UUID@ДОМЕН:443?encryption=none&security=tls&type=ws&path=/ws#VPN
```

---

## Вариант 2: Reality (одна команда)

Маскировка под госуслуги. Не требует домена и SSL.

### Установка

```bash
curl -sL "https://raw.githubusercontent.com/Biaslan-git/vpn-xray-dokploy/refs/heads/master/reality-backup/install.sh" | bash
```

Скрипт автоматически:
- Установит XRay
- Сгенерирует ключи
- Создаст systemd сервис
- Выдаст ссылку для клиента

### Управление пользователями

```bash
cd /opt/xray-reality
./add-user.sh Имя       # добавить
./list-users.sh         # список со ссылками
./remove-user.sh UUID   # удалить
```

### Управление сервисом

```bash
systemctl status xray-reality    # статус
systemctl restart xray-reality   # перезапуск
journalctl -u xray-reality -f    # логи
```

---

## Клиенты

- **Android**: v2rayNG, NekoBox
- **iOS**: Shadowrocket, Streisand
- **Windows/Mac/Linux**: Nekoray
