# 📜 Регламент Версионирования и Релизов Плагинов WordPress
> **WordPress Ultra-Light Plugins Suite (VladiMIR+AI)**  
> *Репозиторий:* [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) • [GinCz/plugins ↗](https://github.com/GinCz/plugins)  
> *Автор:* **VladiMIR (GinCz) + AI**  
> *Версия регламента:* v2026-09-21

---

## 🚨 ГЛАВНОЕ ПРАВИЛО: ОБЯЗАТЕЛЬНЫЙ ИНКРЕМЕНТ ВЕРСИИ ПРИ ЛЮБОМ ИЗМЕНЕНИИ
Каждый плагин в составе пакета обладает **собственной независимой версией**.

> [!IMPORTANT]
> **При внесении ЛЮБОГО изменения в плагин (правка кода, багфикс, рефакторинг, удаление/добавление файлов, изменение стилей или разметки):**
> 1. **ОБЯЗАТЕЛЬНО** повысить номер версии в заголовке `Version: YYYY-MM__<G>.<BB>` главного PHP-файла плагина (`WordPress/Plugins/<slug>/<slug>.php`).
> 2. **ОБЯЗАТЕЛЬНО** добавить описание изменений в [CHANGELOG.md ↗](CHANGELOG.md) соответствующего плагина под новой версией.

---

## 🔢 Формат версионирования
Версии формируются по единому шаблону:
`YYYY-MM__<Поколение>.<Билд>`

* **`YYYY-MM`** — Текущий год и месяц (например: `2026-09`).
* **`__`** — Двойное подчеркивание (разделитель даты и поколения).
* **`<Поколение>`** — Архитектурное поколение плагина (сейчас `1`).
* **`.<Билд>`** — Монотонно возрастающий номер билда (например: `.37`, `.38`, `.39`...).

**Пример:** `2026-09__1.37`

---

## ⚙️ Автоматический CI/CD Пайплайн Релизов (`.github/workflows/wp-plugins-release.yml`)
При каждом пуше в ветку `main` в директорию `WordPress/Plugins/**` автоматически запускается процесс сборки:

1. **Сравнение версий:** Скрипт считывает версию из заголовка `<slug>.php` и сравнивает её с версией в [updates.json ↗](updates.json).
2. **Условия обработки:**
   * **`Версия в файле > Версии в updates.json`** ➡️ Плагин включается в план релиза (`build/release-plan.json`). Собирается ZIP-архив, создаётся GitHub Release с тегом `wp-<slug>-<version>`, а [updates.json ↗](updates.json) автоматически обновляется и коммитится ботом в репозиторий.
   * **`Версия в файле == Версии в updates.json`** ➡️ Плагин не перевыпускается (изменений нет).
   * **`Версия в файле < Версии в updates.json`** ➡️ **КРИТИЧЕСКАЯ ОШИБКА (`SystemExit`)**. Пайплайн падает, так как понижение версий запрещено!

---

## 📋 Список плагинов в каталоге (13 модулей)
1. [`404-410-301`](./404-410-301/) — `404-410-301.php`
2. [`classic-editor-tinymce`](./classic-editor-tinymce/) — `classic-editor-tinymce.php`
3. [`clean-head-meta`](./clean-head-meta/) — `clean-head-meta.php`
4. [`disable-update-emails`](./disable-update-emails/) — `disable-update-emails.php`
5. [`image-resizer`](./image-resizer/) — `image-resizer.php`
6. [`translit-cyr-lat`](./translit-cyr-lat/) — `translit-cyr-lat.php`
7. [`wp-allow-html-cats`](./wp-allow-html-cats/) — `wp-allow-html-cats.php`
8. [`wp-auto-sku`](./wp-auto-sku/) — `wp-auto-sku.php`
9. [`wp-bulk-delete-clean`](./wp-bulk-delete-clean/) — `wp-bulk-delete-clean.php`
10. [`wp-online-counter`](./wp-online-counter/) — `wp-online-counter.php`
11. [`wp-seo-micro`](./wp-seo-micro/) — `wp-seo-micro.php`
12. [`wp-simple-post-order`](./wp-simple-post-order/) — `wp-simple-post-order.php`
13. [`wp-test-email-micro`](./wp-test-email-micro/) — `wp-test-email-micro.php`
