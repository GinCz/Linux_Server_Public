# 🚀 Регламент создания и публикации новых версий GIN-VPN (Strict Release Protocol)

> **Статус:** Обязательный регламент для всех ИИ-агентов и разработчиков  
> **Проект:** GIN-VPN Windows Client (VLESS Reality Native Client)  
> **Репозитории:**  
> - [Windows_scripts / Windows / GIN-VPN ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-VPN)  
> - [Linux_Server_Public / Windows / GIN-VPN ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/Windows/GIN-VPN)  
> - [Secret_Privat / Windows / GIN-VPN ↗](https://github.com/GinCz/Secret_Privat/tree/main/Windows/GIN-VPN)  

---

## 🎯 Архитектура механизма обновлений и 100% защита от кэширования (Zero-Cache)

1. **Многоуровневая проверка версии через GitHub API:**
   - **Уровень 1 (GitHub Commits API):** Запрос `https://api.github.com/repos/GinCz/Windows_scripts/commits/main` для мгновенного получения актуального SHA-хэша последнего коммита.
   - **Уровень 2 (GitHub Contents API):** Запрос `https://api.github.com/repos/GinCz/Windows_scripts/contents/Windows/GIN-VPN/version.json` с декодированием Base64 payload. GitHub API обновляется мгновенно в момент push и **не кэшируется** промежуточными CDN.
   - **Уровень 3 (Commit SHA Raw URL):** Запрос `https://raw.githubusercontent.com/GinCz/Windows_scripts/<commit_sha>/Windows/GIN-VPN/version.json`. Поскольку `<commit_sha>` уникален для каждого релиза, Fastly CDN физически не может выдать старый кэш (гарантированный `x-cache: MISS`).
   - **Уровень 4 (Fallback Raw):** Запрос `version.json`, `version.txt` и `README.md` с временным таймстемпом `?t=<nanoseconds>`.

2. **Загрузка бинарного обновления через Commit SHA:**
   - Загрузка исполняемого файла выполняется по прямому адресу коммита:
     `https://raw.githubusercontent.com/GinCz/Windows_scripts/<commit_sha>/Windows/GIN-VPN/GIN-VPN_<ver>.exe`
     что исключает скачивание устаревшего исполняемого файла из кэша.

3. **Числовое сравнение версий:**
   - Преобразование строк версий (`v052` -> `52`) и строгое числовое сравнение `remoteNum > localNum`.

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
