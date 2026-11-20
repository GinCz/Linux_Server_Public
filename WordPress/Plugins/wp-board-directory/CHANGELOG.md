# Changelog — WP Board & Directory

## [2026-11__1.23] - 2026-11-20
### Fixed & Improved
- Semantic Heading Structure & Clean Category Hierarchy:
  - Replaced `<h3>` tags around category sub-items with clean `<div class="vb-subcat-title">`, completely eliminating over 60 redundant H3 headings from the homepage and category layouts.
  - Added `aria-hidden="true"` to visual bullet marks (`<span class="vb-cat-bullet">◉</span>`) inside parent category `<h2>` tags, preserving the stylish visual dot while ensuring search engines and screen readers index clean, standard category text.
  - Automatic bullet stripping on subcategory names (`^[◉\s\-\•\·]+`).

## [2026-11__1.22] - 2026-11-20
### Fixed & Improved
- Multi-Currency Localization across All 11 Country Boards:
  - Added dynamic currency resolver `VB_CPT::get_currency_info()` and `VB_CPT::get_currency_symbol()` automatically detecting the host domain (`EUR / €` for Germany, France, Spain, Italy, Greece; `PLN / zł` for Poland; `CZK / Kč` for Czech Republic; `HUF / Ft` for Hungary; `MDL / L` for Moldova; `UAH / грн` for Ukraine; `ILS / ₪` for Israel).
  - Replaced hardcoded `Kč` with localized country currency symbols on single listings (`single-listing.php`), category archives (`taxonomy-category.php`), submission form (`submit-form.php`), search loops (`class-shortcodes.php`), and admin listings table (`class-cpt.php`).
  - Approximate EUR conversion block `~ XX €` is now displayed strictly on non-EUR domains (e.g. `CZK`), avoiding redundant duplicate currency displays in eurozone countries (`doska-de.ru`, etc.).

## [2026-11__1.21] - 2026-11-19
### Changed
- SEO & Semantic Heading Hierarchy:
  - На странице рубрик (`taxonomy-category.php`) заголовок переведен в семантический `<h2>` (`vb-tax-title`) для соблюдения правильной иерархии документа и исключения конкуренции с главным сайтовым `<h1>`.
  - На странице отдельного объявления/компании (`single-listing.php`) заголовок публикации переведен в `<h2>` (`vb-single-title`), синхронизируя общую типографику шапки и контента сети досок.

## [2026-11__1.20] - 2026-11-19
### Added
- Beautiful Universal Search Module (`[vb_search]` and backward-compatible aliases `[acadp_search_form]`, `[acadp_search]`):
  - Modern hero search container with prominent query input, search magnifier icon, and instant clear button (`✕`).
  - Hierarchical Category dropdown (`Рубрика`) with item count badges and nested subcategory indentations.
  - Region / City dropdown (`Город / Регион`) covering all localized kraje, cities, and Internet / OnLine.
  - Publication type selector (`Все публикации`, `📢 Только объявления`, `🏢 Только компании`).
  - Sorting options (`Сначала новые`, `Сначала старые`, `Сначала дешевле`, `Сначала дороже`).
  - Rich listings & companies card grid matching the board styling with ratings, price, photo, category, and location.
  - Interactive pagination with numbered page links.
  - Friendly empty state with search hints when no matches are found.
  - Enhanced search across custom meta fields (`_vb_email`, `_vb_phone`, `_vb_address`, `_vb_whatsapp`, `_vb_telegram`, `_vb_website`) and author names.
- Top bar navigation menu button styling:
  - Added dedicated styling for `Поиск` in header navigation with magnifier icon (`🔍 Поиск`), translucent pill background (`rgba(255, 255, 255, 0.18)`), smooth hover animations, and elevated contrast.
- Global Search Routing:
  - Standard WordPress frontend searches (`/?s=...`) automatically include custom post types `vb_listing` and `vb_company` and redirect to the unified rich search page (`/poisk-obyavlenij/?s=...`).

## [2026-11__1.19] - 2026-11-19
### Added
- Eternal listings for Vladimir Bulantsev (`gin@volny.cz` / author ID 1 / `ekaterinburg-sro.eu`):
  - Automatically marked as `never_expires = 1` and `expiry_date = '2099-12-31 23:59:59'` across all 11 boards.
  - Distinctive green `Вечно ♾️` badge in WordPress Admin listings table and user dashboard.
  - Admin checkbox `Отображать вечно (без ограничения срока) ♾️` in listing parameters meta box.
