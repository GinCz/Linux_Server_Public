# CHANGELOG - WP Test Email Micro

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

---
## 2026-09__1.31 — 2026-09-20

- Replaced the malformed mixed-encoding source with a UTF-8-only admin screen.
- Made the complete form, status messages, subject, and default HTML message English.
- Simplified the default email to a neutral website check: it contains the site's own URL and its current custom logo (or site icon as a fallback).
- Removed mail-scoring and promotional wording from the default message. Delivery still depends on the site's configured SMTP/PHP mail transport and sender-domain authentication.

---
## 2026-09__1.24 — 2026-09-20

- **Окончательное устранение аварии с HTTP 500.** Общие модули (`vladimir-ai-updater.php`, `vladimir-ai-i18n.php`) больше не дублируются в каждом плагине — они поставляются только внутри `404-410-301`, остальные плагины подключают их, если файл есть, и прекрасно работают без него.
- Почему так: копии разных выпусков, лежащие рядом, вызывали повторное объявление функций и роняли весь сайт. Правка кода не помогала — PHP-FPM отдавал старый байткод из OPcache, и спасало только физическое удаление лишних файлов. Одна копия — проблема исчезает в принципе.
- Скрипт развёртывания `WordPress/deploy/wp_deploy_vladimir_plugins.sh` теперь сам удаляет оставшиеся копии со старых установок.

---

## 2026-09__1.23 — 2026-09-20

- **Исправлена фатальная ошибка, из-за которой сайты отдавали HTTP 500.** Общие модули (`vladimir-ai-updater.php`, `vladimir-ai-i18n.php`) лежат копией в папке каждого плагина. Когда на сайте оказывались копии разных выпусков, защиты по константе не хватало — PHP получал повторное объявление функции (`Cannot redeclare vladimir_ai_update_manifest()`) и сайт падал целиком.
- Теперь оба модуля проверяют не только константу, но и наличие самой функции. Несколько копий рядом больше не опасны, даже если они из разных версий или отдаются из устаревшего кэша PHP (OPcache).

---

## 2026-09__1.22 — 2026-09-20

- Синхронизация с релизом пакета: общий клиент обновлений и модуль переводов обновлены до этой версии.
- Из пакета удалён плагин `wc-admin-default-sort-date` — он объединён с `wp-simple-post-order`, где сортировка списков в админке стала настраиваемой и по умолчанию не трогает товары.

---

## 2026-09__1.21 — 2026-09-20

- **Окончательный адрес плагинов.** Пакет живёт в публичном репозитории `GinCz/Linux_Server_Public`, путь `WordPress/Plugins/<плагин>`. Все ссылки внутри плагина (`Plugin URI`, кнопка «Документация», подвал страницы настроек) переписаны на это место; промежуточные адреса `Secret_Privat` и `WordPress-Plugins` больше не используются.
- **Автообновление без токенов.** Репозиторий публичный: клиент обновлений берёт манифест обычным запросом к `raw.githubusercontent.com`, ZIP скачивается как публичный релиз. В `wp-config.php` ничего прописывать не нужно.
- **Безопасность автообновления.** Ссылка на архив из манифеста теперь проверяется по строгому списку: устанавливается только HTTPS-релиз из `github.com/GinCz/Linux_Server_Public`. Подменённый манифест не сможет указать сайту на чужой архив.
- Добавлен `index.php` («Silence is golden») в папку плагина — защита от листинга каталога на серверах с включённым индексом.

---


## 2026-09__1.19 - 2026-09-19

- Added 8-language localization for plugin descriptions: EN, RU, CS, DE, IT, ES, FR, PL.
- Unified localization in ladimir-ai-i18n.php using the ll_plugins hook and fallback to English.
- Integrated branding tag (VladiMIR+AIâś…) across all language descriptions.

---

## 2026-09__1.18 - 2026-09-19

### Suite Standardization Release

- Adopted standard versioning schema YYYY-MM__<generation>.<build> across all suite modules.
- Standardized branding tag (VladiMIR+AIâś…) in Plugin Name.
- Unified update mechanism with GitHub API updater: Update URI: https://vladimir-ai.updates/wp-test-email-micro + ladimir-ai-updater.php.
- Standardized metadata requirements: Requires at least: 6.0 and Requires PHP: 7.4.
- Reorganized codebase into clean modular architecture.
