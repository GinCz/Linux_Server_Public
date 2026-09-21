# ⚡ WordPress Ultra-Light Plugins Suite (VladiMIR+AI)

> **Repository:** [GinCz/plugins ↗](https://github.com/GinCz/plugins)  
> **Author:** `VladiMIR (GinCz) + AI`  
> **Brand Tag:** `(VladiMIR+AI✅)`  
> **Version Format:** `YYYY-MM__G.BB` (e.g. `2026-09__1.37`) — See [RULES.md ↗](RULES.md) for full versioning policy  
> **Roadmap & Plans:** [PLANS.md ↗](PLANS.md) — очереди и кандидаты на разработку микро-плагинов  

A collection of ultra-lightweight, secure, and high-performance micro-plugins for **WordPress** and **WooCommerce**, engineered by **VladiMIR (GinCz) + AI** and **Antigravity AI**.

These plugins serve as clean, 100% ad-free replacements for bloated third-party plugins from WordPress.org. They eliminate aggressive upgrade banners, tracking scripts, slow database queries, and vulnerable dashboards.

---

## 🔄 How the Native WordPress Auto-Update System Works

All plugins in this repository automatically update directly from WordPress without requiring external updater plugins, WP-CLI daemons, or paid licenses.

### 1. Architecture & Mechanism
```
┌───────────────────────────────┐
│     WordPress Admin / Core    │
│  (wp_version_check / WP-Cron) │
└───────────────┬───────────────┘
                │
                ▼ (Intercepted via 'Update URI: https://vladimir-ai.updates/<slug>')
┌───────────────────────────────┐
│   vladimir-ai-updater.php     │
│   (Shared Client in Plugins)  │
└───────────────┬───────────────┘
                │
                ▼ (HTTPS GET with 6-hour Transient Cache)
┌────────────────────────────────────────────────────────────────────────┐
│  https://raw.githubusercontent.com/GinCz/plugins/main/updates.json    │
└───────────────┬────────────────────────────────────────────────────────┘
                │
                ▼ (If new version available > installed version)
┌───────────────────────────────┐
│ WordPress Core Plugin Upgrader│ ──▶ Downloads ZIP: https://raw.githubusercontent.com/.../zips/<slug>.zip
│                               │ ──▶ Overwrites wp-content/plugins/<slug>/ seamlessly
└───────────────────────────────┘
```

1. **Header Declaration:** Each plugin specifies `Update URI: https://vladimir-ai.updates/<slug>` in its main PHP header. This tells WordPress core to bypass `wordpress.org` checks for this slug and route requests to our filter hook `update_plugins_vladimir-ai.updates`.
2. **Shared Updater Client (`vladimir-ai-updater.php`):** A byte-identical copy is included in each plugin. The first loaded plugin activates the updater, while others short-circuit, ensuring exactly one cacheable HTTP request.
3. **Manifest (`updates.json`):** Hosted in this public repository at `https://raw.githubusercontent.com/GinCz/plugins/main/updates.json`. WordPress caches the manifest in `_vladimir_ai_manifest` site transient for 6 hours.
4. **Security & Validation:** `vladimir_ai_update_package_allowed()` strictly enforces an allow-list: packages must originate from `https://github.com/GinCz/plugins/` or `https://raw.githubusercontent.com/GinCz/plugins/`.
5. **Admin Details Modal:** The updater hooks into `plugins_api` to render full plugin information, changelogs, and author details inside the native WordPress update dialog.

---

## 📦 Plugins Catalog (13 Modules)

| # | Plugin Slug | Name | Replaces | Action Links |
| :-: | :--- | :--- | :--- | :--- |
| **1** | [`404-410-301`](./404-410-301/) | `404-410-301 (SEO 404/410 + Auto-Redirect) (VladiMIR+AI✅)` | *404 to 301, Redirection* | Settings • Docs |
| **2** | [`classic-editor-tinymce`](./classic-editor-tinymce/) | `Classic Editor - TinyMCE (VladiMIR+AI✅)` | *Classic Editor + TinyMCE Advanced* | Settings • Docs |
| **3** | [`clean-head-meta`](./clean-head-meta/) | `Clean Head Meta & Anti-Fingerprint (VladiMIR+AI✅)` | *Head Meta Data, WP Hide* | Settings • Docs |
| **4** | [`disable-update-emails`](./disable-update-emails/) | `Disable Update Notification Emails (VladiMIR+AI✅)` | *Manage Notification E-mails* | Settings • Docs |
| **5** | [`image-resizer`](./image-resizer/) | `Image Resizer on Upload (VladiMIR+AI✅)` | *Imsanity, Resize Images* | Settings • Docs |
| **6** | [`translit-cyr-lat`](./translit-cyr-lat/) | `Cyrillic & European to Latin SEO Transliteration (VladiMIR+AI✅)` | *Cyr-To-Lat, RusToLat* | Settings • Docs |
| **7** | [`wp-allow-html-cats`](./wp-allow-html-cats/) | `Allow HTML in Category & Taxonomy Descriptions (VladiMIR+AI✅)` | *Allow HTML in Category Descriptions* | Settings • Docs |
| **8** | [`wp-auto-sku`](./wp-auto-sku/) | `WooCommerce Auto SKU Generator & SKU Search (VladiMIR+AI✅)` | *Easy Auto SKU Generator* | Settings • Docs |
| **9** | [`wp-bulk-delete-clean`](./wp-bulk-delete-clean/) | `WP Bulk Delete Clean (VladiMIR+AI✅)` | *WP Bulk Delete, Bulk Delete* | Tools • Docs |
| **10** | [`wp-online-counter`](./wp-online-counter/) | `Live Active Users & Visitors Counter (VladiMIR+AI✅)` | *Online Active Users, WP Online Counter* | Settings • Docs |
| **11** | [`wp-seo-micro`](./wp-seo-micro/) | `WP SEO Micro (VladiMIR+AI✅)` | *Yoast SEO, Rank Math, SEOPress* | Settings • Docs |
| **12** | [`wp-simple-post-order`](./wp-simple-post-order/) | `WP Simple Post & Category Order (VladiMIR+AI✅)` | *Simple Custom Post Order, Post Types Order* | Settings • Docs |
| **13** | [`wp-test-email-micro`](./wp-test-email-micro/) | `WP Test Email Micro (VladiMIR+AI✅)` | *WP Test Email* | Tools • Docs |

---

## 🌍 Multilingual Module Descriptions (8 Languages)

### 1. English (`en`)
* **`404-410-301`**: Returns true HTTP 404/410 for SEO and redirects visitors to homepage via smooth countdown (0–60s).
* **`classic-editor-tinymce`**: All-in-one classic editor: blocks Gutenberg, opens 2nd Word-like toolbar row (fonts, colors, tables).
* **`clean-head-meta`**: Cleans `<head>` clutter, hides WP version, removes pingbacks/emojis, adds `VladiMIR` author.
* **`disable-update-emails`**: Completely blocks automatic core, plugin, and theme update notification email spam.
* **`image-resizer`**: Automatically scales large uploads down to 1600×1600 px with crisp 95% JPEG quality.
* **`translit-cyr-lat`**: Fast SEO transliteration of Russian, Ukrainian, and Czech/Slovak letters into clean Latin slugs.
* **`wp-allow-html-cats`**: Allows safe formatting HTML in taxonomy descriptions without disabling XSS filtering.
* **`wp-auto-sku`**: Generates non-sequential random 5-digit SKUs (74921, 18304) and enables instant storewide search.
* **`wp-bulk-delete-clean`**: High-speed batch bulk deletion of posts, products, and taxonomies by date via AJAX with zero server timeouts and no ads.
* **`wp-online-counter`**: Real-time counts of visitors, admins, editors, and shop managers in admin bar + user list column.
* **`wp-seo-micro`**: Minimal SEO module: custom title, meta description, Open Graph tags, canonical URL, XML sitemap.
* **`wp-simple-post-order`**: Native HTML5 drag-and-drop reordering for posts, products, and taxonomies (categories).
* **`wp-test-email-micro`**: Administrator-only on-demand email delivery test; no database logging or global mail interception.

### 2. Русский (`ru`)
* **`404-410-301`**: Отдаёт поисковикам честный HTTP 404/410 для быстрого удаления битых ссылок из индекса и плавно перенаправляет посетителя на главную по таймеру.
* **`classic-editor-tinymce`**: Возвращает классический редактор: отключает Gutenberg и блочные виджеты, держит открытой вторую строку панели форматирования.
* **`clean-head-meta`**: Чистит мусор в `<head>`, скрывает номер версии WordPress, закрывает XML-RPC и пингбеки, убирает emoji-скрипты и добавляет авторские мета-теги.
* **`disable-update-emails`**: Полностью отключает спам уведомлениями об автообновлениях движка, плагинов и тем на почту администратора.
* **`image-resizer`**: Автоматически масштабирует огромные фото при загрузке до 1600×1600 px с сохранением качества 95% JPEG/WebP.
* **`translit-cyr-lat`**: Быстрая SEO-транслитерация кириллицы (RU, UA) и чешско-словацких символов в чистые латинские URL (slug).
* **`wp-allow-html-cats`**: Разрешает безопасное HTML-форматирование в описаниях рубрик и таксономий с защитой от XSS.
* **`wp-auto-sku`**: Генерирует уникальные случайные 5-значные артикулы (например, 74921) для товаров WooCommerce и ускоряет поиск по артикулу.
* **`wp-bulk-delete-clean`**: Быстрое массовое удаление постов, товаров WooCommerce и страниц по дате, статусу и рубрикам через AJAX без рекламы и зависаний сервера.
* **`wp-online-counter`**: Реальный счётчик онлайн-посетителей и администраторов в админ-баре и колонке пользователей.
* **`wp-seo-micro`**: Лёгкий SEO-модуль: title, meta description, Open Graph, канонические ссылки и XML-карта сайта без лишнего веса.
* **`wp-simple-post-order`**: Сортировка записей, страниц, товаров WooCommerce и рубрик перетаскиванием мышью.
* **`wp-test-email-micro`**: Диагностика почты по требованию: отправляет тестовое письмо через `wp_mail()` и показывает точную причину сбоя.

### 3. Čeština (`cs`)
* **`404-410-301`**: Vrací vyhledávačům korektní HTTP 404/410 pro rychlé odstranění mrtvých odkazů z indexu a návštěvníka plynule přesměruje na úvodní stránku s odpočtem.
* **`classic-editor-tinymce`**: Vrací klasický editor: vypíná Gutenberg i blokové widgety a nechává otevřenou druhou řádku formátovací lišty.
* **`clean-head-meta`**: Čistí nepořádek v `<head>`, skrývá verzi WordPressu, zavírá XML-RPC a pingbacky, odstraňuje emoji skripty a přidává autorské meta tagy.
* **`disable-update-emails`**: Zcela vypíná e-mailová oznámení o automatických aktualizacích jádra, pluginů a šablon.
* **`image-resizer`**: Automaticky zmenšuje velké nahrané obrázky na 1600×1600 px s vysokou kvalitou 95%.
* **`translit-cyr-lat`**: Rychlá SEO transliterace azbuky a českých/slovenských znaků s diakritikou do čistých URL.
* **`wp-allow-html-cats`**: Umožňuje bezpečné HTML formátování v popisech rubrik a taxonomií s ochranou proti XSS.
* **`wp-auto-sku`**: Generuje unikátní náhodné 5místné kódy SKU pro produkty WooCommerce a umožňuje okamžité vyhledávání.
* **`wp-bulk-delete-clean`**: Rychlé hromadné mazání příspěvků, produktů WooCommerce a stránek podle data, stavu a rubrik přes AJAX bez reklam a zasekávání serveru.
* **`wp-online-counter`**: Zobrazuje počet návštěvníků a administrátorů online v horní liště administrace.
* **`wp-seo-micro`**: Lehký SEO modul: titulky, meta popisy, Open Graph, kanonické odkazy a XML mapa webu.
* **`wp-simple-post-order`**: Řazení příspěvků, stránek, produktů WooCommerce a rubrik přetažením myší.
* **`wp-test-email-micro`**: Diagnostika pošty na vyžádání: odešle testovací e-mail přes `wp_mail()` a zobrazí přesnou příčinu selhání.

### 4. Deutsch (`de`)
* **`404-410-301`**: Liefert Suchmaschinen einen echten HTTP-404/410-Status zur schnellen Deindexierung toter Links und leitet Besucher sanft zur Startseite weiter.
* **`classic-editor-tinymce`**: Stellt den klassischen Editor wieder her: deaktiviert Gutenberg und hält die zweite Formatierungsleiste geöffnet.
* **`clean-head-meta`**: Räumt den `<head>` auf, verbirgt die WordPress-Version, schließt XML-RPC und Pingbacks, entfernt Emoji-Skripte.
* **`disable-update-emails`**: Deaktiviert Benachrichtigungs-E-Mails über automatische Updates von WordPress, Plugins und Themes.
* **`image-resizer`**: Skaliert große Bild-Uploads automatisch auf maximal 1600×1600 px bei 95% Qualität.
* **`translit-cyr-lat`**: Schnelle SEO-Transliteration von kyrillischen und Sonderzeichen in saubere URLs.
* **`wp-allow-html-cats`**: Ermöglicht sicheres HTML in Kategorie- und Taxonomie-Beschreibungen.
* **`wp-auto-sku`**: Generiert zufällige 5-stellige Artikelnummern (SKUs) für WooCommerce und aktiviert Schnellsuche.
* **`wp-bulk-delete-clean`**: Schnelles Massenlöschen von Beiträgen, WooCommerce-Produkten und Seiten nach Datum, Status und Kategorien per AJAX.
* **`wp-online-counter`**: Echtzeitzähler aktiver Besucher und Administratoren in der Admin-Leiste.
* **`wp-seo-micro`**: Schlankes SEO-Modul: Title, Meta-Description, Open Graph, kanonische URLs und XML-Sitemap.
* **`wp-simple-post-order`**: Sortierung von Beiträgen, Seiten, Produkten und Kategorien per Drag-and-drop.
* **`wp-test-email-micro`**: Mail-Diagnose auf Abruf: versendet eine Testnachricht über `wp_mail()` und zeigt die genaue Fehlerursache.

### 5. Italiano (`it`)
* **`404-410-301`**: Restituisce ai motori di ricerca un vero stato HTTP 404/410 e reindirizza i visitatori alla home con conto alla rovescia.
* **`classic-editor-tinymce`**: Ripristina l'editor classico: disattiva Gutenberg e mantiene aperta la seconda barra di formattazione.
* **`clean-head-meta`**: Pulisce l'intestazione `<head>`, nasconde la versione di WordPress e chiude XML-RPC.
* **`disable-update-emails`**: Blocca le e-mail di notifica per gli aggiornamenti automatici di core, plugin e temi.
* **`image-resizer`**: Ridimensiona automaticamente i caricamenti di grandi immagini a 1600×1600 px.
* **`translit-cyr-lat`**: Traslitterazione SEO veloce per caratteri cirillici ed europei in slug URL puliti.
* **`wp-allow-html-cats`**: Consente formattazione HTML sicura nelle descrizioni delle categorie e tassonomie.
* **`wp-auto-sku`**: Genera SKU casuali a 5 cifre per prodotti WooCommerce con ricerca istantanea.
* **`wp-bulk-delete-clean`**: Eliminazione di massa rapida di articoli, prodotti WooCommerce e pagine per data, stato e tassonomie tramite AJAX.
* **`wp-online-counter`**: Conteggio in tempo reale di visitatori e amministratori online nella barra di amministrazione.
* **`wp-seo-micro`**: Modulo SEO leggero: title, meta description, tag Open Graph, URL canonici e sitemap XML.
* **`wp-simple-post-order`**: Ordinamento di articoli, pagine, prodotti WooCommerce e categorie tramite trascinamento.
* **`wp-test-email-micro`**: Diagnostica e-mail su richiesta: invia un messaggio di prova tramite `wp_mail()` e mostra l'errore.

### 6. Español (`es`)
* **`404-410-301`**: Devuelve a los buscadores un estado HTTP 404/410 real y redirige a las visitas a la portada con cuenta atrás.
* **`classic-editor-tinymce`**: Restaura el editor clásico: desactiva Gutenberg y mantiene abierta la segunda barra de formato.
* **`clean-head-meta`**: Limpia `<head>`, oculta la versión de WordPress, cierra XML-RPC y pingbacks.
* **`disable-update-emails`**: Desactiva los correos de notificación por actualizaciones automáticas de WordPress, plugins y temas.
* **`image-resizer`**: Escala automáticamente imágenes pesadas subidas a 1600×1600 px manteniendo alta calidad.
* **`translit-cyr-lat`**: Transliteración SEO rápida de caracteres cirílicos y europeos a URLs limpias.
* **`wp-allow-html-cats`**: Permite HTML seguro en las descripciones de categorías y taxonomías.
* **`wp-auto-sku`**: Genera códigos SKU aleatorios de 5 dígitos para WooCommerce y habilita búsqueda rápida.
* **`wp-bulk-delete-clean`**: Eliminación masiva rápida de entradas, productos de WooCommerce y páginas por fecha, estado y taxonomías mediante AJAX.
* **`wp-online-counter`**: Contador en tiempo real de visitas y administradores online en la barra superior.
* **`wp-seo-micro`**: Módulo SEO ligero: title, meta description, etiquetas Open Graph, URL canónicas y sitemap XML.
* **`wp-simple-post-order`**: Ordenación de entradas, páginas, productos y categorías arrastrando y soltando.
* **`wp-test-email-micro`**: Diagnóstico de correo a demanda: envía un mensaje de prueba mediante `wp_mail()` y muestra el fallo.

### 7. Français (`fr`)
* **`404-410-301`**: Renvoie aux moteurs un vrai statut HTTP 404/410 et redirige les visiteurs vers l'accueil avec un compte à rebours.
* **`classic-editor-tinymce`**: Rétablit l'éditeur classique : désactive Gutenberg et garde ouverte la 2ème barre d'outils.
* **`clean-head-meta`**: Nettoie `<head>`, masque la version de WordPress, désactive XML-RPC et les emojis.
* **`disable-update-emails`**: Bloque complètement les e-mails de notification des mises à jour automatiques.
* **`image-resizer`**: Redimensionne automatiquement les images téléversées à 1600×1600 px à 95% de qualité.
* **`translit-cyr-lat`**: Translittération SEO rapide des caractères cyrilliques et européens en permaliens latins propres.
* **`wp-allow-html-cats`**: Autorise le formatage HTML sécurisé dans les descriptions de catégories.
* **`wp-auto-sku`**: Génère des références SKU uniques aléatoires à 5 chiffres pour WooCommerce.
* **`wp-bulk-delete-clean`**: Suppression groupée rapide d'articles, produits WooCommerce et pages par date, statut et taxonomies via AJAX.
* **`wp-online-counter`**: Compteur en temps réel des visiteurs et administrateurs connectés.
* **`wp-seo-micro`**: Module SEO ultra-léger : title, meta description, Open Graph, URL canoniques et plan de site XML.
* **`wp-simple-post-order`**: Tri des articles, pages, produits WooCommerce et catégories par glisser-déposer.
* **`wp-test-email-micro`**: Diagnostic e-mail à la demande : envoie un message de test via `wp_mail()` avec diagnostic précis.

### 8. Polski (`pl`)
* **`404-410-301`**: Zwraca wyszukiwarkom prawdziwy status HTTP 404/410 i płynnie przekierowuje na stronę główną z odliczaniem.
* **`classic-editor-tinymce`**: Przywraca klasyczny edytor: wyłącza Gutenberga i trzyma otwarty drugi rząd paska narzędzi.
* **`clean-head-meta`**: Czyści nagłówek `<head>`, ukrywa wersję WordPressa, blokuje XML-RPC i skrypty emoji.
* **`disable-update-emails`**: Całkowicie wyłącza powiadomienia e-mail o automatycznych aktualizacjach WordPressa, wtyczek i motywów.
* **`image-resizer`**: Automatycznie zmniejsza duże wgrywane zdjęcia do 1600×1600 px z jakością 95%.
* **`translit-cyr-lat`**: Szybka transliteracja SEO cyrylicy i znaków diakrytycznych na czyste adresy URL.
* **`wp-allow-html-cats`**: Umożliwia bezpieczne formatowanie HTML w opisach kategorii i taksonomii.
* **`wp-auto-sku`**: Generuje losowe 5-cyfrowe kody SKU dla produktów WooCommerce i umożliwia szybkie wyszukiwanie.
* **`wp-bulk-delete-clean`**: Szybkie masowe usuwanie wpisów, produktów WooCommerce i stron według daty, statusu i kategorii przez AJAX.
* **`wp-online-counter`**: Licznik online aktywnych użytkowników i gości w czasie rzeczywistym.
* **`wp-seo-micro`**: Lekki moduł SEO: title, meta description, znaczniki Open Graph, adresy kanoniczne i mapa XML.
* **`wp-simple-post-order`**: Sortowanie wpisów, stron, produktów WooCommerce i kategorii metodą przeciągnij i upuść.
* **`wp-test-email-micro`**: Diagnostyka poczty na żądanie: wysyła wiadomość testową przez `wp_mail()` i diagnozuje błędy.

---

## 💾 Local Storage on Laptop

On the local laptop, all plugins are mirrored directly in:
* **Folder:** `D:\MEGA\WordPress\<slug>\`
* **ZIP Archives:** `D:\MEGA\WordPress\<slug>-(VladiMIR+AI).zip`

---

## 📜 License

All plugins are released under the [GPL-2.0-or-later](https://www.gnu.org/licenses/gpl-2.0.html) license.