- Standard 6-month publication period for all other users with automated email reminder system:
  - Automated watchdog cron (`VB_Cron`) running daily.
  - Email notification 14 days before expiration with 1-click renewal link.
  - Email notification 7 days before expiration with 1-click renewal link.
  - Automated expiration handling when publication period ends.
  - Free 1-click renewal mechanism (`vb_action=renew_ad`) extending listings by +6 months with live confirmation toast banner.

## [2026-11__1.18] - 2026-11-19
### Added
- Strict 100-character post title limit for listings (`vb_listing`) and companies (`vb_company`):
  - DB & Save level: `wp_insert_post_data` filter enforces `mb_substr( $title, 0, 100, 'UTF-8' )` on all creations and updates.
  - Frontend form: `maxlength="100"` attribute with real-time character counter (`0 / 100 символов`) and dynamic color indicator.
  - WordPress Admin: injected script on post edit screen enforcing `maxlength="100"` on `#title` with live character counter.
  - Submission handler: sanitizes and strictly clamps `$title` to 100 characters.

## [2026-11__1.17] - 2026-11-19
### Changed
- Symmetrical category layout: added balanced horizontal padding (`padding: 10px 45px; box-sizing: border-box;`) to `.vb-categories-columns-wrap` and `.vb-categories-enhanced` to eliminate left-side stickiness and match right-side spacing equally across all screen sizes.
- Two-column countries module: transformed `.vb-countries-list` into a compact, responsive 2-column grid (`grid-template-columns: repeat(2, 1fr);`) with clean tile styling and smooth purple hover effects, halving vertical sidebar height.

## [2026-11__1.16] - 2026-11-19
### Fixed
- Fixed homepage categories rendering in `render_categories()`: dynamically fetch and balance all top-level parent categories across 3 columns, with full dual-slug support for both migrated English slugs (`auto`, `business`, `phones`, `home`, `entertainment`, `household`, `realty`, `other`, `electronics`) and legacy slugs.

## [2026-11__1.15] - 2026-11-19
### Fixed
- Added native `assets/no-photo.svg` camera placeholder icon.
- Enhanced thumbnail resolution: automatically fallback to `_vb_images[0]` attachment URL before placeholder.
- Dynamic `VB_BOARD_URL` asset URL calculation avoiding broken relative path lookups.

## [2026-11__1.14] - 2026-11-19
### Removed / Changed
- Removed WordPress Native Custom Fields (`postcustom`) and Excerpt (`postexcerpt`) meta boxes from post editor for `vb_listing` (`supports` simplified, explicit `remove_meta_box` attached).
- Preserved Discussion / Comments (`comments`) support for permitted discussion moderation.

## [2026-11__1.13] - 2026-11-19
### Added
- Ultra-Clean English SEO Permalinks & Slugs:
  - Frontend ads: `/ad/<slug>/` (archive: `/ads/`).
  - Frontend companies: `/company/<slug>/` (catalog: `/company/`).
  - Categories taxonomy: `/category/<slug>/` (e.g., `/category/business/`, `/category/auto/`, `/category/realty/`).
  - Locations taxonomy: `/location/<slug>/` (e.g., `/location/prague/`, `/location/internet-online/`).
  - Automated 301 Permanent Redirects from legacy Czech and transliterated URLs (`/inzerat/` -> `/ad/` or `/company/`, `/inzeraty/` -> `/ads/`, `/kategorie/` -> `/category/`, `/mesto/` -> `/location/`).
- Automated Category & Location Slugs Migration:
  - All 11 board installations automatically translate taxonomy slugs from Cyrillic transliteration to clean English on update (`rabota-i-biznes` -> `business`, `avto` -> `auto`, `nedvizhimost` -> `realty`, `dlya-doma` -> `home`, `elektronika` -> `electronics`, `sredstva-svyazi` -> `phones`, `razvlecheniya` -> `entertainment`, `hozyajstvo` -> `household`, `raznoe` -> `other`, `ezoterika` -> `esoterics`).
