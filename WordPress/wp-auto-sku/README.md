# WP Auto SKU 5 Digits (VladiMIR+AI)

**Version:** 2026.09.11
**Requires:** WooCommerce
**License:** GPL-2.0-or-later

## Purpose

Assigns an unused five-digit numeric SKU such as `00042` when a new WooCommerce product has no SKU. Existing product SKUs remain unchanged during ordinary editing.

## Full-store regeneration

**Tools → Auto SKU → Regenerate All Product SKUs** intentionally overwrites every product SKU with sequential five-digit values in product-ID order. It has a capability check, WordPress nonce, and browser confirmation. It does not alter variation SKUs.

Use regeneration only after exporting a WooCommerce product backup and checking that no accounting, feed, marketplace, or barcode system relies on existing SKU values.

## Security and performance

The plugin creates no database tables, cron jobs, settings, remote requests, or frontend assets. It uses WooCommerce's SKU lookup to avoid an automatic duplicate. The all-products action is administrator-only.

## Installation

1. Confirm WooCommerce is active.
2. Copy the `wp-auto-sku` directory to `wp-content/plugins/`.
3. Activate **WP Auto SKU 5 Digits**.
4. Create a test product and confirm that it receives a five-digit SKU.
