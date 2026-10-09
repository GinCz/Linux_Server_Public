# 🚀 Регламент создания и публикации новых версий GIN-VPN (Strict Release Protocol)

> **Статус:** Обязательный регламент для всех ИИ-агентов и разработчиков  
> **Проект:** GIN-VPN Windows Client (VLESS Reality Native Client)  
> **Репозитории:**  
> - [Windows_scripts / Windows / GIN-VPN ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN)  
> - [Linux_Server_Public / Windows / GIN-VPN ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/Windows/GIN-VPN)  
> - [Secret_Privat / Windows / GIN-VPN ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-VPN)  

---

## 🎯 Архитектура механизма обновлений и защита от кэширования

1. **Многоуровневая проверка версии:**
   - `version.json` — структурированный манифест с полями `version`, `version_number`, `download_url`.
   - `version.txt` — чистый текстовый номер версии (`v048`).
   - `README.md` — резервный парсинг бейджей версий.

2. **Защита от CDN Fastly / GitHub Raw кэширования (Anti-Cache):**
   - Все GET-запросы проверки и загрузки обновлений обязаны отправлять:
     - Заголовки `Cache-Control: no-cache, no-store, must-revalidate` и `Pragma: no-cache`.
     - Уникальный временной параметр `?t=<nanoseconds>` для гарантированного обхода Fastly CDN (5-минутного TTL).
   - Числовое сравнение версий `remoteNum > localNum` гарантирует математическую точность без зависимости от строковых префиксов.

---

## 📋 Пошаговый чек-лист выпуска новой версии (Release Checklist)

При создании любой новой версии (например, `v048` -> `v049`):

### 1. Инкремент версии в исходном коде:
- В `main.go`:
  ```go
  AppVersion = "v049"
  AppTitleEN = "GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client [v049]"
  AppTitleRU = "GIN-VPN от VladiMIR+AI — Высокоскоростной Xray Клиент [v049]"
  mutexName := strPtr("Local\\GIN_VPN_SINGLE_INSTANCE_MUTEX_V049")
  className := strPtr("GIN_VPN_WINDOW_CLASS_V049")
  ```

### 2. Обновление файлов манифеста:
- `version.json`:
  ```json
  {
    "version": "v049",
    "version_number": 49,
    "app_name": "GIN-VPN",
    "title": "GIN-VPN by VladiMIR+AI",
    "release_date": "YYYY-MM-DD",
    "download_url": "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"
  }
  ```
- `version.txt`: `v049`
- `README.md`: обновить бейджи и ссылки на `v049`.

### 3. Компиляция бинарников для Windows x64:
```bash
cd /root/Secret_Privat/Windows/GIN-VPN
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-H windowsgui -s -w" -o GIN-VPN_v049.exe .
cp GIN-VPN_v049.exe GIN-VPN.exe
rm -f GIN-VPN_v<OLD>.exe
```

### 4. Синхронизация файлов во все 3 репозитория:
- Скопировать `GIN-VPN.exe`, `GIN-VPN_v049.exe`, `version.json`, `version.txt`, `README.md` в:
  - `/root/AI_157/repos/Windows_scripts/Windows/GIN-VPN/`
  - `/root/AI_157/repos/Linux_Server_Public/Windows/GIN-VPN/`
  - `/root/Linux_Server_Public/Windows/GIN-VPN/`
- Удалить устаревшие бинарники старых версий.

### 5. Выгрузка на Рабочий стол в Облако MEGA №1:
```bash
mega-put -c /root/Secret_Privat/Windows/GIN-VPN/GIN-VPN_v049.exe "MEGA/DOCS/desktop/"
mega-rm "MEGA/DOCS/desktop/GIN-VPN_v<OLD>.exe" 2>/dev/null || true
```

### 6. Фиксация коммитов и Push в GitHub:
- `Secret_Privat`: `git add Windows/GIN-VPN/ && git commit -m "Release GIN-VPN v049" && git push origin main`
- `Windows_scripts`: `git add Windows/GIN-VPN/ && git commit -m "Release GIN-VPN v049" && git push origin main`
- `Linux_Server_Public`: `git add Windows/GIN-VPN/ && git commit -m "Release GIN-VPN v049" && git push origin main`

### 7. Контрольная проверка доступности через curl:
```bash
curl -s "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/version.json"
curl -I -s "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-VPN/GIN-VPN.exe"
```