- Clean Admin Query Engine URLs:
  - Replaced long transliterated admin query arguments with short English parameters: `edit.php?post_type=vb_listing&type=ads` and `edit.php?post_type=vb_listing&type=companies`.
  - Added aggressive client-side form sanitizer stripping default and empty query flags (`action=-1`, `action2=-1`, `m=0`, `filter_action`, empty `category`, empty `location`, `paged=1`, `post_status=all`), ensuring admin URLs remain clean, short, and question-mark-free.

## [2026-11__1.12] - 2026-11-19
### Added
- Separated Admin Menus & Dedicated Views:
  - Reorganized Admin Submenus under «Доска и Фирмы»:
    1. «📢 Все объявления» (`edit.php?post_type=vb_listing&vb_type_filter=classified`)
    2. «🏢 Все компании» (`edit.php?post_type=vb_listing&vb_type_filter=company`)
    3. «➕ Добавить объявление» (`post-new.php?post_type=vb_listing&vb_type=classified`)
    4. «➕ Добавить компанию» (`post-new.php?post_type=vb_listing&vb_type=company`)
    5. «📁 Рубрики» (`edit-tags.php?taxonomy=vb_category&post_type=vb_listing`)
    6. «📍 Города / Локации» (`edit-tags.php?taxonomy=vb_location&post_type=vb_listing`)
    7. «🧹 Очистка картинок» (`vb-media-cleaner`)
    8. «📦 Миграция (1-Click)» (`vb-migration`)
- Independent List Views & Filtering:
  - Classified Ads and Business Directory Companies are now cleanly separated in admin list tables.
  - Sticky type retention across post status tabs (`Все`, `Опубликованные`, `Черновики`, `Корзина`) and pagination.
  - Dynamic page heading («📢 Все объявления» vs «🏢 Каталог компаний») and context-aware «Добавить» action button.
- Comprehensive Listing & Company Admin Meta Box:
  - Added native «⚙️ Параметры записи (Доска & Каталог)» with visual type toggle (Объявление / Компания).
  - Clean inputs for Phone, Email, WhatsApp, Telegram, Address, Website URL, Price (Kč), and Publication Expiry Date.
  - Context-aware title placeholder ("Введите заголовок объявления..." vs "Введите название компании...").

## [2026-11__1.11] - 2026-11-18
### Fixed
- Fixed font clipping in Category Filter Toolbar (`templates/taxonomy-category.php`):
  - Completely neutralized Flatsome theme's aggressive `select`/`input` overrides (`margin-bottom: 1em; padding-top: 1.1em; height: 3.0084em;`).
  - Implemented crisp `height: 40px`, centered `line-height: 40px`, `margin: 0 !important`, `padding: 0 4px !important`, and custom SVG chevron arrow, ensuring zero bottom-line font truncation across all browsers.
- Fully restored and re-linked all company logos and preview images:
  - Reinstated company image attachments (`post_parent` linked to `vb_listing`) from clean backup archives.
  - Linked featured thumbnails for all migrated companies.

## [2026-11__1.10] - 2026-11-18
### Added
- Complete Czech Republic Regions:
  - Integrated all 14 administrative regions (kraje) of the Czech Republic under parent taxonomy `Чехия` (`vb_location`): Prague, Central Bohemian, South Moravian (Brno), South Bohemian (České Budějovice), Plzeň, Karlovy Vary, Ústí nad Labem, Liberec, Hradec Králové, Pardubice, Vysočina (Jihlava), Olomouc, Moravian-Silesian (Ostrava), Zlín.
  - Added anti-spam trap regions (`Россия` / `Москва`, `Украина` / `Киев`) allowing spammers to self-segment for immediate 1-click administrative purging.
  - Dynamic hierarchical dropdowns with optgroups in frontend submission form (`templates/submit-form.php`) and category archive filter toolbar (`templates/taxonomy-category.php`).
- Clean Admin Filter URLs:
  - Added client-side form sanitizer to `#posts-filter` that disables empty parameters and default `-1`/`0` values before submission, completely eliminating URL clutter (such as `filter_action=Фильтр` and empty queries).

### Fixed
- Fixed `/company/` catalog query to strictly query `vb_listing`, eliminating duplicate cards caused by residual legacy Directorist posts.
- Restored missing published companies from trash and permanently purged orphaned legacy `at_biz_dir` posts.

## [2026-11__1.09] - 2026-11-18
### Fixed
- Fixed 502 Bad Gateway ("upstream sent too big header") on bulk admin actions with high post selection counts:
  - Tuned FastCGI buffers (`fastcgi_buffer_size 128k; fastcgi_buffers 8 128k;`).
  - Cleaned duplicate `DISALLOW_FILE_EDIT` warning in `wp-config.php`.

