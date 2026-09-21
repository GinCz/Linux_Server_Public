# CHANGELOG - WP SEO Micro

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

---

## 2026-09__1.38 — 2026-09-21

### 🚀 Полный паритет функционала и 100% замена SEOPress (SEOPress Full Feature Parity)

- **Комплексная очистка исходного кода и ускорение (Head & HTTP Headers Cleaner):**
  - Удаление скриптов и стилей Emoji (`print_emoji_detection_script`, `print_emoji_styles`, `wp_staticize_emoji`, DNS prefetch `s.w.org`, плагин TinyMCE).
  - Удаление мусорных мета-тегов: `wp_generator`, `rsd_link` (EditURI), `wlwmanifest_link` (Windows Live Writer), `shortlink`.
  - Удаление discovery-ссылок и скриптов oEmbed.
  - Удаление класса `hentry` из `post_class`, что устраняет ложные предупреждения Google Schema о датах/авторах.
  - Перезапись ссылок `/?replytocom` в форме комментариев на прямые якоря `#comment-X` (устранение ловушек для краулеров).
  - Очистка заголовков HTTP: удаление `X-Pingback` и отключение пингбэков, удаление заголовка `X-Powered-By`.
- **Автоматизированное SEO для изображений (Automated Image SEO):**
  - Автоматическая очистка и санитизация имени файла при загрузке в медиабиблиотеку (`sanitize_file_name`): транслитерация диакритических знаков, приведение к нижнему регистру, замена пробелов и спецсимволов на дефисы (`ExAmple 1 cOpy!.jpg` ➔ `example-1-copy.jpg`).
  - Автоматическая генерация тега Alt из имени файла при загрузке, если Alt не был указан.
  - Фронтенд Fallback Alt: автоподстановка ключевых слов статьи/товара или заголовка в пустые теги `alt=""` на лету.
- **Изображения в XML Карте Сайта (Image Sitemap XML):**
  - Добавлена поддержка пространства имен `xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"` в `/sitemap.xml` и `/sitemaps.xml`.
  - Автоматическое добавление тегов `<image:image><image:loc>...</image:loc><image:title>...</image:title></image:image>` для записей, страниц и товаров.
- **301 редиректы для мусорных архивов:**
  - Автоматический 301-редирект со страниц авторов (`is_author()`) на главную страницу для защиты от перечисления логинов и дублей.
  - Автоматический 301-редирект с архивов дат (`is_date()`) на главную страницу.
  - Автоматический 301-редирект со страниц вложений (`is_attachment()`) на родительский пост или главную.
- **Верификация вебмастеров (Webmaster Verifications):**
  - Поддержка мета-тегов верификации поисковых систем: Яндекс (`yandex-verification`), Google (`google-site-verification`), Seznam.cz (`seznam-wmt`), Bing (`msvalidate.01`), Pinterest (`p:domain_verify`), Baidu (`baidu-site-verification`), Facebook Domain.
  - Автоматический бесшовный подхват ранее сохраненных кодов верификации из базы данных SEOPress (`seopress_advanced_option_name`).
- **Обновление панели управления (Settings UI):**
  - Локализованная панель настроек на 3 языках (RU, CS, EN) с переключателями новых модулей и полями кодов верификации.

---

## 2026-09__1.37 — 2026-09-21

- **Codebase maintenance & independence**: Removed standalone updater dependency, streamlined standalone micro-plugin architecture, synchronized suite versioning.

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
- Unified localization in vladimir-ai-i18n.php using the all_plugins hook and fallback to English.
- Integrated branding tag (VladiMIR+AI✅) across all language descriptions.

---

## 2026-09__1.18 - 2026-09-19

### Suite Standardization Release

- Adopted standard versioning schema YYYY-MM__<generation>.<build> across all suite modules.
- Standardized branding tag (VladiMIR+AI✅) in Plugin Name.
- Unified update mechanism with GitHub API updater: Update URI: https://vladimir-ai.updates/wp-seo-micro + vladimir-ai-updater.php.
- Standardized metadata requirements: Requires at least: 6.0 and Requires PHP: 7.4.
- Reorganized codebase into clean modular architecture.
