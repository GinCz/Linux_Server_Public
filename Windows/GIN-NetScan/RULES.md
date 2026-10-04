# 📌 Железное Правило Релизов: Автоматическая Выгрузка на Рабочий Стол через MEGA

> **Путь:** `Windows_Scripts/GIN-NetScan/RULES.md`  
> **Статус:** Обязательно к исполнению при каждом билде / обновлении  
> **Дата утверждения:** 05.10.2026  

---

## ⚡ 1. Абсолютное Требование (Zero Inquiry & Automatic Sync)

При сборке, компиляции или обновлении любой новой версии исполняемого файла (`.exe` / `.ico` / скрипта / установщика) ИИ-агент **ОБЯЗАН АВТОМАТИЧЕСКИ И БЕЗ НАПОМИНАНИЙ**:

1. Скомпилировать бинарник с встроенным ресурсом иконки PE (`rsrc_windows_amd64.syso`).
2. Проверить сессию MEGA (`mega-whoami` -> аккаунт `gin.vladimir@gmail.com`). При необходимости авторизоваться через `oathtool --totp` (TOTP-ключ из `/root/Secret_Privat/PASS_KEYS/2FA_AUTHENTICATOR_KEYS.md`).
3. Удалить старую версию из папки облака:
   ```bash
   mega-rm "/MEGA/DOCS/desktop/<old_version>.exe"
   ```
4. Загрузить новую версию исполняемого файла и иконки на рабочий стол пользователя (`D:\MEGA\DOCS\desktop` <-> `/MEGA/DOCS/desktop/`):
   ```bash
   mega-put "/root/Secret_Privat/Windows_Scripts/GIN-NetScan/<new_version>.exe" "/MEGA/DOCS/desktop/"
   mega-put "/root/Secret_Privat/Windows_Scripts/GIN-NetScan/Gin-NetScan.ico" "/MEGA/DOCS/desktop/"
   ```
5. Зафиксировать изменения в git и запушить в `Secret_Privat`.

---

## 🛑 Запреты

- ❌ **ЗАПРЕЩЕНО** завершать задачу без выгрузки свежего бинарника в `/MEGA/DOCS/desktop/`.
- ❌ **ЗАПРЕЩЕНО** ждать, пока пользователь сам попросит скопировать файл на рабочий стол.
- ❌ **ЗАПРЕЩЕНО** оставлять на рабочем столе устаревшие предыдущие версии `.exe`.
