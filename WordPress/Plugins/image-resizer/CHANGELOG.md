# CHANGELOG - Smart Image Resizer on Upload

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

---

## 2026-10__1.41 — 2026-10-21

- **Clean Core & Cloudflare Removal**: Completely removed Cloudflare CDN routing, custom CDN subdomains, and URL rewrite filters from the plugin. The plugin returns to its single core purpose: ultra-fast, reliable automatic resizing and optimization of image uploads on local disk. This eliminates any risks of broken image URLs (404/NXDOMAIN), CORS font blocking, or Cloudflare accessibility issues in Russia.
- **Maintained Instant Update Check**: Preserved direct in-admin button (`🔄 Проверить обновления плагина сейчас`) to flush transients on demand.

---

## 2026-10__1.40 — 2026-10-21

- **Zero-Config Cloudflare Mode**: Enabling Cloudflare CDN now operates 100% automatically without requiring any manual subdomain or URL input. Sends 1-year Cloudflare Edge caching headers (`Cache-Control: public, max-age=31536000`, `CDN-Cache-Control: max-age=31536000`). Custom subdomain input moved to an optional advanced toggle.
- **Instant Update Check & Transient Bypass**: Added a direct in-admin button (`🔄 Проверить обновления плагина сейчас`) to immediately flush WordPress transient caches and trigger core plugin update checks. `vladimir-ai-updater` now forces fresh manifest fetches whenever WordPress checks for updates.

---

## 2026-10__1.39 — 2026-10-21

- **Branding & Clarity**: Renamed plugin to **Image Resizer on Upload & Cloudflare CDN (VladiMIR+AI✅)** to explicitly reflect Cloudflare Edge CDN caching capabilities.
- **Interactive Cloudflare Setup Guide**: Added 1-click domain auto-suggestion button (`🪄 Подставить: https://cdn.domain.com`) and a clear 3-step in-admin DNS setup walkthrough.
- **Fail-Safe Preserved**: Retains strict local execution by default for Russian servers and `.RU` domains.

---

## 2026-10__1.38 — 2026-10-20

- **Cloudflare Edge Delivery & Optimization Integration**: Added optional Cloudflare Edge delivery toggle (`enable_cloudflare`) and custom CDN/Worker domain input (`cloudflare_domain`).
- **Fail-Safe for Russian Domains (.RU / .РФ)**: Disabled strictly by default (`default: 0`). When disabled, operates 100% locally via GD/Imagick with zero external network requests.
- **Dynamic URL Rewriting Without Database Modification**: Image URLs are dynamically filtered on-the-fly (`wp_get_attachment_url`, `the_content`, `wp_calculate_image_srcset`), guaranteeing zero DB pollution. Turning off the checkbox immediately restores local URLs.

---

## 2026-09__1.37 — 2026-09-21

- **Codebase maintenance & independence**: Removed standalone updater dependency, streamlined standalone micro-plugin architecture, synchronized suite versioning.

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
- Unified update mechanism with GitHub API updater: Update URI: https://vladimir-ai.updates/image-resizer + ladimir-ai-updater.php.
- Standardized metadata requirements: Requires at least: 6.0 and Requires PHP: 7.4.
- Reorganized codebase into clean modular architecture.
