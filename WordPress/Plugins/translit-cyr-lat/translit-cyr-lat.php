<?php
/**
 * Plugin Name: Cyrillic & European to Latin SEO Transliteration (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/translit-cyr-lat
 * Description: Ultra-fast SEO transliteration of Cyrillic (Russian, Ukrainian) and European (Czech, Slovak, German) characters into clean, URL-friendly Latin slugs. Zero external HTTP requests.
 * Version:     2026-09__1.26
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/translit-cyr-lat
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: translit-cyr-lat
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Shared auto-update client (private GitHub repository, see WordPress/README.md).
// Guarded: a partial copy of the plugin folder must degrade to "no auto-updates",
// not to a fatal error on every page load.
if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

// Shared plugin-list translations (8 languages, see WordPress/README.md).
if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-i18n.php';
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_tcl_get_settings() {
    $defaults = array(
        'enable_translit' => 1,
        'translit_files'  => 1,
        'lowercase'       => 1,
    );
    $saved = get_option( '_vladimir_tcl_settings', array() );
    return wp_parse_args( is_array( $saved ) ? $saved : array(), $defaults );
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function( $links ) {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $settings_label = ( 'ru' === $lang ) ? 'Настройки' : ( ( 'cs' === $lang ) ? 'Nastavení' : 'Settings' );
    $docs_label     = ( 'ru' === $lang ) ? 'Документация ↗' : ( ( 'cs' === $lang ) ? 'Dokumentace ↗' : 'Documentation ↗' );

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-tcl-settings' ) ) . '" style="white-space:nowrap;">' . esc_html( $settings_label ) . '</a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/translit-cyr-lat" target="_blank" style="white-space:nowrap;">' . esc_html( $docs_label ) . '</a>';

    return array_merge( array(
        'settings' => $settings_link,
        'docs'     => $docs_link,
    ), $links );
} );

add_action( 'admin_head-plugins.php', function() {
    static $css_done = false;
    if ( ! $css_done ) {
        $css_done = true;
        echo '<style>.plugins .row-actions { white-space: nowrap !important; }</style>';
    }
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Cyrillic & European Transliteration (VladiMIR+AI✅)',
        'Cyr-to-Lat Translit',
        'manage_options',
        'vladimir-tcl-settings',
        'vladimir_tcl_render_settings_page'
    );
} );

function vladimir_tcl_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_tcl_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Транслитерация Cyr-to-Lat: Настройки ЧПУ';
        $txt_subtitle = 'Мгновенно переводит русские, украинские и чешские буквы в чистый латинский URL (slug) для идеального SEO.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_en       = 'Включить транслитерацию постоянных ссылок (записи, страницы, товары, категории)';
        $txt_files    = 'Транслитерировать имена загружаемых файлов и картинок';
        $txt_lower    = 'Приводить все URL к нижнему регистру (lowercase)';
        $txt_save     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Transliterace Cyr-to-Lat: Nastavení URL';
        $txt_subtitle = 'Okamžitý převod azbuky i české/slovenské diakritiky do čistého tvaru URL pro SEO.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_en       = 'Povolit transliteraci trvalých odkazů';
        $txt_files    = 'Transliterovat názvy nahrávaných souborů';
        $txt_lower    = 'Všechny URL převádět na malá písmena';
        $txt_save     = 'Uložit nastavení';
    } else {
        $txt_title    = 'Cyr-to-Lat Transliteration: SEO Slug Settings';
        $txt_subtitle = 'Converts Cyrillic and European accented characters into clean Latin permalinks.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_en       = 'Enable Transliteration for Permalinks';
        $txt_files    = 'Transliterate Uploaded Filenames';
        $txt_lower    = 'Force Lowercase URLs';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🔤 <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI✅)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_tcl_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_tcl_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Options</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="enable_translit" value="1" <?php checked( $settings['enable_translit'], 1 ); ?>>
                                <?php echo esc_html( $txt_en ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="translit_files" value="1" <?php checked( $settings['translit_files'], 1 ); ?>>
                                <?php echo esc_html( $txt_files ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="lowercase" value="1" <?php checked( $settings['lowercase'], 1 ); ?>>
                                <?php echo esc_html( $txt_lower ); ?>
                            </label>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/translit-cyr-lat" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_tcl_settings', function() {
    check_admin_referer( 'vladimir_save_tcl_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'enable_translit' => isset( $_POST['enable_translit'] ) ? 1 : 0,
        'translit_files'  => isset( $_POST['translit_files'] ) ? 1 : 0,
        'lowercase'       => isset( $_POST['lowercase'] ) ? 1 : 0,
    );

    update_option( '_vladimir_tcl_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-tcl-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. TRANSLITERATION TABLE & FILTERS
// ─────────────────────────────────────────────

function vladimir_tcl_convert( $title ) {
    $table = array(
        'А' => 'a', 'Б' => 'b', 'В' => 'v', 'Г' => 'g', 'Д' => 'd', 'Е' => 'e', 'Ё' => 'e', 'Ж' => 'zh',
        'З' => 'z', 'И' => 'i', 'Й' => 'y', 'К' => 'k', 'Л' => 'l', 'М' => 'm', 'Н' => 'n', 'О' => 'o',
        'П' => 'p', 'Р' => 'r', 'С' => 's', 'Т' => 't', 'У' => 'u', 'Ф' => 'f', 'Х' => 'h', 'Ц' => 'ts',
        'Ч' => 'ch', 'Ш' => 'sh', 'Щ' => 'sch', 'Ъ' => '', 'Ы' => 'y', 'Ь' => '', 'Э' => 'e', 'Ю' => 'yu',
        'Я' => 'ya',
        'а' => 'a', 'б' => 'b', 'в' => 'v', 'г' => 'g', 'д' => 'd', 'е' => 'e', 'ё' => 'e', 'ж' => 'zh',
        'з' => 'z', 'и' => 'i', 'й' => 'y', 'к' => 'k', 'л' => 'l', 'м' => 'm', 'н' => 'n', 'о' => 'o',
        'п' => 'p', 'р' => 'r', 'с' => 's', 'т' => 't', 'у' => 'u', 'ф' => 'f', 'х' => 'h', 'ц' => 'ts',
        'ч' => 'ch', 'ш' => 'sh', 'щ' => 'sch', 'ъ' => '', 'ы' => 'y', 'ь' => '', 'э' => 'e', 'ю' => 'yu',
        'я' => 'ya',
        'Є' => 'ye', 'є' => 'ye', 'І' => 'i', 'і' => 'i', 'Ї' => 'yi', 'ї' => 'yi', 'Ґ' => 'g', 'ґ' => 'g',
        // Czech & Slovak
        'á' => 'a', 'č' => 'c', 'ď' => 'd', 'é' => 'e', 'ě' => 'e', 'í' => 'i', 'ň' => 'n', 'ó' => 'o',
        'ř' => 'r', 'š' => 's', 'ť' => 't', 'ú' => 'u', 'ů' => 'u', 'ý' => 'y', 'ž' => 'z',
        'Á' => 'a', 'Č' => 'c', 'Ď' => 'd', 'É' => 'e', 'Ě' => 'e', 'Í' => 'i', 'Ň' => 'n', 'Ó' => 'o',
        'Ř' => 'r', 'Š' => 's', 'Ť' => 't', 'Ú' => 'u', 'Ů' => 'u', 'Ý' => 'y', 'Ž' => 'z',
        // German - listed in the plugin description since the first release but missing
        // from the table, so umlauts fell through to WordPress and were dropped entirely.
        'ä' => 'ae', 'ö' => 'oe', 'ü' => 'ue', 'ß' => 'ss',
        'Ä' => 'ae', 'Ö' => 'oe', 'Ü' => 'ue',
        // Slovak and Polish letters that share these keyboards.
        'ĺ' => 'l', 'ľ' => 'l', 'ŕ' => 'r', 'ô' => 'o',
        'Ĺ' => 'l', 'Ľ' => 'l', 'Ŕ' => 'r', 'Ô' => 'o',
        'ą' => 'a', 'ć' => 'c', 'ę' => 'e', 'ł' => 'l', 'ń' => 'n', 'ś' => 's', 'ź' => 'z', 'ż' => 'z',
        'Ą' => 'a', 'Ć' => 'c', 'Ę' => 'e', 'Ł' => 'l', 'Ń' => 'n', 'Ś' => 's', 'Ź' => 'z', 'Ż' => 'z',
    );

    $converted = strtr( $title, $table );

    // The lowercase setting was present in the UI from the start but never applied.
    $settings = vladimir_tcl_get_settings();
    if ( ! empty( $settings['lowercase'] ) ) {
        $converted = function_exists( 'mb_strtolower' ) ? mb_strtolower( $converted, 'UTF-8' ) : strtolower( $converted );
    }

    return $converted;
}

add_filter( 'sanitize_title', function( $title, $raw_title = '', $context = 'query' ) {
    $settings = vladimir_tcl_get_settings();
    if ( empty( $settings['enable_translit'] ) ) {
        return $title;
    }

    $input = ( ! empty( $raw_title ) && 'save' === $context ) ? $raw_title : $title;
    return vladimir_tcl_convert( $input );
}, 0, 3 );

add_filter( 'sanitize_file_name', function( $filename ) {
    $settings = vladimir_tcl_get_settings();
    if ( empty( $settings['translit_files'] ) ) {
        return $filename;
    }
    return vladimir_tcl_convert( $filename );
}, 0 );

