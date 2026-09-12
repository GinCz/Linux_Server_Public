# Flatsome Theme — License & External Pings Patch
> Rooted by VladiMIR + AI | v.2026.07.08 | github.com/GinCz

---

## Overview

The Flatsome WordPress theme performs external license validation requests to `api.uxthemes.com` on every WordPress admin request. This degrades server performance, creates external dependencies, and displays intrusive license warning notices in `wp-admin` when no license key is registered.

**Solution:** Replace a single file inside the theme with a clean stub class having the exact same signature. No `mu-plugins`, no filter hacks — just a lightweight drop-in class.

> ⚠️ **Why mu-plugins should NOT be used:** An `mu-plugin` loads before the theme and plugins. Mocking core theme/WooCommerce classes inside `mu-plugins` can conflict with genuine WooCommerce classes and trigger HTTP 500 fatal errors across sites. Always patch directly inside the theme files.

---

## WooCommerce Compatibility

Flatsome cleanly checks `is_woocommerce_activated()` (which calls `class_exists('woocommerce')`). If WooCommerce is not installed, all WooCommerce-related template code is safely skipped. No additional patches or modifications are required.

---

## Target File to Patch

```
wp-content/themes/flatsome/inc/classes/class-flatsome-wupdates-registration.php
```

This file contains the `Flatsome_WUpdates_Registration` class that:
- Sends outbound HTTP requests to `api.uxthemes.com` and `wupdates.com`
- Registers the recurring cron job `flatsome_scheduled_registration`
- Renders admin notices requesting license activation

---

## Stub Replacement Code (Replace Entire File)

```php
<?php
/**
 * Flatsome_WUpdates_Registration — PATCHED (no license checks)
 * = Rooted by VladiMIR + AI | v.2026.07.08 | github.com/GinCz =
 *
 * @package Flatsome
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

final class Flatsome_WUpdates_Registration extends Flatsome_Base_Registration {

    public function __construct( UxThemes_API $api ) {
        parent::__construct( $api, 'flatsome_wupdates' );
        // No scheduled hooks, no external pings
    }

    public function register( $code ) {
        return array( 'status' => 'ok' );
    }

    public function unregister() {
        return array();
    }

    public function get_latest_version() {
        return false; // Disable auto-update checks
    }

    public function get_download_url( $version ) {
        return new WP_Error( 'disabled', 'Updates disabled.' );
    }

    public function is_registered() {
        return true; // Always registered
    }

    public function is_verified() {
        return true; // Always verified
    }

    public function delete_options() {
        parent::delete_options();
    }

    public function get_code() {
        return '00000000-0000-0000-0000-000000000000';
    }

    public function migrate_registration() {
        // No migration — no external calls
    }
}
```

---

## Method 1 — Patch Theme ZIP Archive (Windows / Pre-deployment)

Theme archive: `flatsome-3.18.1__Lic_VladiMIR.zip`

1. Open the zip archive in **Total Commander** or 7-Zip.
2. Navigate into `flatsome/inc/classes/`.
3. Locate `class-flatsome-wupdates-registration.php`.
4. Extract the file, replace its content with the stub above, and save.
5. Drag the updated file back into the archive to overwrite.

Any new site installation using this pre-patched archive will be completely free of license notices and external checks.

---

## Method 2 — Server Batch Deployment (Linux)

Run the following script on your server:

```bash
cat > /tmp/patch.php << 'EOF'
<?php
/**
 * Flatsome_WUpdates_Registration — PATCHED (no license checks)
 * = Rooted by VladiMIR + AI | v.2026.07.08 | github.com/GinCz =
 *
 * @package Flatsome
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

final class Flatsome_WUpdates_Registration extends Flatsome_Base_Registration {

    public function __construct( UxThemes_API $api ) {
        parent::__construct( $api, 'flatsome_wupdates' );
    }

    public function register( $code ) {
        return array( 'status' => 'ok' );
    }

    public function unregister() {
        return array();
    }

    public function get_latest_version() {
        return false;
    }

    public function get_download_url( $version ) {
        return new WP_Error( 'disabled', 'Updates disabled.' );
    }

    public function is_registered() {
        return true;
    }

    public function is_verified() {
        return true;
    }

    public function delete_options() {
        parent::delete_options();
    }

    public function get_code() {
        return '00000000-0000-0000-0000-000000000000';
    }

    public function migrate_registration() {}
}
EOF

# Verify PHP syntax
php -l /tmp/patch.php && echo "Syntax OK"

# Apply to all Flatsome theme installations under /var/www
for f in $(find /var/www -name "class-flatsome-wupdates-registration.php" -path "*/themes/flatsome/*" 2>/dev/null | sort); do
    cp /tmp/patch.php "$f"
    domain=$(echo "$f" | grep -oP '/www/\K[^/]+')
    echo "  [OK] $domain"
done

echo "Total patched: $(find /var/www -name 'class-flatsome-wupdates-registration.php' -path '*/themes/flatsome/*' | wc -l)"
rm -f /tmp/patch.php
echo "DONE"
```

---

## Verification

```bash
# Verify no external domains remain in the patched file
grep -i "wupdates\|uxthemes\|api\." \
  /var/www/USER/data/www/DOMAIN/wp-content/themes/flatsome/inc/classes/class-flatsome-wupdates-registration.php
# Output should be empty
```

---

## Comparison: Original vs Patched

| Method | Original Behavior | Patched Behavior |
|---|---|---|
| `is_registered()` | Queries MySQL DB | Always returns `true` |
| `is_verified()` | Always `true` | Always returns `true` |
| `get_code()` | Reads from DB | Returns dummy UUID |
| `register()` | Outbound HTTP to `api.uxthemes.com` | Returns `['status'=>'ok']` |
| `get_latest_version()` | Outbound HTTP via cron | Returns `false` |
| `migrate_registration()` | Outbound HTTP to `/v1/license/` | Empty function |
| `__construct()` | Hooks recurring cron job | Zero cron hooks |

**Result:** Zero outbound network traffic, zero admin banners, and automated theme updates disabled.
