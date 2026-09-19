# CHANGELOG - Smart Image Resizer on Upload

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

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
- Unified update mechanism with GitHub API updater: Update URI: https://vladimir-ai.updates/image-resizer + ladimir-ai-updater.php.
- Standardized metadata requirements: Requires at least: 6.0 and Requires PHP: 7.4.
- Reorganized codebase into clean modular architecture.
