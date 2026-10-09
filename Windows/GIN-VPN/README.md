# 🛡️ GIN-VPN by VladiMIR+AI (v050)
### Нативный высокоскоростной Xray клиент (VLESS + Reality + Vision) для Windows

---

<div align="center">

# 🚀 [СКАЧАТЬ ПОСЛЕДНЮЮ ВЕРСИЮ GIN-VPN (v050)](https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe)
### ⚡ Нажмите на зелёную кнопку для мгновенного скачивания готовой программы:

<br/>

[![Download GIN-VPN](https://img.shields.io/badge/📥_СКАЧАТЬ_GIN--VPN.exe_(v050)-ПРЯМАЯ_ЗАГРУЗКА_(15_МБ)-00C853?style=for-the-badge&logo=windows&logoColor=white)](https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe)

<br/>

[![Alternative Mirror](https://img.shields.io/badge/Зеркало_загрузки_(GitHub_Raw)-1E88E5?style=flat-square&logo=github&logoColor=white)](https://github.com/GinCz/Windows_scripts/raw/main/Windows/GIN-VPN/GIN-VPN.exe)
[![Version](https://img.shields.io/badge/Version-v050_(Latest_Release)-00E676.svg?style=flat-square)](https://github.com/GinCz/Windows_scripts)
[![Platform](https://img.shields.io/badge/Платформа-Windows_7_/_8.1_/_10_/_11_/_Server-0288D1.svg?style=flat-square)](https://microsoft.com/windows)
[![Engine](https://img.shields.io/badge/Движок-Xray_Core_VLESS--Reality-FF6D00.svg?style=flat-square)](https://github.com/XTLS/Xray-core)
[![License](https://img.shields.io/badge/Лицензия-MIT_%7C_100%25_Free-76FF03.svg?style=flat-square)](https://opensource.org/licenses/MIT)

</div>

---

## ⚡ Быстрый старт (Zero Installation)

1. **Скачайте** единственный файл [`GIN-VPN.exe`](https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe) (15 МБ).
2. **Запустите его** на любом компьютере с Windows (Windows 7 SP1, 8.1, 10, 11, Windows Server 2008–2025). Никаких сторонних программ, библиотек или Python устанавливать не нужно — высокоскоростной движок Xray Core уже встроен внутрь файла.
3. **Вставьте ваш VLESS-ключ** (кнопка `[ 📋 Вставить ]`) и нажмите **`[ ▶ ПОДКЛЮЧИТЬ VPN ]`**.

---

## 🌟 Ключевые возможности GIN-VPN (v050)

### 🔄 1. Встроенное умное автообновление в 1 клик (In-App Auto-Updater)
- При нажатии кнопки **`[ 🔄 Обновить ]`** программа сама проверяет релизы на GitHub.
- Если доступна новая версия, GIN-VPN **автоматически скачивает обновление в фоне, безопасно отключает VPN, заменяет исполняемый файл и перезапускает уже обновлённую программу**.
- Больше не нужно вручную заходить на сайты и перекачивать файлы!

### 💾 2. Надежное сохранение всех настроек и языка (Persistence)
- Выбранный язык (**RU / EN**) и тема оформления (**Дневная / Ночная OLED**) мгновенно сохраняются в Windows Registry (`HKCU\Software\VladiMIR\GIN-VPN`) и файле `settings.json`.
- При перезагрузке компьютера или перезапуске приложения все ваши настройки, выбранный сервер и тема восстанавливаются мгновенно с первого кадра.

### 📑 3. Установка и чистое удаление (Official Windows Uninstaller)
- Кнопка **`[ 📑 Установить ]`** создает ярлыки с золотым щитом на Рабочем столе и в меню Пуск, регистрирует приложение в «Установке и удалении программ Windows».
- Встроенная программа удаления **`uninstall.exe`** чисто и безопасно удаляет приложение, восстанавливает системные прокси-настройки и очищает ярлыки.

### 🛡️ 4. Умный сплит-туннель (Smart Split Shield)
- Российские сайты (`.ru`, Госуслуги, Сбер, Т-Банк, ВКонтакте, Яндекс) работают напрямую на максимальной скорости вашего провайдера.
- Заблокированные и международные сервисы (YouTube, Instagram, ChatGPT, Twitter/X) направляются через скоростной шифрованный туннель VLESS Reality.
- Встроенный редактор правил позволяет добавлять собственные домены исключений (ЖКХ, локальные сервисы).

### 📦 5. Экспорт и импорт бэкапов серверов в 1 клик
- Экспорт всей вашей базы серверов в текстовый файл `GIN-VPN_BackUp__YYYY-MM-DD.txt` на Рабочий стол.
- Быстрый импорт серверов из файлов бэкапа или списка ключей с автоматической защитой от дубликатов.

---

## 🖥️ Скриншоты и режимы оформления

| Дневной режим (Light Theme) | Ночной OLED режим (Dark Theme) |
| :---: | :---: |
| Чистый контрастный светлый интерфейс | Глубокий черный OLED-интерфейс без артефактов |

---

## 🏛️ Архитектура приложения

```text
┌────────────────────────────────────────────────────────┐
│               GIN-VPN.exe (Единый файл)               │
│  ┌─────────────────────────┐  ┌─────────────────────┐  │
│  │    Win32 GUI Клиент     │  │ Встроенный Xray     │  │
│  │ (Dark/Day, Трей, Языки) │  │ Core Engine (Gzip)  │  │
│  └────────────┬────────────┘  └──────────┬──────────┘  │
└───────────────┼──────────────────────────┼─────────────┘
                │                          │ (Распаковка в памяти)
                │ IPC                      ▼
        ┌───────▼───────────────────────────────┐
        │       Локальный демон Xray Core       │
        └───────────────────┬───────────────────┘
                            │ (TLS Reality Vision)
        ┌───────────────────▼───────────────────┐
        │      Серверы DE / RU / FI / ES        │
        └───────────────────────────────────────┘
```

---

## 🔒 Безопасность и конфиденциальность (Privacy-First)
- **100% чистый открытый исходный код:** исходники на Go доступны прямо в этом репозитории (`main.go`).
- **Защита от утечек:** при первом запуске список серверов пуст — ваши приватные ключи никогда не попадут к третьим лицам.
- **Шифрование настроек:** конфигурации профилей хранятся локально в системном реестре Windows текущего пользователя.

---

## 👨‍💻 Автор и разработка
- **Автор:** Владимир Буланцев ([GinCz ↗](https://github.com/GinCz)) & AI Assistant
- **Репозитории проекта:**
  - [Windows_scripts / Windows / GIN-VPN ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN)
  - [Linux_Server_Public / Windows / GIN-VPN ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/Windows/GIN-VPN)
