# SSH Authorized Keys — 222-DE-NetCup
> v2026-04-02 | = Rooted by VladiMIR | AI =
> ⚠️ ПРИВАТНЫЙ ФАЙЛ — не публиковать публично!

---

## ~/.ssh/authorized_keys на сервере 152.53.182.222

### Ключ 1 — VladiMir-HP (старый компьютер #1)
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFgiij002E/AxqPXkBAaH0KT61TSn20FERXcm7GmsBa user@VladiMir-HP
```

### Ключ 2 — VladiMir-HP (старый компьютер #2)
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPGeywmt++jfg4gLyZwq6DwMWZpB25RjO7S49Zp6/UrT user@VladiMir-HP
```

### Ключ 3 — VladiMIR-Windows (новый, создан 02.04.2026 для Cursor)
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcQBnsNusXZtXoxmt97Harmijm4ibe6OqR231FV7zNu VladiMIR-Windows
```

---

## 📁 Файлы ключей на Windows (C:\Users\USER\.ssh\)

| Файл | Тип | Назначение |
|------|-----|------------|
| `id_ed25519_win` | Приватный | Для подключения к серверам |
| `id_ed25519_win.pub` | Публичный | Добавлен в authorized_keys сервера |
| `id_ed25519` | ⚠️ Это ключ сервера! | Не использовать для Windows подключения |
| `id_ed25519.pub` | ⚠️ Это ключ сервера! | root@222-DE-NetCup — не путать! |

---

## ⚠️ Важные замечания

- Файл `id_ed25519` на Windows — это публичный ключ **самого сервера** (`root@222-DE-NetCup`),
  был случайно скопирован туда ранее. НЕ использовать его для подключения с Windows!
- Рабочий ключ для Cursor и PowerShell: **`id_ed25519_win`**
- При добавлении нового компьютера — создать новый ключ и добавить в authorized_keys

---

## 🔧 Как добавить новый компьютер

### На новом компьютере (PowerShell/Terminal):
```powershell
ssh-keygen -t ed25519 -C "VladiMIR-НазваниеКомпа" -f "$HOME\.ssh\id_ed25519_win"
cat "$HOME\.ssh\id_ed25519_win.pub"
```

### На сервере:
```bash
echo "ПУБЛИЧНЫЙ_КЛЮЧ_СЮДА" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat ~/.ssh/authorized_keys
```
