# CHANGELOG - WP Simple Post & Category Order

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

---
## 2026-09__1.22 — 2026-09-20

- **Плагин `wc-admin-default-sort-date` объединён с этим.** Отдельный плагин удалён из пакета, его задача стала строкой «Товары» в новом блоке настроек «Сортировка списков в админке».
- **Исправлен старый косяк с товарами.** Прежняя версия безусловно навязывала списку товаров сортировку по дате DESC, независимо от настроек. Из-за этого у клиента «пропадали» только что добавленные товары, и разбираться пришлось по звонку. Теперь для товаров по умолчанию стоит `WordPress default` — плагин не вмешивается в сортировку вообще, пока это не включено вручную.
- **Появился выбор сортировки для каждого типа.** Для записей, страниц и товаров отдельно задаются поле (дата создания, дата изменения, заголовок, ручной порядок `menu_order`, ID — либо «не вмешиваться») и направление (по возрастанию / по убыванию).
- Явный выбор колонки пользователем (`?orderby=` в адресе) теперь всегда важнее настроек плагина.
- Значения из формы проверяются по белому списку, а не принимаются как есть.
- Если старый плагин `wc-admin-default-sort-date` ещё активен, в админке показывается предупреждение с указанием, что делать.

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
- Unified update mechanism with GitHub API updater: Update URI: https://vladimir-ai.updates/wp-simple-post-order + ladimir-ai-updater.php.
- Standardized metadata requirements: Requires at least: 6.0 and Requires PHP: 7.4.
- Reorganized codebase into clean modular architecture.
