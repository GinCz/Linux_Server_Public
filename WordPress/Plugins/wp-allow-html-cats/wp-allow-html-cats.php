<?php
/**
 * Plugin Name: Allow HTML in Category & Taxonomy Descriptions (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-allow-html-cats
 * Description: Allows rich HTML formatting (paragraphs, links, images, headings, lists) in category, tag, and WooCommerce taxonomy descriptions without stripping tags.
 * Version:     2026-09__1.24
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-allow-html-cats
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-allow-html-cats
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-ahc-settings' ) ) . '" style="white-space:nowrap;">' . esc_html( $settings_label ) . '</a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-allow-html-cats" target="_blank" style="white-space:nowrap;">' . esc_html( $docs_label ) . '</a>';

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
        'Allow HTML in Descriptions (VladiMIR+AI✅)',
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
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI✅)</span>
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
                    <th scope="row"><strong>Taxonomies</strong></th>
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
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-allow-html-cats" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
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

/**
 * Taxonomies the three settings map to.
 *
 * @return string[]
 */
function vladimir_ahc_active_taxonomies() {
    $settings   = vladimir_ahc_get_settings();
    $taxonomies = array();

    if ( ! empty( $settings['enable_cats'] ) ) {
        $taxonomies[] = 'category';
    }
    if ( ! empty( $settings['enable_tags'] ) ) {
        $taxonomies[] = 'post_tag';
    }
    if ( ! empty( $settings['enable_woo'] ) ) {
        $taxonomies[] = 'product_cat';
        $taxonomies[] = 'product_tag';
    }

    return $taxonomies;
}

/**
 * Which taxonomy is the current term-description write for?
 * On save WordPress has the taxonomy in $_POST; on the term-edit screen it is in $_GET.
 *
 * @return string Empty when it cannot be determined.
 */
function vladimir_ahc_current_taxonomy() {
    if ( isset( $_POST['taxonomy'] ) ) {
        return sanitize_key( wp_unslash( (string) $_POST['taxonomy'] ) );
    }
    if ( isset( $_GET['taxonomy'] ) ) {
        return sanitize_key( wp_unslash( (string) $_GET['taxonomy'] ) );
    }

    $screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;

    return ( $screen && ! empty( $screen->taxonomy ) ) ? (string) $screen->taxonomy : '';
}

// Before 2026-09__1.18 all three checkboxes ran the same two global remove_filter()
// calls: ticking any one of them unfiltered EVERY taxonomy, and unticking one could
// not put the filter back. The per-taxonomy handlers below replace that.
remove_filter( 'pre_term_description', 'wp_filter_kses' );
remove_filter( 'term_description', 'wp_kses_data' );

/**
 * Saving: allow post-grade HTML for the enabled taxonomies, keep core behaviour elsewhere.
 *
 * wp_kses_post() is used deliberately instead of storing raw input: it keeps paragraphs,
 * links, images, headings and lists while still stripping <script>/<iframe>/on* handlers.
 *
 * @param string $description Incoming description.
 * @return string
 */
function vladimir_ahc_pre_term_description( $description ) {
    $taxonomy = vladimir_ahc_current_taxonomy();
    $active   = vladimir_ahc_active_taxonomies();

    if ( '' !== $taxonomy && ! in_array( $taxonomy, $active, true ) ) {
        return wp_filter_kses( $description );
    }

    if ( '' === $taxonomy && empty( $active ) ) {
        return wp_filter_kses( $description );
    }

    return current_user_can( 'unfiltered_html' ) ? $description : wp_kses_post( $description );
}
add_filter( 'pre_term_description', 'vladimir_ahc_pre_term_description' );

// Output stays unfiltered: wp_kses_data was already removed above, so stored markup
// reaches the template as saved. Sanitising happens once, on write, not on every render.

// Quick-edit and the term-edit screen post through description_save_pre as well.
add_filter( 'description_save_pre', 'vladimir_ahc_pre_term_description' );