### Added
- Deep Admin Search:
  - Searching by email (`s=example@gmail.com`), phone number, or address in `edit.php?post_type=vb_listing` now automatically searches through custom meta fields (`_vb_email`, `_vb_phone`, `_vb_address`) and author profile accounts.

## [2026-11__1.08] - 2026-11-18
### Added
- Admin List Table Enhancements (`edit.php?post_type=vb_listing`):
  - Thumbnail / photo preview column (`Фото`).
  - Sortable `Телефон` and `Email` columns with direct click-to-call / mailto links.
  - Type badge column (`📢 Объявление` vs `🏢 Фирма`).
  - Price and Expiry status columns.
  - Dropdown filter bar for Rubrics (`vb_category`), Cities/Regions (`vb_location`), and Types.
- Frontend Category Filter Toolbar (`templates/taxonomy-category.php`):
  - Interactive city/region filter (`vb_location`), keyword search, and sorting (price / date).
- Anti-Spam Limitation:
  - Enforced hard limit: maximum 10 active listings per account/email in one category.

## [2026-11__1.07] - 2026-11-18
### Added
- Integration with standalone `WP Media Cleaner (VladiMIR+AI✅)`:
  - If `wp-media-cleaner` is active, the menu item «Доска и Фирмы» ➔ «Очистка картинок» seamlessly bridges to the full universal cleaner with WooCommerce support.
  - Retained native fallback cleaner and automatic media purge on ad/company deletion.

## [2026-11__1.06] - 2026-11-18
### Fixed
- Fixed fatal stall / endless loading on Dashboard Ads tab (`https://doska-cz.ru/dashboard/?tab=ads`):
  - Removed deprecated unverified call to deleted taxonomy `acadp_categories`.
  - Added safe taxonomy lookup with `vb_category` first and strict `is_wp_error()` checks.
  - Page now loads instantly in < 0.2s.

### Added
- Permanent Attached Media Deletion on Item Removal:
  - Deleting an ad or company (both single action and bulk delete) permanently purges all attached images from disk (`_thumbnail_id`, `_vb_images`, legacy `images`, `_gallery_images`, `_listing_images`, `_atbdp_gallery`, `_atbdp_header_image`, and all attachments with `post_parent = $post_id`) via `wp_delete_attachment( $id, true )`.
- Turnkey Orphan Media Cleaner Engine (`VB_Media_Cleaner`):
  - Added dedicated Admin GUI tool under **Доска и Фирмы ➔ Очистка картинок** (`vb-media-cleaner`).
  - Scans entire WordPress media library, cross-references all active posts, pages, listings, companies, featured images, galleries, logos, and site icons.
  - Displays interactive audit dashboard: Total Media, Used on Site, Orphan/Unused garbage count, and freed MB space.
  - Provides 1-Click "Выбрать все неиспользуемые" and bulk permanent disk purge.
  - Added WP-CLI command `wp vb clean-media [--dry-run]`.

## [2026-11__1.05] - 2026-11-18
### Added
- Complete elimination and deletion of legacy `Directorist` and `Advanced Classifieds and Directory Pro (ACADP)` plugins.
- Modern Single Listing Template (`templates/single-listing.php`):
  - High-res photo gallery with thumbnail strip.
  - Price in Czech Koruna (Kč) and approx. EUR (€).
  - Quick contact bar: Click-to-Call (`tel:`), direct WhatsApp (`wa.me`), Telegram, and website links.
  - Safe deal recommendations and dual anti-fraud ratings (`👍 Рекомендую / 👎 Сомнительно`).
  - Related listings from the same category.
- Taxonomy Category Archive Template (`templates/taxonomy-category.php`):
  - Breadcrumb navigation, subcategory pills/chips, Czech city/region filter.
  - Responsive 3-column equal-height cards grid with 260px cover images.
- Turnkey Frontend Submission Engine (`templates/submit-form.php`):
  - Client-side WebP compression up to 15 photos (max 1024px) with zero server overhead.
  - Category and Czech region selectors.
  - Cloudflare Turnstile bot protection integration.
