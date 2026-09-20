# WP Bulk Delete Clean (VladiMIR+AI✅)

Fast, lightweight, ad-free bulk deletion plugin for WordPress and WooCommerce with real-time AJAX batch processing, zero memory limits, and zero server timeouts.

## ✨ Features

- **Multi Post Type Support:** Bulk delete Posts (`post`), WooCommerce Products (`product`), Pages (`page`), Media (`attachment`), or any registered Custom Post Types.
- **Granular Date Filtering:**
  - All dates (no filter)
  - Older than X days (e.g. 30, 90, 365 days)
  - Created within the last X days
  - Created BEFORE a specific date (`< YYYY-MM-DD`)
  - Created AFTER a specific date (`> YYYY-MM-DD`)
  - Exact Date Range (From `YYYY-MM-DD` To `YYYY-MM-DD`)
  - Choose between Published Date (`post_date`) and Modified Date (`post_modified`).
- **Post Status Filtering:** Publish, Draft, Pending, Private, Trash, Future, or Any Status.
- **Taxonomy & Category Filtering:** Dynamically loads Categories, Tags, and Custom Taxonomies (including WooCommerce `product_cat` & `product_tag`).
- **Safe & Fast Execution:**
  - Deletion Mode: **Permanently Delete** (bypasses Trash) or **Move to Trash** (soft delete).
  - Optional cleanup of attached images/media files.
  - Chunked AJAX batching (50, 100, 250, 500 items per request) + throttle delay to prevent PHP timeouts / memory exhaustion on heavy sites (100k+ items).
  - Live animated Progress Bar (0–100%), count metrics, and real-time activity log console.
  - Interactive controls: **Preview / Calculate Count**, **Start**, **Pause**, **Resume**, **Stop**.
- **100% Free & Clean:** No ads, no banners, no upsells, no external telemetry.
- **Multilingual:** Supports EN, RU, CS, DE, IT, ES, FR, PL.

## 🚀 Installation

1. Upload the `wp-bulk-delete-clean` folder to `/wp-content/plugins/`
2. Activate the plugin in **Plugins** menu.
3. Open **Tools -> WP Bulk Delete** (`tools.php?page=wp-bulk-delete-clean`).

## ⚙️ Requirements

- WordPress 6.0+
- PHP 7.4+ (fully compatible with PHP 8.0, 8.1, 8.2, 8.3, 8.4+)

## 👤 Author

**VladiMIR ([GinCz](https://github.com/GinCz)) + AI**  
Part of the [VladiMIR+AI WordPress Plugin Suite](https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins).
