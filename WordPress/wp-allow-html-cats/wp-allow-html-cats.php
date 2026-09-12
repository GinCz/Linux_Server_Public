<?php
/**
 * Plugin Name: Allow HTML in Category & Taxonomy Descriptions (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-allow-html-cats
 * Description: Allows rich HTML formatting (paragraphs, links, images, headings, lists) in category, tag, and WooCommerce taxonomy descriptions without stripping tags.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: wp-allow-html-cats
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_ahc_get_settings() {
    $defaults = array(
        'enable_cats' => 1,
        'enable_tags' => 1,
        'enable_woo'  => 1,
    );
    $saved = get_option( '_vladimir_ahc_settings', array() );
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-ahc-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-allow-html-cats" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Allow HTML in Descriptions (VladiMIR+AI)',
        'Allow HTML in Cats',
        'manage_options',
        'vladimir-ahc-settings',
        'vladimir_ahc_render_settings_page'
    );
} );

function vladimir_ahc_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_ahc_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Allow HTML in Descriptions: Настройки HTML в категориях';
        $txt_subtitle = 'Разрешает использовать полноценное HTML-форматирование в описаниях рубрик и таксономий без обрезания тегов движком WordPress.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_cats     = 'Разрешить HTML в описаниях рубрик записей (category)';
        $txt_tags     = 'Разрешить HTML в описаниях меток записей (post_tag)';
        $txt_woo      = 'Разрешить HTML в категориях и метках товаров WooCommerce (product_cat / product_tag)';
        $txt_save     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Allow HTML in Descriptions: Nastavení HTML v popisech rubrik';
        $txt_subtitle = 'Povoluje formátování HTML v popisech kategorií a taxonomií.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_cats     = 'Povolit HTML v rubrikách příspěvků';
        $txt_tags     = 'Povolit HTML ve štítcích příspěvků';
        $txt_woo      = 'Povolit HTML v kategoriích WooCommerce';
        $txt_save     = 'Uložit nastavení';
    } else {
        $txt_title    = 'Allow HTML in Descriptions: Taxonomy HTML Settings';
        $txt_subtitle = 'Allows safe rich HTML tags in category and WooCommerce taxonomy descriptions.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_cats     = 'Allow HTML in Post Categories';
        $txt_tags     = 'Allow HTML in Post Tags';
        $txt_woo      = 'Allow HTML in WooCommerce Product Categories & Tags';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🏷️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_ahc_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_ahc_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Таксономии</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="enable_cats" value="1" <?php checked( $settings['enable_cats'], 1 ); ?>>
                                <?php echo esc_html( $txt_cats ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_tags" value="1" <?php checked( $settings['enable_tags'], 1 ); ?>>
                                <?php echo esc_html( $txt_tags ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_woo" value="1" <?php checked( $settings['enable_woo'], 1 ); ?>>
                                <?php echo esc_html( $txt_woo ); ?>
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
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-allow-html-cats" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_ahc_settings', function() {
    check_admin_referer( 'vladimir_save_ahc_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'enable_cats' => isset( $_POST['enable_cats'] ) ? 1 : 0,
        'enable_tags' => isset( $_POST['enable_tags'] ) ? 1 : 0,
        'enable_woo'  => isset( $_POST['enable_woo'] ) ? 1 : 0,
    );

    update_option( '_vladimir_ahc_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-ahc-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. HTML ALLOW HOOKS
// ─────────────────────────────────────────────

$ahc_cfg = vladimir_ahc_get_settings();

// Post Categories
if ( ! empty( $ahc_cfg['enable_cats'] ) ) {
    remove_filter( 'pre_term_description', 'wp_filter_kses' );
    remove_filter( 'term_description', 'wp_kses_data' );
}

// Post Tags
if ( ! empty( $ahc_cfg['enable_tags'] ) ) {
    remove_filter( 'pre_term_description', 'wp_filter_kses' );
    remove_filter( 'term_description', 'wp_kses_data' );
}

// WooCommerce Categories
if ( ! empty( $ahc_cfg['enable_woo'] ) ) {
    remove_filter( 'pre_term_description', 'wp_filter_kses' );
    remove_filter( 'term_description', 'wp_kses_data' );
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
            $plugins[ $plugin_key ]['Name']        = 'Allow HTML in Category & Taxonomy Descriptions (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Разрешает безопасные HTML-теги и форматирование в описаниях рубрик, меток и категорий WooCommerce.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Allow HTML in Category & Taxonomy Descriptions (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Povoluje HTML formátování v popisech rubrik, štítků a kategorií WooCommerce.';
        }
    }
    return $plugins;
} );
