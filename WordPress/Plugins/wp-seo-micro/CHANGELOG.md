# CHANGELOG - WP SEO Micro

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

---
## 2026-11__1.39 — 2026-11-21

- **Privacy & Authorship Safeguard in Schema.org:**
  - Guaranteed that any listing with `author_id <= 1` is strictly emitted with author `'Пользователь'`, completely protecting site administrator personal identity from being erroneously linked to general or guest listings in search engine schema.

---
## 2026-11__1.38 — 2026-11-21

- **Classified Architecture Optimization: Migration from eCommerce Product to Schema.org ItemPage:**
  - **Eliminated Merchant Listings Mismatch:** Completely removed `@type: Product` and `@type: Offer` from classified listings. Classified boards are C2C listing platforms (services, jobs, auto, rentals, goods), not eCommerce retail stores with checkout. This permanently eliminates Google Search Console Merchant Listings demands (`shippingDetails`, `hasMerchantReturnPolicy`, `brand`, `gtin`, price validity).
  - **Introduced Clean Schema.org ItemPage:** Classified ads now render as `ItemPage` with `datePublished`, `dateModified` (capturing actual price/content updates), `inLanguage`, `author` (Person), and `isPartOf` (WebSite).
  - **Image Safeguard:** Prevented site logos/favicons from being emitted as listing photos; only genuine ad attachments (`has_post_thumbnail` or `_vb_images`) are passed in `image`.
  - **Retained Business Directory Schema:** Verified and preserved `LocalBusiness` for corporate listings (`_vb_type === 'company'`) and `BreadcrumbList` across all pages.

---
## 2026-11__1.37 — 2026-11-21

- **Google Search Console Merchant Listing Structured Data Compliance:**
  - **Resolved "Invalid value in field 'category'":** Removed raw taxonomy category strings from Schema.org `Product` JSON-LD markup to strictly comply with Google Merchant Listing standards (hierarchical categories remain cleanly defined via standard `BreadcrumbList`).
  - **Resolved "Missing field 'validFrom' (in offers)":** Added ISO-8601 `validFrom` timestamp to `Offer` schema based on post publication date (`get_post_time( 'c', false, $post_id )`).
  - **Schema Data Cleanliness:** Added `sku` identifier to `Product` and ensured `name` and `Brand` strings are cleanly decoded from HTML entities (`wp_strip_all_tags( html_entity_decode(...) )`).

---
## 2026-11__1.36 — 2026-11-20

- **Robots Meta Unification & Deep Parameter Filtering:**
  - **Single Unified Robots Meta Tag:** Removed core WordPress redundant `wp_robots` hook at `wp_head` priority 0, preventing duplicate `<meta name='robots'>` output and ensuring pristine search engine compliance.
  - **WordPress 5.7+ `wp_robots` Filter Bridge:** Added priority 99 filter to `wp_robots` returning `noindex, follow` on any parameterized query strings or service slugs.
  - **Dual-Layer Query Parameter Detection:** Evaluates both `$_GET` and `$_SERVER['QUERY_STRING']` for parameters (`sort`, `view`, `order`, `filter`, `vb_sort`, `min_price`, `max_price`, `directory_radius`, `page`, `paged`), ensuring query URLs are strictly marked `noindex, follow` across all server configurations.

---
## 2026-11__1.35 — 2026-11-20

- **Duplicate Indexation Defense, Canonical Hardening & Rich Auto-Description:**
  - **Dynamic Query Parameter Filtering:** URLs containing sorting or filtering parameters (`sort=`, `view=`, `order=`, `filter=`, etc.) now strictly receive `<meta name="robots" content="noindex, follow">`, eliminating crawl waste and duplicate content issues in search results.
  - **Pristine Base Canonical URLs:** Guaranteed that `<link rel="canonical">` always strips all GET query strings (`strtok($url, '?')`), pointing search engines strictly to the canonical root URL.
  - **Extended Service Page Exclusion:** Comprehensive `noindex, follow` applied to technical and member pages (`poisk-obyavlenij`, `obyavleniya-polzovatelya`, `add-listing`, `dashboard`, `kabinet`, etc.), removing them from XML Sitemap and search engine results.
  - **Country-Aware Default Meta Description:** When homepage description is unset, automatically generates a localized high-CTR snippet tailored to the board's country.

---
## 2026-11__1.34 — 2026-11-20

