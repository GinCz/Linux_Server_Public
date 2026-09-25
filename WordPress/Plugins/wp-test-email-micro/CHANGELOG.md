# CHANGELOG - WP Test Email Micro

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

---

## 2026-09__1.38 — 2026-09-25

- **One-click Mail-Tester check.** The plugin now builds the Mail-Tester address itself (`test-<9 random characters>@srv1.mail-tester.com`), sends the same rich diagnostic message to it and polls the public report page every three seconds until the verdict appears, giving up after 180 seconds. No API, account, key or third-party library is involved: Mail-Tester's own front page generates that address in the visitor's browser, so the plugin reproduces it server-side. The previous copy-and-paste instructions are gone.
- **Three live figures.** Seconds from dispatch to analysed report, the score out of ten (green from 9, amber from 7, red below) with AUTH / SPAM / LIST flags, and the milliseconds `wp_mail()` itself needed. The two timings measure different things and are deliberately shown apart: only the first one describes the real journey of the message.
- **Big button to the full report** appears as soon as the address is created, so the verdict can be opened on mail-tester.com at any moment.
- **DNS panel.** SPF, DKIM, DMARC, MX and PTR are read straight from the resolvers with no external service. DKIM is recognised both as TXT and as CNAME, because Seznam publishes the provider key as a CNAME. The selector is editable: `dkim` is the server key that Exim/FastPanel uses for site mail, while `mail`, `mailru` or `szn20221014` show the provider key.
- **Shared dispatch path.** The manual form and the Mail-Tester run now go through one function, so both send byte-identical messages and both report the transport time.

---

## 2026-09__1.37 — 2026-09-21

- **Codebase maintenance & independence**: Removed standalone updater dependency, streamlined standalone micro-plugin architecture, synchronized suite versioning.

---

## 2026-09__1.36 — 2026-09-20

- Added substantial diagnostic, server environment, and deliverability compliance text to the email body to achieve an optimal text-to-image ratio and eliminate SpamAssassin `HTML_IMAGE_RATIO` penalty.
- Enhanced site logo embedding with graceful fallback to styled site branding badge when no logo is configured.
- Synchronized rich multipart/alternative plain-text AltBody for complete MIME deliverability.
- Updated direct GitHub updater endpoint and package verification.

---
## 2026-09__1.34 — 2026-09-20

- Replaced the shared suite updater dependency with a plugin-specific update checker.
- Test Email now checks only its own manifest entry and release package.
- Removed the stale six-hour shared manifest cache that could hide a newly published version after pressing **Check again** in WordPress.
- No other plugin version or release is changed.

---
## 2026-09__1.33 — 2026-09-20

- Added a prominent **Open Mail Tester** button that opens the deliverability service in a new tab.
- Replaced the raw HTML textarea with a readable English plain-text message field.
- The outgoing HTML email now inserts the current site logo automatically and includes a large **Open Website** button plus the visible site URL.
- Released only `wp-test-email-micro`; no other plugin version is changed.

---
## 2026-09__1.32 — 2026-09-20

- Restored the green check mark in the WordPress plugin name after the UTF-8 cleanup.

---
## 2026-09__1.31 — 2026-09-20

- Replaced the malformed mixed-encoding source with a UTF-8-only admin screen.
- Made the complete form, status messages, subject, and default HTML message English.
- Simplified the default email to a neutral website check: it contains the site's own URL and its current custom logo (or site icon as a fallback).
- Removed mail-scoring and promotional wording from the default message. Delivery still depends on the site's configured SMTP/PHP mail transport and sender-domain authentication.

---
## 2026-09__1.24 — 2026-09-20

- **Окончательное устранение аварии с HTTP 500.** Общие модули (`vladimir-ai-updater.php`, `vladimir-ai-i18n.php`) больше не дублируются в каждом плагине — они поставляются только внутри `404-410-301`, остальные плагины подключают их, если файл есть, и прекрасно работают без него.
- Почему так: копии разных выпусков, лежащие рядом, вызывали повторное объявление функций и роняли весь сайт. Правка кода не помогала — PHP-FPM отдавал старый байткод из OPcache, и спасало только физическое удаление лишних файлов. Одна копия — проблема исчезает в принципе.
- Скрипт развёртывания `WordPress/deploy/wp_deploy_vladimir_plugins.sh` теперь сам удаляет оставшиеся копии со старых установок.

---

## 2026-09__1.23 — 2026-09-20

- **Исправлена фатальная ошибка, из-за которой сайты отдавали HTTP 500.** Общие модули (`vladimir-ai-updater.php`, `vladimir-ai-i18n.php`) лежат копией в папке каждого плагина. Когда на сайте оказывались копии разных выпусков, защиты по константе не хватало — PHP получал повторное объявление функции (`Cannot redeclare vladimir_ai_update_manifest()`) и сайт падал целиком.
- Теперь оба модуля проверяют не только константу, но и наличие самой функции. Несколько копий рядом больше не опасны, даже если они из разных версий или отдаются из устаревшего кэша PHP (OPcache).

---

## 2026-09__1.22 — 2026-09-20

- Синхронизация с релизом пакета: общий клиент обновлений и модуль переводов обновлены до этой версии.
- Из пакета удалён плагин `wc-admin-default-sort-date` — он объединён с `wp-simple-post-order`, где сортировка списков в админке стала настраиваемой и по умолчанию не трогает товары.

---

## 2026-09__1.21 — 2026-09-20

- **Окончательный адрес плагинов.** Пакет живёт в публичном репозитории `GinCz/Linux_Server_Public`, путь `WordPress/Plugins/<плагин>`. Все ссылки внутри плагина (`Plugin URI`, кнопка «Документация», подвал страницы настроек) переписаны на это место; промежуточные адреса `Secret_Privat` и `WordPress-Plugins` больше не используются.
- **Автообновление без токенов.** Репозиторий публичный: клиент обновлений берёт манифест обычным запросом к `raw.githubusercontent.com`, ZIP скачивается как публичный релиз. В `wp-config.php` ничего прописывать не нужно.
- **Безопасность автообновления.** Ссылка на архив из манифеста теперь проверяется по строгому списку: устанавливается только HTTPS-релиз из `github.com/GinCz/Linux_Server_Public`. Подменённый манифест не сможет указать сайту на чужой архив.
- Добавлен `index.php` («Silence is golden») в папку плагина — защита от листинга каталога на серверах с включённым индексом.

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
- Unified update mechanism with GitHub API updater: Update URI: https://vladimir-ai.updates/wp-test-email-micro + ladimir-ai-updater.php.
- Standardized metadata requirements: Requires at least: 6.0 and Requires PHP: 7.4.
- Reorganized codebase into clean modular architecture.
