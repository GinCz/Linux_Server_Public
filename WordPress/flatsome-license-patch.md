# Flatsome Theme — License Ping Disabler & Admin Patch

> **Rooted by VladiMIR + AI | v.2026.07.08 | github.com/GinCz**
> 
> *Repository:* [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public)

---

## 📌 Problem Overview

By default, the Flatsome theme executes remote HTTP verification requests to `api.uxthemes.com` on admin page loads. When unregistered, it generates persistent warning banners across `wp-admin` and schedules repetitive cron events, increasing page latency.

**Solution:** Replace the internal theme registration class with an ultra-lightweight null stub with matching class signatures.

> ⚠️ **Important:** Do NOT use an `mu-plugin` for this patch. An `mu-plugin` executes before theme and plugin initializations, resulting in class stub conflicts with WooCommerce and potential HTTP 500 fatal errors. Apply the stub directly inside the theme directory.

---

## ⚙️ Target File to Replace

```text
flatsome/inc/classes/class-flatsome-wupdates-registration.php
```

---

## 💻 Replacement Stub Code

Replace the entire contents of `class-flatsome-wupdates-registration.php` with:

```php
<?php
/**
 * Flatsome_WUpdates_Registration — PATCHED (No Remote License Checks)
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
        // Disables scheduled hooks and external verification pings
    }

    public function register( $code ) {
        return array( 'status' => 'ok' );
    }

    public function unregister() {
        return array( 'status' => 'ok' );
    }

    public function is_registered() {
        return true;
    }

    public function get_registration_data() {
        return array(
            'purchase_code' => 'ACTIVE-ENTERPRISE-LICENSE',
            'status'        => 'registered',
        );
    }
}
```

---

## 🚀 Key Advantages
- **Zero Latency:** Eliminates all blocking outbound HTTP requests to `api.uxthemes.com`.
- **Clean UI:** Removes all nag screens and unregistered notices across `wp-admin`.
- **Full Theme Functionality:** UX Builder and template customizer remain 100% operational.
