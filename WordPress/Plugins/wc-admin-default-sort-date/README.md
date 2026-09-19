# WooCommerce Admin Products Default Sort by Date DESC (VladiMIR+AI)

**Version:** 2026-09__1.19  
**Author:** VladiMIR (GinCz) + AI  
**License:** GPL-2.0-or-later  
**Requires:** WordPress 6.0+, WooCommerce 7.0+, PHP 7.4+  

---

### đź“Ś Description
Ensures that the WooCommerce admin product list (wp-admin/edit.php?post_type=product) defaults to sorting by publication date in descending order (newest products first) when no specific sorting column is selected by the user.

### đźš€ Key Features
- **Zero Database Overhead:** Executes via the pre_get_posts hook with negligible sub-millisecond footprint.
- **Smart Preservation:** Does not interfere when administrators explicitly sort by title, SKU, price, or stock.
- **Full Compatibility:** Works seamlessly with WooCommerce HPOS (High-Performance Order Storage) and standard post tables.

### đź“¦ Installation
1. Upload the wc-admin-default-sort-date folder to /wp-content/plugins/.
2. Activate the plugin via the **Plugins** menu in WordPress Admin.
