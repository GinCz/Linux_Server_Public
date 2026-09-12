# Flatsome — Отключение лицензии (патч темы)
> Rooted by VladiMIR + AI | v.2026.07.08 | github.com/GinCz

---

## Суть

Тема Flatsome при каждом запросе WordPress проверяет лицензию через внешний сервер `api.uxthemes.com`. Это замедляет сайт и показывает нотисы в wp-admin если лицензия не активна.

**Решение:** заменить один файл внутри темы на заглушку. Никаких mu-plugins, никаких фильтров — просто класс-пустышка с той же сигнатурой.

> ⚠️ **mu-plugin — НЕПРАВИЛЬНЫЙ способ.** mu-plugin грузится раньше темы и плагинов, стабы классов конфликтуют с настоящим WooCommerce и вызывают HTTP 500 на всех сайтах. Только патч внутри темы!

---

## WooCommerce — ничего делать не нужно

Тема Flatsome везде использует `is_woocommerce_activated()` которая проверяет `class_exists('woocommerce')`. Если WC не установлен — весь WC-код в теме автоматически пропускается. Дополнительных патчей не требуется.

---

## Файл для замены

```
flatsome/inc/classes/class-flatsome-wupdates-registration.php
```

Этот файл содержит класс `Flatsome_WUpdates_Registration` который:
- делает HTTP запросы к `api.uxthemes.com` и `wupdates.com`
- вешает cron `flatsome_scheduled_registration`
- показывает нотисы в wp-admin о необходимости лицензии

---

## Содержимое заглушки (заменить файл целиком)

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

## Способ 1 — Патч в архиве на Windows (для новых установок)

Архив темы: `flatsome-3.18.1__Lic_VladiMIR.zip`

1. Открыть архив в **TotalCommander** (F3 или двойной клик)
2. Зайти в папку `flatsome/inc/classes/`
3. Найти `class-flatsome-wupdates-registration.php`
4. Вытащить файл на рабочий стол (F5 или drag)
5. Заменить содержимое файла на заглушку выше
6. Затащить файл обратно в архив с заменой (drag → подтвердить замену)

После этого все новые установки темы из архива сразу идут без лицензии.

---

## Способ 2 — Патч на сервере (для существующих сайтов)

Запустить на нужном сервере:

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

# Проверка синтаксиса
php -l /tmp/patch.php && echo "Syntax OK"

# Применить на все сайты с темой flatsome
for f in $(find /var/www -name "class-flatsome-wupdates-registration.php" -path "*/themes/flatsome/*" 2>/dev/null | sort); do
    cp /tmp/patch.php "$f"
    domain=$(echo "$f" | grep -oP '/www/\K[^/]+')
    echo "  [OK] $domain"
done

echo "Total: $(find /var/www -name 'class-flatsome-wupdates-registration.php' -path '*/themes/flatsome/*' | wc -l)"
rm -f /tmp/patch.php
echo "DONE"
```

---

## Проверка что патч работает

```bash
# На сервере — файл не должен содержать упоминаний wupdates.com или api.uxthemes.com
grep -i "wupdates\|uxthemes\|api\." \
  /var/www/ЮЗЕР/data/www/ДОМЕН/wp-content/themes/flatsome/inc/classes/class-flatsome-wupdates-registration.php
# Вывод должен быть пустым
```

---

## Что происходит после патча

| Функция | Оригинал | После патча |
|---|---|---|
| `is_registered()` | проверяет БД | всегда `true` |
| `is_verified()` | всегда `true` | всегда `true` |
| `get_code()` | читает из БД | фейк UUID |
| `register()` | HTTP → api.uxthemes.com | `['status'=>'ok']` |
| `get_latest_version()` | HTTP + cron | `false` |
| `migrate_registration()` | HTTP → /v1/license/ | пустая функция |
| `__construct()` | вешает cron hook | ничего не вешает |

**Результат:** нулевые внешние соединения, никаких нотисов в wp-admin, автообновления темы отключены.

---

## История применения

| Дата | Сервер | Сайтов | Способ |
|---|---|---|---|
| 2026-07-08 | 222-DE-NetCup (152.53.182.222) | 43 | Скрипт на сервере |
| 2026-07-08 | 109-RU-FirstVDS (212.109.223.109) | 22 | Скрипт на сервере |

### Сайты на 109-RU (22 шт.)

| Домен | Пользователь |
|---|---|
| comfort-eng.ru | alex_zas |
| ne-son.ru | alex_zas |
| stassinhouse.ru | anastasia_bul |
| study-italy.eu | anatoly_solodilin |
| andrey-maiorov.ru | andrey-maiorov |
| 4ton-96.ru | foton |
| ver7.ru | foton |
| geodesia-ekb.ru | geodesia |
| news-port.ru | gincz |
| prodvig-saita.ru | gincz |
| mtek-expert.ru | kirill_mtek |
| tri-sure.ru | kirill-tri-sure |
| natal-karta.ru | natal-karta |
| novorr-art.ru | novorr |
| shapkioptom.ru | palantins |
| stanok-ural.ru | stanok |
| stomatolog-belchikov.ru | stomat-bel |
| tatra-ural.ru | tatra |
| ugfp.ru | ugfp |
| nail-space-ekb.ru | valeriia |
| lvo-endo.ru | vlad_lazarev |
| stuba-dom.ru | vobs |

---

_Актуально для Flatsome 3.18.1 | VladiMIR + AI_
