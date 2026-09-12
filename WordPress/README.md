# ⚡ WordPress Ultra-Light Plugins Suite (VladiMIR+AI)

A collection of ultra-lightweight, secure, and high-performance micro-plugins for **WordPress**, engineered by **VladiMIR (GinCz) + AI** and **Antigravity AI**.

These plugins were built to replace bloated third-party plugins from WordPress.org that clutter MySQL databases, generate noisy bot logs, ship vulnerable React/JS dashboards, or display annoying "Go Pro" upgrade banners.

---

## 📜 Author & Project Attribution Rules

- **Primary Author:** `VladiMIR (GinCz) + AI` *(Always write as VladiMIR without last name)*
- **AI Co-Developer:** `Antigravity AI`
- **Version Format:** `YYYY.MM.DD` (Release Date)
- **Branding Tag:** `(VladiMIR+AI)`

---

## 📦 Plugins Catalog (12 Active Consolidated Modules)

> 🛑 **Архитектурные решения по оптимизации пакета (VladiMIR+AI):**
> 
> 1. **Единый модуль 404-410-301 вместо двух:** Плагин `wp-redirect-404-to-homepage` упразднен и удален как избыточный. Плагин `404-410-301` полностью закрывает обе задачи: поисковые боты (Google/Yandex) получают честный HTTP 404/410 Not Found для мгновенного удаления битых ссылок из индекса (без ошибок в панелях вебмастеров), а посетители плавно и красиво перенаправляются на главную через таймер (время настраивается: от 0 до 60 сек).
> 2. **Объединение Classic Editor и TinyMCE:** Модули `classic-editor` и `wp-tinymce-micro` объединены в единый мощный плагин `classic-editor-tinymce` (`Classic Editor - TinyMCE`). Он отключает Gutenberg и блочные виджеты, включает классический редактор и держит всегда открытой 2-ю строчку тулбара Word-форматирования (шрифты, цвета, таблицы, очистка стилей).
> 3. **Случайные 5-значные артикулы вразброс в `wp-auto-sku`:** Плагин генерирует уникальные случайные 5-значные коды (например, `74921`, `18304`), исключая предсказуемую цепочку 1, 2, 3, и обеспечивает мгновенный поиск товаров по SKU на фронтенде и в админке.
> 4. **Гранулярная сортировка записей и категорий в `wp-simple-post-order`:** В панели настроек можно точечно выбрать, для чего именно активировать drag-and-drop сортировку (отдельно для записей, товаров, страниц, а также рубрик и категорий товаров магазина).
> 5. **Google Analytics и Seznam Webmaster:** Разработка закрыта, используются `Google for WooCommerce` и стандартная верификация через HTML/DNS.

| # | Module / Directory | Source | Replaces | Key Features | Action Links |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **1** | [**404-410-301**](./404-410-301/) | PHP + README | *404 to 301, Redirection* | Returns true HTTP 404/410 for SEO and redirects visitors to homepage via smooth countdown (0–60s). | Settings • Docs |
| **2** | [**classic-editor-tinymce**](./classic-editor-tinymce/) | PHP + README | *Classic Editor + TinyMCE Advanced* | All-in-one classic editor: blocks Gutenberg, opens 2nd Word-like toolbar row (fonts, colors, tables). | Settings • Docs |
| **3** | [**clean-head-meta**](./clean-head-meta/) | PHP + README | *Head Meta Data, WP Hide* | Cleans `<head>` clutter, hides WP version, removes pingbacks/emojis, adds `VladiMIR` author. | Settings • Docs |
| **4** | [**disable-update-emails**](./disable-update-emails/) | PHP + README | *Manage Notification E-mails* | Completely blocks automatic core, plugin, and theme update notification email spam. | Settings • Docs |
| **5** | [**image-resizer**](./image-resizer/) | PHP + README | *Imsanity, Resize Images* | Automatically scales large uploads down to 1600×1600 px with crisp 95% JPEG quality. | Settings • Docs |
| **6** | [**translit-cyr-lat**](./translit-cyr-lat/) | PHP + README | *Cyr-To-Lat, RusToLat* | Fast SEO transliteration of Russian, Ukrainian, and Czech/Slovak letters into clean Latin slugs. | Settings • Docs |
| **7** | [**wp-allow-html-cats**](./wp-allow-html-cats/) | PHP + README | *Allow HTML in Category Descriptions* | Allows safe formatting HTML in taxonomy descriptions without disabling XSS filtering. | Settings • Docs |
| **8** | [**wp-auto-sku**](./wp-auto-sku/) | PHP + README | *Easy Auto SKU Generator* | Generates non-sequential random 5-digit SKUs (74921, 18304) and enables instant storewide search. | Settings • Docs |
| **9** | [**wp-online-counter**](./wp-online-counter/) | PHP + README | *Online Active Users, WP Online Counter* | Real-time counts of visitors, admins, editors, and shop managers in admin bar + user list column. | Settings • Docs |
| **10** | [**wp-simple-post-order**](./wp-simple-post-order/) | PHP + README | *Simple Custom Post Order, Post Types Order* | Native HTML5 drag-and-drop reordering for posts, products, and taxonomies (categories). | Settings • Docs |
| **11** | [**wp-seo-micro**](./wp-seo-micro/) | PHP + README | *Yoast SEO, Rank Math, All in One SEO* | Minimal SEO module: custom title, meta description, Open Graph tags, canonical URL, XML sitemap. | Settings • Docs |
| **12** | [**wp-test-email-micro**](./wp-test-email-micro/) | PHP + README | *WP Test Email* | Administrator-only on-demand email delivery test; no database logging or global mail interception. | Settings • Docs |

