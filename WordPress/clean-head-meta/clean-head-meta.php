<?php
/**
 * Plugin Name: Clean Head Meta & Anti-Fingerprint (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/clean-head-meta
 * Description: Cleans WordPress <head> clutter, removes generator version tags, strips obsolete XML-RPC pingback links and emoji scripts, and adds clean author and designer meta tags (VladiMIR).
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: clean-head-meta
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_chm_get_settings() {
    $defaults = array(
        'remove_generator'  => 1,
        'disable_xmlrpc'    => 1,
        'remove_head_links' => 1,
        'disable_emojis'    => 1,
        'add_author_meta'   => 1,
        'author_name'       => 'VladiMIR (GinCz)',
    );
    $saved = get_option( '_vladimir_chm_settings', array() );
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-chm-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/clean-head-meta" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Clean Head Meta (VladiMIR+AI)',
        'Clean Head Meta',
        'manage_options',
        'vladimir-chm-settings',
        'vladimir_chm_render_settings_page'
    );
} );

function vladimir_chm_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_chm_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Clean Head Meta: Очистка заголовка и скрытие версии WP';
        $txt_subtitle = 'Удаляет лишние служебные теги WordPress, скрывает номер версии системы и ускоряет загрузку.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_gen      = 'Удалить тег генератора и скрыть номер версии WordPress';
        $txt_xml      = 'Отключить пинги XML-RPC и закрыть pings_open';
        $txt_links    = 'Удалить ссылки RSD, WLW Manifest, короткие ссылки shortlink и oEmbed discovery';
        $txt_emo      = 'Отключить загрузку emoji скриптов и стилей';
        $txt_aut      = 'Добавлять чистые авторские мета-теги (author / designer)';
        $txt_aut_val  = 'Имя автора в мета-тегах';
        $txt_save     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Clean Head Meta: Vyčištění hlavičky a skrytí verze WP';
        $txt_subtitle = 'Odstraní zbytečné meta tagy, skryje verzi WordPress a zrychlí načítání.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_gen      = 'Skrýt verzi WordPressu a odstranit wp_generator';
        $txt_xml      = 'Vypnout XML-RPC pingbacky';
        $txt_links    = 'Odstranit RSD, WLW Manifest, shortlink a oEmbed odkazy';
        $txt_emo      = 'Vypnout skripty a styly emoji';
        $txt_aut      = 'Přidat autorské meta tagy';
        $txt_aut_val  = 'Jméno autora';
        $txt_save     = 'Uložit nastavení';
    } else {
        $txt_title    = 'Clean Head Meta: Head Optimization Settings';
        $txt_subtitle = 'Cleans WordPress header bloat, removes version fingerprinting and emoji scripts.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_gen      = 'Remove generator meta tag and WordPress version';
        $txt_xml      = 'Disable XML-RPC pingbacks';
        $txt_links    = 'Remove RSD, WLW Manifest, shortlinks and oEmbed discovery links';
        $txt_emo      = 'Disable WordPress emoji scripts and styles';
        $txt_aut      = 'Add author and designer meta tags';
        $txt_aut_val  = 'Author Name in Meta Tags';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🧹 <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_chm_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_chm_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Очистка & Безопасность</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="remove_generator" value="1" <?php checked( $settings['remove_generator'], 1 ); ?>>
                                <?php echo esc_html( $txt_gen ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="disable_xmlrpc" value="1" <?php checked( $settings['disable_xmlrpc'], 1 ); ?>>
                                <?php echo esc_html( $txt_xml ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="remove_head_links" value="1" <?php checked( $settings['remove_head_links'], 1 ); ?>>
                                <?php echo esc_html( $txt_links ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="disable_emojis" value="1" <?php checked( $settings['disable_emojis'], 1 ); ?>>
                                <?php echo esc_html( $txt_emo ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="add_author_meta" value="1" <?php checked( $settings['add_author_meta'], 1 ); ?>>
                                <?php echo esc_html( $txt_aut ); ?>
                            </label>
                        </fieldset>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="author_name"><strong><?php echo esc_html( $txt_aut_val ); ?></strong></label></th>
                    <td>
                        <input type="text" name="author_name" id="author_name" value="<?php echo esc_attr( $settings['author_name'] ); ?>" class="regular-text">
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/clean-head-meta" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_chm_settings', function() {
    check_admin_referer( 'vladimir_save_chm_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'remove_generator'  => isset( $_POST['remove_generator'] ) ? 1 : 0,
        'disable_xmlrpc'    => isset( $_POST['disable_xmlrpc'] ) ? 1 : 0,
        'remove_head_links' => isset( $_POST['remove_head_links'] ) ? 1 : 0,
        'disable_emojis'    => isset( $_POST['disable_emojis'] ) ? 1 : 0,
        'add_author_meta'   => isset( $_POST['add_author_meta'] ) ? 1 : 0,
        'author_name'       => sanitize_text_field( (string) ( $_POST['author_name'] ?? 'VladiMIR (GinCz)' ) ),
    );

    update_option( '_vladimir_chm_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-chm-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. CLEANUP EXECUTION HOOKS
// ─────────────────────────────────────────────

$chm_cfg = vladimir_chm_get_settings();

if ( ! empty( $chm_cfg['remove_generator'] ) ) {
    remove_action( 'wp_head', 'wp_generator' );
    add_filter( 'the_generator', '__return_empty_string' );
}

if ( ! empty( $chm_cfg['disable_xmlrpc'] ) ) {
    add_filter( 'pings_open', '__return_false', 9999 );
}

if ( ! empty( $chm_cfg['remove_head_links'] ) ) {
    remove_action( 'wp_head', 'rsd_link' );
    remove_action( 'wp_head', 'wlwmanifest_link' );
    remove_action( 'wp_head', 'wp_shortlink_wp_head' );
    remove_action( 'wp_head', 'rest_output_link_wp_head' );
    remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
    remove_action( 'template_redirect', 'rest_output_link_header', 11 );
}

if ( ! empty( $chm_cfg['disable_emojis'] ) ) {
    add_action( 'init', function() {
        remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
        remove_action( 'admin_print_scripts', 'print_emoji_detection_script' );
        remove_action( 'wp_print_styles', 'print_emoji_styles' );
        remove_action( 'admin_print_styles', 'print_emoji_styles' );
        remove_filter( 'the_content_feed', 'wp_staticize_emoji' );
        remove_filter( 'comment_text_rss', 'wp_staticize_emoji' );
        remove_filter( 'wp_mail', 'wp_staticize_emoji_for_email' );
        add_filter( 'tiny_mce_plugins', function( $plugins ) {
            return is_array( $plugins ) ? array_diff( $plugins, array( 'wpemoji' ) ) : array();
        } );
    } );
}

if ( ! empty( $chm_cfg['add_author_meta'] ) ) {
    add_action( 'wp_head', function() {
        $cfg  = vladimir_chm_get_settings();
        $name = esc_attr( $cfg['author_name'] ?: 'VladiMIR (GinCz)' );
        echo "<meta name=\"author\" content=\"{$name}\">\n";
        echo "<meta name=\"designer\" content=\"{$name}\">\n";
    }, 1 );
}

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Clean Head Meta & Anti-Fingerprint (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Очистка мусора в <head>, скрытие номера версии WordPress, удаление emoji скриптов и устаревших XML-RPC пингов.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Clean Head Meta & Anti-Fingerprint (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Vyčištění hlavičky <head>, skrytí verze WordPress a vypnutí emoji skriptů.';
        }
    }
    return $plugins;
} );
