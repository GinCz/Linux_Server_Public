# 🪟 Windows Applications & Executable Suite (`Windows/`)

> **Репозиторий:** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)  
> **Автор / Архитектор:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Платформа:** Windows 7 / 8 / 10 / 11 / Server 2008–2025 (x86_64 / x86)  
> **Лицензия:** MIT — 100% Free & Open Source

---

## 🧭 Каталог Windows-приложений и исполняемых файлов (.exe)

В этой папке и подкаталогах собраны все фирменные нативные Windows-утилиты, сетевые сканеры, VPN-клиенты и сценарии автоматизации, разрабатываемые в экосистеме **GinCz + Anti-Gravity AI**.

| Приложение / Пакет | Исполняемый файл (.exe) / Скрипт | Назначение и ключевые возможности | Статус & Версия |
| :--- | :--- | :--- | :---: |
| 🌐 **[GIN-NetScan ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-NetScan)** | `GIN-NetScan_v025.exe` | Сверхскоростной нативный Win32 LAN-сканер подсети (SendARP, ICMP, mDNS Bonjour, декодер Apple-моделей, NetBIOS, 36-портовый аудит безопасности, цветные кнопки `BS_OWNERDRAW`, PE-иконка). Standalone без зависимостей. | 🟢 `v025` (Active) |
| 🛡️ **[GIN-VPN ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN/GIN-VPN)** | `GIN-VPN_v013.exe`<br>`GIN-VPN.ps1` / `GIN-VPN.bat` | Высокоскоростной нативный Xray VLESS-Reality клиент с полупрозрачным 3D Glassmorphism UI, контролем трафика, live-пингом, детекцией обновлений и официальным Windows-деинсталлятором. | 🟢 `v013` (Active) |
| ☁️ **[MEGA Drive ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/MEGA)** | `MEGA_Drive_Universal.cmd`<br>`Mount_MEGA_M.bat` | Автономный монтировщик диска MEGA (`M:`) с поддержкой 2FA, автоматическим переподключением и управлением квотой. | 🟢 Stable |
| 🛡️ **[Xray VPN Suite ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN)** | `XRAY-VPN_VladiMIR__Win-ALL_109_&&&.bat`<br>`xray.exe` | Автономные установщики Xray Core под ключ с поддержкой Windows 7/10/11 и векторным динамическим GDI+ щитом в системном трее. | 🟢 Stable |
| 🤖 **[CODEX ChatGPT ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/CODEX_ChatGPT)** | `Install_ChatGPT_Codex_Universal.cmd` | Универсальный установщик и ярлык быстрого запуска десктопного окружения ChatGPT Codex. | 🟢 Stable |
| 🔍 **System Security Audit** | `System_Security_Miner_Audit.cmd` | Глубокий аудит системы на наличие скрытых майнеров, аномальных процессов, посторонних слушающих сокетов и скрытых планировщиков задач. | 🟢 Stable |

---

## ⚡ Железный Регламент: Единственная Актуальная Копия на Рабочем Столе через MEGA

> [!IMPORTANT]
> **Правило синхронизации исполняемых файлов (.exe):**  
> При сборке, обновлении или выпуске новой версии любого Windows-приложения (`GIN-NetScan`, `GIN-VPN` и др.) соблюдается строгий стандарт:
>
> 1. **Единственная последняя копия (Single Latest Version Only):** На рабочем столе пользователя всегда присутствует **ровно одна актуальная версия** бинарника.
> 2. **Автоматическая ротация версий:** Перед загрузкой новой сборки все предыдущие устаревшие `.exe` файлы гарантированно удаляются из облачной папки рабочего стола.
> 3. **Целевой каталог синхронизации:**
>    - Облачный путь MEGA: `/MEGA/DOCS/desktop/`
>    - Локальный путь на компьютере: `D:\MEGA\DOCS\desktop\`
>    - Владелец / Аккаунт: `gin.vladimir@gmail.com`
> 4. **Сопутствующие ресурсы:** Вместе с бинарником на рабочий стол выгружается нативная высококачественная `.ico` иконка приложения.

### Команды конвейера деплоя на серверной ноде DE-222:
```bash
# 1. Удаление устаревших версий бинарников
mega-rm "/MEGA/DOCS/desktop/<old_binary_vXXX>.exe" 2>/dev/null || true

# 2. Мгновенная выгрузка последней свежей копии и иконки
mega-put -c "<path_to_new_binary_vYYY.exe>" "/MEGA/DOCS/desktop/"
mega-put -c "<path_to_icon.ico>" "/MEGA/DOCS/desktop/"
```

---

## 🛠️ Сборка бинарников из исходного кода (Go / Windows PE)

Все `.exe` приложения компилируются на центральном сервере **DE-222** кросс-компиляцией Go под целевую архитектуру `windows/amd64` с внедрением нативного ресурса иконки `rsrc`:

```bash
# 1. Генерация COFF .syso ресурса с манифестом и иконкой
rsrc -ico app_icon.ico -o rsrc_windows_amd64.syso

# 2. Монолитная сборка чистого Win32 GUI бинарника (без черного окна консоли)
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w -H=windowsgui" -o App_vXXX.exe main.go
```

---

## 📂 Структура каталога `Windows/`

```text
Windows/
├── README.md                      # Данный сводный реестр Windows-приложений
├── RULES.md                       # Регламент деплоя и синхронизации через MEGA
├── GIN-NetScan/                   # Сканер локальной сети GIN-NetScan (v025)
│   ├── main.go                    # Исходный код Win32 GUI на Go
│   ├── Gin-NetScan.ico            # Оригинальная иконка приложения
│   ├── rsrc_windows_amd64.syso    # Встроенный PE-ресурс иконки
│   ├── RULES.md                   # Локальный регламент приложения
│   └── README.md                  # Подробная документация сканера
├── VPN/
│   ├── README.md                  # Общая документация Xray VPN установщиков
│   ├── GIN-VPN/                   # Клиент GIN-VPN (v013) с Glassmorphism UI
│   │   ├── main.go                # Исходный код нативного Win32 лаунчера
│   │   ├── GIN-VPN.ps1            # Основной GUI клиент (PowerShell / WinForms)
│   │   ├── GIN-VPN.bat            # UAC авто-запускатель
│   │   ├── Uninstall.ps1          # Деинсталлятор
│   │   ├── Uninstall.cmd          # Точка входа деинсталлятора
│   │   ├── Gin-VPN.ico            # Иконка GIN-VPN
│   │   └── README.md              # Документация GIN-VPN
│   └── *.bat / *.ps1              # Универсальные установщики Xray VPN (7/10/11)
├── MEGA/
│   ├── MEGA_Drive_Universal.cmd   # Универсальный CMD-монтировщик диска MEGA
│   ├── Mount_MEGA_M.bat / .ps1    # Скрипты подключения диска M:
│   ├── Unmount_MEGA_M.bat / .ps1  # Скрипты отключения диска M:
│   └── README.md                  # Инструкция по работе с диском MEGA
└── CODEX_ChatGPT/
    ├── Install_ChatGPT_Codex_Universal.cmd # Установщик ChatGPT Codex
    └── README.md                           # Описание интеграции
```

---

*Разработано для [GinCz Windows Infrastructure ↗](https://github.com/GinCz).*