- Full Czech URL Slugs (`CZ Standard`):
  - Listings: `/inzerat/<slug>/` (archive: `/inzeraty/`)
  - Categories: `/kategorie/<slug>/`
  - Locations: `/mesto/<slug>/`
- Aliased legacy shortcodes (`acadp_categories`, `acadp_listings`, `acadp_listing_form`, `directorist_add_listing`) to native `wp-board-directory` handlers.

## [2026-11__1.04] - 2026-11-18
### Added
- Dashboard Bulk Actions (`/kabinet/?tab=ads` & `/kabinet/?tab=companies`):
  - Row checkboxes and "Select All" toggle for multi-selection.
  - Bulk action toolbar with direct "🗑️ Удалить выбранные" and renewal options: «⏳ Продлить на 1 месяц», «⏳ Продлить на 3 месяца», «⏳ Продлить на 6 месяцев», «⏳ Продлить на 1 год».
  - Automatic recalculation of expiration dates (`expiry_date`) and refreshing of publish timestamps.
- Single Row Actions:
  - Added explicit red «Удалить» button with JS confirmation dialog in the "Действия" column for each ad and company.
  - Expiration date badge (`до ДД.ММ.ГГГГ`) in the date column.
- Visual & Design Refinements:
  - Company Directory Cards (`/company/`): increased image height from 220px to 280px with full width (`padding: 0`) and `object-fit: cover`.
  - Homepage Classifieds Cards (`/`): increased image height by 30% (from 200px to 260px) and card minimum height to 490px, eliminating horizontal cropping.
  - Included expired companies in user dashboard so owners can easily renew them with 1 click.

## [2026-11__1.03] - 2026-11-18
### Added
- Company Directory Filter Bar: instant filtering by Category (from classifieds category tree), by Region/City (Czech kraje), and keyword search.
- Turnkey Unified User Dashboard (`[vb_dashboard]`):
  - Tab 1: «Мой профиль» — Edit Display Name, Phone, City/Region, Company Name, and Bio (no password change required).
  - Tab 2: «Мои объявления» — Table of user's classifieds with thumbnail, status, views, view/edit actions, and «+ Подать объявление» button.
  - Tab 3: «Мои компании» — Table of user's company cards with logo, address, phone, ratings, view/edit actions, and «+ Добавить компанию» button.
  - Header summary card with user avatar, company badge, contact details, and listing statistics.
- Aliased old `[acadp_user_dashboard]` and `[directorist_user_dashboard]` shortcodes to the unified dashboard.
- Linked menu items «Мой профайл», «Личный кабинет», «Мои компании», and «Управление объявлениями» to the unified dashboard.

## [2026-11__1.02] - 2026-11-18
### Added
- Left sidebar «Все страны»: removed top gap, converted to clean unbold links with full-width thin divider lines.
- Categories grid: increased typography size for parent and subcategories for improved readability on desktop and mobile.
- Company Directory cards: increased image height to 220px, eliminated empty tagline void, pinned title and fields directly beneath the image.
- Classifieds Homepage Grid: switched ads to 3-column equal-height cards (`view="grid"`, `columns="3"`) with 200px cover images, clamp titles, prominent prices and meta.

## [2026-11__1.01] - 2026-11-18
### Added
- Filter for ACADP categories template (`acadp_get_template` and `acadp_load_template`) with balanced 3 columns (`templates/acadp-categories-list.php`).
- Horizontal dividers between category rows and small horizontal accent line (`vb-cat-accent-line`) above each main category title.
- Reordered categories: swapped «Развлечения» and «Для дома» for visual balance across columns.
- Strict 3-column CSS Grid for Company Directory (`.vb-company-grid`) with uniform card height (`min-height: 400px`, fixed title & tagline clamps, guaranteed 3-field alignment).

## [2026-11__1.00] - 2026-11-17
### Added
- Initial release of unified Classified Ads & Business Directory engine.
- Custom Post Type `vb_listing` and taxonomies `vb_category`, `vb_location`.
- Anti-fraud ratings & reviews table `wp_vb_ratings` and fast search index `wp_vb_index`.
- 1-Click Migration Wizard for ACADP and Directorist with full author relation preservation.
- Shortcodes: `[vb_categories]`, `[vb_listings]`, `[vb_companies]`, `[vb_dashboard]`.
- Backward-compatible shortcode aliases: `[acadp_categories]`, `[acadp_listings]`.
- Client-side WebP image compressor up to 15 photos max 1024px.
