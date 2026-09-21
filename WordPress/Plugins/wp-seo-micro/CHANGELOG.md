# CHANGELOG - WP SEO Micro

Versioning format: YYYY-MM__<generation>.<build> (see [../../README.md](../../README.md)).
Monotonically increasing version: each update must strictly increment the build number.

---

## 2026-09__1.39 — 2026-09-21

### 🎯 Честный HTTP 404 для мусорных архивов и полная автономность

- **Честный HTTP 404 вместо прямого 301 на главную (Anti-Soft 404):**
  - Архивы авторов (`is_author()`), архивы дат (`is_date()`) и страницы вложений без родителя теперь отдают честный статус `404 Not Found` (`$wp_query->set_404()`, `status_header(404)`).
  - **Преимущество для SEO:** Поисковики (Google, Яндекс) моментально удаляют мусорные страницы из индекса без штрафов и предупреждений о "Soft 404" (ложных 404 при нерелевантных 301 редиректах на главную).
  - **Для живых посетителей:** Если на сайте активен фирменный плагин `404-410-301`, он красиво подхватывает 404-страницу и плавно перенаправляет пользователя на главную с таймером обратного отсчета.
- **Полная автономность (Zero SEOPress Dependencies):**
  - Удален автоимпорт и фоновые обращения к глобальным опциям SEOPress (`seopress_advanced_option_name`, `seopress_titles_option_name`).
  - Все настройки сохраняются и считываются строго локально через `_vladimir_seo_settings` без лишних запросов к `wp_options`.
- **Комплексная очистка исходного кода и ускорение (Head & HTTP Headers Cleaner):**
  - Удаление Emoji, `wp_generator`, `rsd_link`, `wlwmanifest_link`, `shortlink`, `oEmbed`, класса `hentry`, `?replytocom`, `X-Pingback` и `X-Powered-By`.
- **Автоматизированное SEO для изображений (Automated Image SEO):**
  - Санитизация имен файлов при загрузке (транслитерация, UTF-8 slug) + авто-Alt из имени файла и fallback ключевых слов на фронтенде.
- **Изображения в XML Карте Сайта:**
  - Поддержка `<image:image>` в `/sitemap.xml` и `/sitemaps.xml`.
- **Верификация вебмастеров:**
  - Мета-теги для Яндекс, Google, Seznam.cz, Bing, Pinterest, Baidu, Facebook.

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
