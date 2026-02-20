# XRay VLESS + WebSocket + TLS + Cloudflare

VPN через Dokploy/Traefik + Cloudflare CDN. Трафик идёт через Cloudflare — сложнее заблокировать.

## Деплой в Dokploy

### 1. Создай Compose-сервис

1. В Dokploy: **Create** → **Compose**
2. Укажи Git-репозиторий
3. В **Environment** добавь:
   ```
   DOMAIN=vpn.твой-домен.com
   ```
4. **Deploy**

### 2. Настрой домен

В Dokploy добавь домен `vpn.твой-домен.com` → направь на сервис.

Traefik автоматически получит Let's Encrypt сертификат.

---

## Подключение клиента

### Данные

| Параметр | Значение |
|----------|----------|
| Address | vpn.твой-домен.com |
| Port | 443 |
| UUID | `dee46f90-cbe4-4474-a4ac-cae0e4149eb4` |
| Security | tls |
| Transport | ws (WebSocket) |
| Path | /ws |

### VLESS ссылка

```
vless://dee46f90-cbe4-4474-a4ac-cae0e4149eb4@vpn.твой-домен.com:443?encryption=none&security=tls&type=ws&path=/ws#VPN
```

### Клиенты

- **Android**: v2rayNG, NekoBox
- **iOS**: Shadowrocket, Streisand
- **Windows/Mac/Linux**: Nekoray

---

## Настройка в v2rayNG

1. **+** → **Ввод вручную** → **VLESS**
2. Заполни:
   - Address: `vpn.твой-домен.com`
   - Port: `443`
   - UUID: `dee46f90-cbe4-4474-a4ac-cae0e4149eb4`
   - Flow: пусто
   - TLS: tls
   - Transport: ws
   - Path: `/ws`
3. Сохрани и подключайся
