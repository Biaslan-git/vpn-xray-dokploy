# XRay VLESS + WebSocket + TLS + Cloudflare

VPN через Dokploy/Traefik + Cloudflare CDN. Трафик идёт через Cloudflare — сложнее заблокировать.

## Деплой в Dokploy

### 1. Создай Compose-сервис

1. В Dokploy: **Create** → **Compose**
2. Укажи Git-репозиторий
3. В **Environment** добавь:
   ```
   DOMAIN=vpn.твой-домен.com
   UUID=твой-uuid-сюда
   WS_PATH=/ws
   ```

   UUID можно сгенерировать командой: `uuidgen`

4. **Deploy**

### 2. Настрой домен

В Dokploy добавь домен → направь на сервис.

Traefik автоматически получит Let's Encrypt сертификат.

---

## Подключение клиента

### VLESS ссылка

```
vless://UUID@ДОМЕН:443?encryption=none&security=tls&type=ws&path=/ws#VPN
```

### Клиенты

- **Android**: v2rayNG, NekoBox
- **iOS**: Shadowrocket, Streisand
- **Windows/Mac/Linux**: Nekoray

---

## Настройка в v2rayNG

1. **+** → **Ввод вручную** → **VLESS**
2. Заполни:
   - Address: `твой-домен`
   - Port: `443`
   - UUID: `твой-uuid`
   - Flow: пусто
   - TLS: tls
   - Transport: ws
   - Path: `/ws`
3. Сохрани и подключайся

---

## Reality вариант (backup)

Для обхода жёстких белых списков есть отдельный скрипт с маскировкой под госуслуги:

```bash
curl -sL https://raw.githubusercontent.com/Biaslan-git/vpn-xray-dokploy/master/reality-backup/install.sh | bash
```

См. папку `reality-backup/`.
