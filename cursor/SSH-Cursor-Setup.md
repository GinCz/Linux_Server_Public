# Cursor SSH Setup — 222-DE-NetCup
> v2026-04-02 | = Rooted by VladiMIR | AI =

---

## 🎯 Цель
Подключить Cursor IDE на Windows к серверу **222-DE-NetCup** (152.53.182.222) по SSH на порту 2222,
и через него (ProxyJump) ко всем остальным серверам на порту 22.

---

## 🖥 Серверы

| Хост | IP | Порт | Панель |
|------|----|------|--------|
| 222-DE-NetCup | 152.53.182.222 | **2222** | FASTPANEL |
| fastvds (109) | 212.109.223.109 | 22 | FASTPANEL |
| alex47, 4ton237, tatra9, shahin227, stolb24, pilik178, ilya176, so38 | разные | 22 | через ProxyJump |

---

## ❌ Проблемы которые встретились и как их решили

### Проблема 1 — SSH слушал только IPv6 `[::]`, не слушал `0.0.0.0`
**Симптом:** `Connection refused` при подключении с Windows
```
ssh: connect to host 152.53.182.222 port 2222: Connection refused
```
**Причина:** `ssh.socket` (systemd) управляет портами в Ubuntu 24, а не `sshd_config`.
По умолчанию слушал только `[::]` без явного `0.0.0.0`.

**Решение:**
```bash
mkdir -p /etc/systemd/system/ssh.socket.d/
cat > /etc/systemd/system/ssh.socket.d/listen.conf << 'EOF'
[Socket]
ListenStream=
ListenStream=22
ListenStream=2222
ListenStream=0.0.0.0:22
ListenStream=0.0.0.0:2222
EOF

systemctl daemon-reload
systemctl restart ssh.socket
systemctl restart sshd
```
**Проверка:**
```bash
ss -tlnp | grep -E ':22|:2222'
# Должно быть 4 строки: 0.0.0.0:22, 0.0.0.0:2222, [::]:22, [::]:2222
```

---

### Проблема 2 — UFW не был открыт для порта 2222
**Симптом:** Соединение refused даже после настройки socket

**Решение:**
```bash
ufw allow 2222/tcp
ufw allow 22/tcp
ufw status
```

---

### Проблема 3 — Неправильное имя файла ключа в config
**Симптом:** `ssh-keygen: id_ed25519_222: No such file or directory`

**Причина:** В config на Windows был указан несуществующий файл `id_ed25519_222`

**Решение:** Вернуть правильное имя файла или создать новый ключ (см. ниже)

---

### Проблема 4 — Публичный ключ Windows не был добавлен в authorized_keys
**Симптом:** Cursor зависал на `Waiting for SSH handshake`, PowerShell просил пароль
```
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: password
```
**Причина:** Файл `id_ed25519.pub` на Windows оказался ключом **самого сервера** (`root@222-DE-NetCup`),
а не Windows машины — был скопирован с сервера ранее!

**Решение:** Создать новый ключ на Windows:
```powershell
ssh-keygen -t ed25519 -C "VladiMIR-Windows" -f "$HOME\.ssh\id_ed25519_win"
cat "$HOME\.ssh\id_ed25519_win.pub"
```
Добавить на сервере:
```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcQBnsNusXZtXoxmt97Harmijm4ibe6OqR231FV7zNu VladiMIR-Windows" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## ✅ Итоговая рабочая конфигурация

### /etc/ssh/sshd_config на 222-DE-NetCup
```
Port 22
Port 2222
```

### /etc/systemd/system/ssh.socket.d/listen.conf
```ini
[Socket]
ListenStream=
ListenStream=22
ListenStream=2222
ListenStream=0.0.0.0:22
ListenStream=0.0.0.0:2222
```

### C:\Users\USER\.ssh\config на Windows
```
Host netcup
    HostName 152.53.182.222
    User root
    Port 2222
    IdentityFile C:\\Users\\USER\\.ssh\\id_ed25519_win

# Все остальные серверы идут через netcup (ProxyJump)
Host fastvds alex47 4ton237 tatra9 shahin227 stolb24 pilik178 ilya176 so38
    User root
    Port 22
    IdentityFile C:\\Users\\USER\\.ssh\\id_ed25519_win
    ProxyJump netcup
```

---

## 🔑 Ключи на сервере (~/.ssh/authorized_keys)
См. файл `cursor/authorized_keys.md`

---

## 📋 Полезные команды для диагностики

```bash
# Проверить какие порты слушает SSH
ss -tlnp | grep -E ':22|:2222'

# Проверить sshd_config
grep -E '^Port|^ListenAddress|^AddressFamily' /etc/ssh/sshd_config

# Проверить socket конфиг
cat /etc/systemd/system/ssh.socket.d/listen.conf

# Проверить UFW
ufw status

# Проверить authorized_keys
cat ~/.ssh/authorized_keys
```

```powershell
# Тест подключения с Windows
ssh -v -p 2222 -i "$HOME\.ssh\id_ed25519_win" root@152.53.182.222

# Список ключей на Windows
dir $HOME\.ssh\
```