---

## ⚙️ Управление плагинами: Кнопки «Настройки» и «Документация» (Action Links)

У каждого плагина в таблице плагинов WordPress (`wp-admin/plugins.php`) под его заголовком встроены быстрые ссылки (по аналогии с **Google for WooCommerce**):
- **Настройки (Settings / Nastavení)** — прямой переход на единую страницу параметров плагина. Все доступные опции плагина собраны компактно на одной странице без лишних вкладок и сложных меню.
- **Документация (Documentation / Dokumentace)** — кликабельная ссылка на исходный код и описание модуля в GitHub.
- **Деактивировать (Deactivate)** — стандартное действие деактивации.

---

## 🛡️ Security, Patches & Hardening Tools

| Модуль / Документ | Назначение | Описание |
| :--- | :--- | :--- |
| [**htaccess_Shield**](./htaccess_Shield/) | `.htaccess` Security Shield | Готовый экранирующий `.htaccess` для защиты WordPress от сканеров, ботов, вредоносных query string и прямого доступа к файлам |
| [**flatsome-license-patch.md**](./flatsome-license-patch.md) | Патч темы Flatsome | Отключение внешних проверок лицензии и внешних пингов `api.uxthemes.com` внутри темы Flatsome |
| [**WordPress_Security_Shield_Guide.md**](./WordPress_Security_Shield_Guide.md) | Руководство по защите | Комплексный гайд по защите WordPress сайтов на Nginx, Apache и Cloudflare WAF |
| [**ADBLOCK_SAFE_FOOTER_BADGES.md**](./ADBLOCK_SAFE_FOOTER_BADGES.md) | Безопасные бейджи | Настройка чистых HTML/CSS счетчиков и бейджей в подвале без блокировки AdBlock |

---

## 🚀 Core Advantages

1. **Zero Database Bloat:** None of these plugins create extra MySQL tables or pollute `wp_options`.
2. **Sub-millisecond Execution:** Average execution overhead is under **0.5 ms**.
3. **Multilingual (EN / RU / CS):** Built-in seamless translation for English, Russian (`ru_RU`), and Czech (`cs_CZ`) in WordPress Admin, descriptions, and UI tools.
4. **All-In-One Settings Page:** Each plugin includes an intuitive single-page settings dashboard with smart defaults.
5. **Direct Plugin Action Links:** Fast access to Settings and Documentation directly from the WordPress Plugins list table.
6. **AdBlock Safe:** Free of external scripts, trackers, or React mount containers that break in ad blockers.

---

## 🛠️ Installation & Deployment

### Option A: Direct Copy to Plugins Directory
1. Copy the desired plugin folder (e.g. `wp-online-counter`) into `/wp-content/plugins/`.
2. In WordPress Admin, navigate to **Plugins** and click **Activate**.

### Option B: Upload via WordPress Admin
1. Compress the plugin folder into a standard `.zip` (e.g. `wp-online-counter.zip`).
2. In WordPress Admin, navigate to **Plugins** → **Add New** → **Upload Plugin**.
3. Choose the `.zip` file and click **Install Now** → **Activate**.


