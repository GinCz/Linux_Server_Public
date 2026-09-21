# WP SEO Micro (VladiMIR+AI✅)

Ultra-lightweight, high-performance complete Search Engine Optimization (SEO) engine for WordPress and WooCommerce. Zero database bloat, zero advertising spam, zero slow API queries — 100% clean and lightning-fast SEO.

Designed as a direct, lightweight replacement for bloated plugins like **SEOPress**, **Yoast SEO**, and **Rank Math**, with seamless automatic backward compatibility.

---

## 🚀 Key Features & Capabilities

### 1. Smart Title & Meta Description Engine
- **Homepage Snippet:** Customizable site title template (`Site Name > Description`) and custom homepage meta description.
- **Single Posts, Pages & Products:** Automated formula `Post Title > Site Name` with support for custom overrides.
- **Taxonomies & Categories:** Automatic clean title and description for WooCommerce product categories (`product_cat`), blog categories (`category`), and product brands.
- **404 & Search Results:** Localized search query titles (`Поиск: query > Site Name` / `Vyhledávání: query > Site Name`) and standard `404 > Site Name`.

### 2. Full Robots Indexation Control (Crawl Budget Protection)
- **Automatic `index, follow`:** Front page, blog posts, pages, WooCommerce products, categories, product brands.
- **Automatic `noindex, follow` (Thin & Duplicate Protection):**
  - Search query results (`is_search()`)
  - 404 error pages (`is_404()`)
  - Author archive pages (`is_author()`)
  - Date archives (`is_date()`)
  - Tags and product tags (`is_tag()`, `product_tag`)
  - Media attachment pages (`is_attachment()`)
  - Archive pagination (`is_paged()`, e.g. `/page/2/`)
- **Automatic `noindex, nofollow`:** flatsome `ux_block`, `wp_block`, `elementor_library` templates.

### 3. Native XML Sitemap with Image Support
- **Dual URLs:** Operates seamlessly at `/sitemap.xml` and `/sitemaps.xml` (SEOPress legacy compatibility).
- **Google Images & Yandex XML:** Embeds `<image:image><image:loc>...</image:loc><image:title>...</image:title></image:image>` tags for featured images and product media.
- **High-Speed In-Memory Caching:** 12-hour transient cache automatically purged on `save_post` or `edited_term`.
- **Automatic `robots.txt` Integration:** Automatically injects `Sitemap: https://.../sitemap.xml` into virtual `robots.txt`.

### 4. Automated Image SEO (Sanitization & Auto-Alt)
- **Media Upload Sanitization:** Cleans uploaded file names on the fly — strips diacritics/accents, converts to lowercase, replaces spaces and symbols with single dashes (`ExAmple 1 cOpy!.jpg` ➔ `example-1-copy.jpg`).
- **Auto-Alt on Upload:** Automatically generates clean, readable Alt text from file name upon upload if empty.
- **Frontend Fallback Alt:** Automatically populates empty `alt=""` or missing `alt` attributes in post/product content with post target keywords or title.

### 5. Head & HTTP Headers Cleanup (Speed & Security)
- **Emoji Scripts & Styles:** Removes WordPress emoji detection scripts, inline styles, DNS prefetch to `s.w.org`, and TinyMCE emoji plugin.
- **Meta Bloat Removal:** Strips `wp_generator` (`<meta name="generator">`), `rsd_link` (EditURI), `wlwmanifest_link` (Windows Live Writer), and `shortlink`.
- **oEmbed Cleanup:** Removes oEmbed discovery links and host scripts.
- **Comment Cleanup:** Rewrites `/?replytocom=X` comment links into direct anchor `#comment-X` to prevent bot crawling traps and duplicate URLs.
- **Google Schema Fix:** Removes rogue `hentry` post class that causes Google Search Console missing author/date warnings.
- **HTTP Header Cleanser:** Unsets `X-Pingback` and disables pingbacks; unsets `X-Powered-By`.

### 6. 301 Permanent Redirects for Junk Archives
- **Author Archives:** Redirects author pages to homepage (prevents username enumeration and content duplicates).
- **Date Archives:** Redirects date-based archives to homepage.
- **Attachment Pages:** Redirects attachment pages directly to parent post/page or homepage.

### 7. Search Engine Webmaster Verification
- Built-in meta tag generation for:
  - **Google Search Console** (`google-site-verification`)
  - **Yandex Webmaster** (`yandex-verification`)
  - **Seznam.cz Webmaster** (`seznam-wmt`)
  - **Bing Webmaster** (`msvalidate.01`)
  - **Pinterest Domain** (`p:domain_verify`)
  - **Baidu Webmaster** (`baidu-site-verification`)
  - **Facebook Domain Verification** (`facebook-domain-verification`)

### 8. Social Open Graph (OG) & Canonical URLs
- Complete Open Graph tags: `og:title`, `og:description`, `og:url`, `og:image`, `og:site_name`, `og:type`.
- Accurate canonical URL generation protecting against parameter duplicates.

### 9. 100% Backward Compatibility (SEOPress & Yoast)
- Automatically reads previously saved metadata without database conversion:
  - `_seopress_titles_title` / `_yoast_wpseo_title`
  - `_seopress_titles_desc` / `_yoast_wpseo_metadesc`
  - `_seopress_analysis_target_kw` / `_yoast_wpseo_focuskw`
  - `_seopress_titles_canonical`
  - `_seopress_robots_index`
  - `_seopress_social_fb_img`
  - Webmaster verification codes from `seopress_advanced_option_name`

---

## 🛠️ Installation

1. Download or clone this repository to `/wp-content/plugins/wp-seo-micro/`.
2. Activate via WordPress admin panel (**Plugins** -> **Installed Plugins**).
3. Navigate to **Settings** -> **WP SEO Micro** to configure site description, keywords, and verification codes.

---

## ⚙️ Requirements

- **WordPress:** 6.0+
- **PHP:** 7.4+ (fully PHP 8.0, 8.1, 8.2, 8.3 & 8.4 compatible)

---

## 👤 Author

**VladiMIR ([GinCz](https://github.com/GinCz)) + AI**  
Part of the [VladiMIR+AI WordPress Plugin Suite](https://github.com/GinCz) — ultra-lightweight replacements for bloated third-party plugins.

---

## 📄 License

GPL-2.0-or-later
