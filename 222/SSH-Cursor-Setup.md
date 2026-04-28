# Cursor SSH Setup — 222-DE-NetCup
> v2026-04-02 | = Rooted by VladiMIR | AI =

---

## 🎯 Goal
Connect Cursor IDE on Windows to server **222-DE-NetCup** (xxx.xxx.xxx.222) via SSH on port 2222,
and through it (ProxyJump) to all other servers on port 22.

---

## 🖥 Servers

| Host | IP | Port | Panel |
|------|----|------|-------|
| 222-DE-NetCup | xxx.xxx.xxx.222 | **2222** | FASTPANEL |
| fastvds (109) | xxx.xxx.xxx.109 | 22 | FASTPANEL |
| alex47, 4ton237, tatra9, shahin227, stolb24, pilik178, ilya176, so38 | various | 22 | via ProxyJump |

> ⚠️ Full IPs → private `Secret_Privat` repository only.

---

## ❌ Problems encountered and how they were solved

### Problem 1 — SSH was listening only on IPv6 `[::]`, not on `0.0.0.0`
**Symptom:** `Connection refused` when connecting from Windows
```
ssh: connect to host xxx.xxx.xxx.222 port 2222: Connection refused
```
**Cause:** `ssh.socket` (systemd) manages ports in Ubuntu 24, not `sshd_config`.
By default it listened only on `[::]` without explicit `0.0.0.0`.

**Fix:**
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
**Verify:**
```bash
ss -tlnp | grep -E ':22|:2222'
# Should show 4 lines: 0.0.0.0:22, 0.0.0.0:2222, [::]:22, [::]:2222
```

---

### Problem 2 — UFW was not open for port 2222
**Symptom:** Connection refused even after socket configuration

**Fix:**
```bash
ufw allow 2222/tcp
ufw allow 22/tcp
ufw status
```

---

### Problem 3 — Wrong key filename in config
**Symptom:** `ssh-keygen: id_ed25519_222: No such file or directory`

**Cause:** Config on Windows referenced a non-existent file `id_ed25519_222`

**Fix:** Correct the filename or create a new key (see below)

---

### Problem 4 — Windows public key was not added to authorized_keys
**Symptom:** Cursor hung on `Waiting for SSH handshake`, PowerShell asked for password
```
debug1: Authentications that can continue: publickey,password
debug1: Next authentication method: password
```
**Cause:** The `id_ed25519.pub` file on Windows was the **server's own key** (`root@222-DE-NetCup`),
not the Windows machine key — it had been accidentally copied from the server earlier!

**Fix:** Create a new key on Windows:
```powershell
ssh-keygen -t ed25519 -C "VladiMIR-Windows" -f "$HOME\.ssh\id_ed25519_win"
cat "$HOME\.ssh\id_ed25519_win.pub"
```
Add to server (replace with actual public key):
```bash
echo "<PASTE_PUBLIC_KEY_HERE>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```
> ⚠️ Actual public keys → `Secret_Privat` repo only.

---

## ✅ Final working configuration

### /etc/ssh/sshd_config on 222-DE-NetCup
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

### C:\Users\USER\.ssh\config on Windows
```
Host netcup
    HostName <FULL_IP_FROM_SECRET_REPO>
    User root
    Port 2222
    IdentityFile C:\\Users\\USER\\.ssh\\id_ed25519_win

# All other servers go through netcup (ProxyJump)
Host fastvds alex47 4ton237 tatra9 shahin227 stolb24 pilik178 ilya176 so38
    User root
    Port 22
    IdentityFile C:\\Users\\USER\\.ssh\\id_ed25519_win
    ProxyJump netcup
```

---

## 🔑 SSH Keys

Full authorized_keys content and private key files → `Secret_Privat` repository only.

### Key files on Windows (`C:\Users\USER\.ssh\`)

| File | Type | Purpose |
|------|------|---------|
| `id_ed25519_win` | Private | For connecting to all servers |
| `id_ed25519_win.pub` | Public | Added to authorized_keys on each server |
| `id_ed25519` | ⚠️ Server key! | `root@222-DE-NetCup` — do NOT use for Windows connection |
| `id_ed25519.pub` | ⚠️ Server key! | Same — do not confuse |

---

## 📋 Useful diagnostic commands

```bash
# Check which ports SSH is listening on
ss -tlnp | grep -E ':22|:2222'

# Check sshd_config
grep -E '^Port|^ListenAddress|^AddressFamily' /etc/ssh/sshd_config

# Check socket config
cat /etc/systemd/system/ssh.socket.d/listen.conf

# Check UFW
ufw status

# Check authorized_keys (on server)
cat ~/.ssh/authorized_keys
```

```powershell
# Test connection from Windows
ssh -v -p 2222 -i "$HOME\.ssh\id_ed25519_win" root@<SERVER_IP>

# List keys on Windows
dir $HOME\.ssh\
```
