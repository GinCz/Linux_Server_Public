<?php
/**
 * Plugin Name: Translit Cyr & Czech to Lat SEO (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/translit-cyr-lat
 * Description: High-performance SEO transliteration plugin converting Cyrillic (Russian, Ukrainian) and Czech/Slovak diacritic characters into clean Latin URL slugs. Zero database queries.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: translit-cyr-lat
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_translit_get_settings() {
     = array(
        'translit_ru'     => 1,
        'translit_uk'     => 1,
        'translit_cs'     => 1,
        'force_lowercase' => 1,
    );
     = get_option( '_vladimir_translit_settings', array() );
    return wp_parse_args( is_array(  ) ?  : array(),  );
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function(  ) {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

     = ( 'ru' ===  ) ? 'Настройки' : ( ( 'cs' ===  ) ? 'Nastavení' : 'Settings' );
         = ( 'ru' ===  ) ? 'Документация ↗' : ( ( 'cs' ===  ) ? 'Dokumentace ↗' : 'Documentation ↗' );

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-translit-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/translit-cyr-lat" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Translit SEO (VladiMIR+AI)',
        'Транслитерация ЧПУ',
        'manage_options',
        'vladimir-translit-settings',
        'vladimir_translit_render_settings_page'
    );
} );

function vladimir_translit_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_translit_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'Транслитерация ЧПУ (Кириллица и Чешские буквы): Настройки';
                = 'Преобразование заголовков записей, страниц и рубрик в чистую латиницу для красивых и правильных SEO URL.';
               = 'Настройки успешно сохранены!';
                  = 'Транслитерация русской кириллицы (а-я -> a-z)';
             = 'Заменяет буквы русского алфавита на транслит латиницей.';
                  = 'Транслитерация украинских букв (є, і, ї, ґ)';
             = 'Включает корректную замену уникальных символов украинского языка.';
                  = 'Транслитерация чешских и словацких диакритических знаков';
             = 'Преобразует буквы с гачеками и чарками (á, č, ď, é, ě, í, ň, ó, ř, š, ť, ú, ů, ý, ž, ä, ô) в чистые базовые латинские буквы.';
               = 'Принудительно переводить слаги в нижний регистр';
          = 'Гарантирует отсутствие заглавных букв в ссылках URL.';
             = 'Интерактивная проверка транслитерации';
           = 'Введите любой заголовок для мгновенной проверки результата:';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'Transliterace do latinky SEO: Nastavení';
                = 'Převod azbuky a českých/slovenských znaků s diakritikou na čisté tvary trvalých odkazů (slug).';
               = 'Nastavení bylo úspěšně uloženo!';
                  = 'Transliterace ruské azbuky';
             = 'Převádí znaky azbuky na latinku.';
                  = 'Transliterace ukrajinských znaků (є, і, ї, ґ)';
             = 'Zahrnuje převod ukrajinských písmen.';
                  = 'Odstranění české a slovenské diakritiky';
             = 'Odstraňuje háčky a čárky (á, č, ď, é, ě, í, ň, ó, ř, š, ť, ú, ů, ý, ž) z URL.';
               = 'Vynutit malá písmena v URL';
          = 'Zajistí čistou adresu URL bez velkých písmen.';
             = 'Rychlý test převodu';
           = 'Zadejte libovolný text pro okamžitý náhled:';
            = 'Uložit nastavení';
    } else {
               = 'Translit Cyr & Czech to Lat SEO: Settings';
                = 'Converts Cyrillic and Czech/Slovak diacritics into clean, readable Latin URL slugs.';
               = 'Settings successfully saved!';
                  = 'Transliterate Russian Cyrillic';
             = 'Replaces Russian letters with phonetic Latin equivalents.';
                  = 'Transliterate Ukrainian Letters (є, і, ї, ґ)';
             = 'Replaces Ukrainian regional characters.';
                  = 'Transliterate Czech & Slovak Diacritics';
             = 'Strips accents and carons (á, č, ď, é, ě, í, ň, ó, ř, š, ť, ú, ů, ý, ž).';
               = 'Force Lowercase Slugs';
          = 'Ensures generated URL slugs contain only lowercase characters.';
             = 'Live Transliteration Tester';
           = 'Type any title to inspect generated slug:';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🌐 <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_translit_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_translit_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="translit_ru" value="1" <?php checked( ['translit_ru'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="translit_uk" value="1" <?php checked( ['translit_uk'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="translit_cs" value="1" <?php checked( ['translit_cs'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="force_lowercase" value="1" <?php checked( ['force_lowercase'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
            </table>

            <h3 style="margin-top:25px;border-top:1px solid #e2e8f0;padding-top:15px;"><?php echo esc_html(  ); ?></h3>
            <p class="description"><?php echo esc_html(  ); ?></p>
            <div style="margin:10px 0 20px;">
                <input type="text" id="translit_test_input" placeholder="Например: Čištění motoru v Praze & Ремонт АКПП" class="large-text" oninput="runTranslitTest(this.value)">
                <div style="margin-top:10px;padding:10px 14px;background:#f8fafc;border:1px solid #cbd5e1;border-radius:6px;font-family:monospace;font-size:14px;">
                    <strong>Slug:</strong> <span id="translit_test_result" style="color:#0284c7;">cisteni-motoru-v-praze-remont-akpp</span>
                </div>
            </div>

            <script>
            function runTranslitTest(str) {
                var matrix = {
                    'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'zh','з':'z','и':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r','с':'s','т':'t','у':'u','ф':'f','х':'kh','ц':'ts','ч':'ch','ш':'sh','щ':'shch','ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya','є':'ye','і':'i','ї':'yi','ґ':'g',
                    'á':'a','č':'c','ď':'d','é':'e','ě':'e','í':'i','ň':'n','ó':'o','ř':'r','š':'s','ť':'t','ú':'u','ů':'u','ý':'y','ž':'z','ä':'a','ô':'o','ĺ':'l','ŕ':'r'
                };
                var lower = str.toLowerCase();
                var res = '';
                for (var i = 0; i < lower.length; i++) {
                    var ch = lower[i];
                    res += matrix[ch] !== undefined ? matrix[ch] : ch;
                }
                res = res.replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
                document.getElementById('translit_test_result').textContent = res || '(empty)';
            }
            </script>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/translit-cyr-lat" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_translit_settings', function() {
    check_admin_referer( 'vladimir_save_translit_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'translit_ru'     => isset( ['translit_ru'] ) ? 1 : 0,
        'translit_uk'     => isset( ['translit_uk'] ) ? 1 : 0,
        'translit_cs'     => isset( ['translit_cs'] ) ? 1 : 0,
        'force_lowercase' => isset( ['force_lowercase'] ) ? 1 : 0,
    );

    update_option( '_vladimir_translit_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-translit-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. TRANSLITERATION ENGINE
// ─────────────────────────────────────────────

add_filter( 'sanitize_title', function( ,  = '',  = 'query' ) {
    if ( 'save' !==  ) {
        return ;
    }

     = vladimir_translit_get_settings();
       =  ?  : ;
       = array();

    // Russian
    if ( ! empty( ['translit_ru'] ) ) {
         += array(
            'а' => 'a',   'б' => 'b',   'в' => 'v',   'г' => 'g',   'д' => 'd',
            'е' => 'e',   'ё' => 'yo',  'ж' => 'zh',  'з' => 'z',   'и' => 'i',
            'й' => 'y',   'к' => 'k',   'л' => 'l',   'м' => 'm',   'н' => 'n',
            'о' => 'o',   'п' => 'p',   'р' => 'r',   'с' => 's',   'т' => 't',
            'у' => 'u',   'ф' => 'f',   'х' => 'kh',  'ц' => 'ts',  'ч' => 'ch',
            'ш' => 'sh',  'щ' => 'shch','ъ' => '',   'ы' => 'y',   'ь' => '',
            'э' => 'e',   'ю' => 'yu',  'я' => 'ya',
            'А' => 'A',   'Б' => 'B',   'В' => 'V',   'Г' => 'G',   'Д' => 'D',
            'Е' => 'E',   'Ё' => 'Yo',  'Ж' => 'Zh',  'З' => 'Z',   'И' => 'I',
            'Й' => 'Y',   'К' => 'K',   'Л' => 'L',   'М' => 'M',   'Н' => 'N',
            'О' => 'O',   'П' => 'P',   'Р' => 'R',   'С' => 'S',   'Т' => 'T',
            'У' => 'U',   'Ф' => 'F',   'Х' => 'Kh',  'Ц' => 'Ts',  'Ч' => 'Ch',
            'Ш' => 'Sh',  'Щ' => 'Shch','Ъ' => '',   'Ы' => 'Y',   'Ь' => '',
            'Э' => 'E',   'Ю' => 'Yu',  'Я' => 'Ya',
        );
    }

    // Ukrainian
    if ( ! empty( ['translit_uk'] ) ) {
         += array(
            'є' => 'ye',  'і' => 'i',   'ї' => 'yi',  'ґ' => 'g',
            'Є' => 'Ye',  'І' => 'I',   'Ї' => 'Yi',  'Ґ' => 'G',
        );
    }

    // Czech / Slovak
    if ( ! empty( ['translit_cs'] ) ) {
         += array(
            'á' => 'a',   'č' => 'c',   'ď' => 'd',   'é' => 'e',   'ě' => 'e',
            'í' => 'i',   'ň' => 'n',   'ó' => 'o',   'ř' => 'r',   'š' => 's',
            'ť' => 't',   'ú' => 'u',   'ů' => 'u',   'ý' => 'y',   'ž' => 'z',
            'ä' => 'a',   'ô' => 'o',   'ĺ' => 'l',   'ŕ' => 'r',
            'Á' => 'A',   'Č' => 'C',   'Ď' => 'D',   'É' => 'E',   'Ě' => 'E',
            'Í' => 'I',   'Ň' => 'N',   'Ó' => 'O',   'Ř' => 'R',   'Š' => 'S',
            'Ť' => 'T',   'Ú' => 'U',   'Ů' => 'U',   'Ý' => 'Y',   'Ž' => 'Z',
            'Ä' => 'A',   'Ô' => 'O',   'Ĺ' => 'L',   'Ŕ' => 'R',
        );
    }

    if ( ! empty(  ) ) {
         = strtr( ,  );
    }

     = remove_accents(  );

    if ( ! empty( ['force_lowercase'] ) ) {
         = strtolower(  );
    }

    return ;
}, 9, 3 );

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'Транслитерация Кириллицы и Чешских букв в Латиницу SEO (VladiMIR+AI)';
            [  ]['Description'] = 'Мгновенное преобразование русских, украинских и чешских букв с диакритикой в чистую латиницу для понятных URL (ЧПУ). Включает панель настроек на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'Transliterace azbuky a češtiny do latinky SEO (VladiMIR+AI)';
            [  ]['Description'] = 'Rychlý SEO plugin pro převod azbuky a českých/slovenských znaků s diakritikou na čisté tvary URL s přehledným nastavením na jedné stránce.';
        }
    }
    return ;
} );