- **Instant Google Indexing API & IndexNow Push Engine + Automated Daily Cron:**
  - **Native Google Indexing API v3 Integration:**
    - Pure PHP implementation using built-in `openssl_sign` (RS256) for OAuth 2.0 JWT assertions — zero Composer or Google Client library dependencies.
    - Automatic token exchange with `https://oauth2.googleapis.com/token` and 50-minute transient caching (`_wsm_google_access_token`).
    - Instant push to `https://indexing.googleapis.com/v3/urlNotifications:publish` with `URL_UPDATED` or `URL_DELETED`.
    - Universal credential discovery: reads from WordPress option `_vladimir_seo_google_json` with automated server-level fallback `/etc/wp-seo-micro/google_indexing_key.json`.
  - **IndexNow Protocol (Bing, Yandex, Seznam.cz):**
    - Instant notification via `https://api.indexnow.org/indexnow`.
    - Dynamic key verification endpoint `/<key>.txt` served entirely in memory via WordPress rewrite without writing physical files to disk.
  - **Real-Time & Scheduled Automations:**
    - Real-time trigger on post/ad creation, modification, or deletion (`transition_post_status` hook for `vb_listing`, `post`, `page`, `product`).
    - Daily scheduled background re-indexing (`vladimir_seo_cron_daily_reindex` via WP-Cron): pings search engines with the XML sitemap and pushes the latest modified pages.
  - **Single-Page Dashboard & Audit Log:**
    - Live visual status cards for Google Search Console API, IndexNow, and Daily Cron.
    - Quick 1-click manual URL submission form with targeted engine selection (All, Google, IndexNow).
    - In-admin real-time audit log of recent indexing events with timestamp, engine, HTTP status code, and API response.

---
## 2026-11__1.33 — 2026-11-20

- **Merchant Listings (Google Search Console Structured Data) & Universal Catalog Meta Engine:**
  - **100% Google Merchant Listings Compliance:**
    - Resolved critical missing `description`, `offers`, and `image` errors in Google Search Console structured data report ("Данные о товарах продавца: структурированные данные").
    - Added dynamic multi-currency detector `vladimir_seo_detect_country_currency()` across all 11 country boards (`EUR` for DE, FR, ESP, IT, GR; `PLN` for PL; `CZK` for CZ; `HUF` for HU; `MDL` for MD; `UAH` for UA; `ILS` for IL). Eliminated hardcoded CZK on non-Czech domains.
    - Guaranteed valid `offers` schema for every classified ad with real or "0.00" price, valid ISO-4217 `priceCurrency`, `priceValidUntil`, `availability` (`InStock`), and `seller` Person/Organization details.
    - Image resolver `vladimir_seo_get_post_image()` checks featured thumbnail, gallery `_vb_images`, legacy thumbnail IDs, and site icon/logo fallbacks — Schema `image` is never empty.
    - Full word-boundary truncation `vladimir_seo_clean_text()` ensures meta and structured data descriptions are never cut off mid-word and never end with `[...]`.
  - **Comprehensive Catalog, Search & Archive Meta Tags:**
    - Full native support for Post Type Archive `/ads/` (`is_post_type_archive('vb_listing')`): sets `robots` index/follow, optimized meta title, high-converting meta description, canonical link, OpenGraph tags, and Schema.org `CollectionPage` + `BreadcrumbList`.
    - Native support for `/company/` page (Company Catalog) and `/poisk-obyavlenij/` (Search): sets tailored meta descriptions and `CollectionPage` + `BreadcrumbList` structured data.
    - Cleaned category titles and descriptions: automatically removes decorative bullet marks (`^[◉\s\-\•\·]+`) from `vb_category` and `vb_location` terms.
    - Rich `BreadcrumbList` schema generated for every single ad and company page.

---
## 2026-11__1.32 — 2026-11-19

- **Network-wide Classified & Directory SEO Engine:**
  - Добавлена нативная поддержка кастомного типа записей доски объявлений `vb_listing` (объявления и карточки компаний) и таксономий `vb_category` (рубрики) и `vb_location` (регионы/города) в XML Карту Сайта (`/sitemap.xml`, `/sitemaps.xml`).
  - Интеллектуальная фильтрация страниц: из sitemap автоматически исключены служебные и технические страницы (`dashboard`, `my-ads`, `kabinet`, `sign-in`, `login`, `registration`, `checkout`, `add-listing`).
  - Устранено дублирование тега канонического адреса: отключен дефолтный хук ядра `rel_canonical`, теперь формируется ровно один валидный `<link rel="canonical">`.
  - Полноценная поддержка микроразметки Schema.org (JSON-LD): автоматическая генерация сущностей `WebSite` с `SearchAction` и `Organization` для главной, `LocalBusiness` для карточек фирм каталога и `Product` / `Offer` для товарных объявлений.
  - Мета-теги `Description`, `Canonical` и `Robots` теперь полноценно генерируются для всех рубрик и фильтров доски `vb_category` и `vb_location`.

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
- Unified update mechanism with GitHub API updater: Update URI: https://vladimir-ai.updates/wp-seo-micro + ladimir-ai-updater.php.
- Standardized metadata requirements: Requires at least: 6.0 and Requires PHP: 7.4.
- Reorganized codebase into clean modular architecture.
