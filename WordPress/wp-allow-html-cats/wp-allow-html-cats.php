<?php
/**
 * Plugin Name: WP Allow Safe HTML in Categories (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-allow-html-cats
 * Description: Allows safe post-style HTML in taxonomy descriptions without disabling WordPress XSS filtering.
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

function vladimir_allow_html_get_settings() {
     = array(
        'allow_categories'   => 1,
        'allow_tags'         => 1,
        'allow_product_cats' => 1,
        'allow_product_tags' => 1,
        'allow_all_tax'      => 1,
    );
     = get_option( '_vladimir_allow_html_settings', array() );
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

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-allow-html-cats-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-allow-html-cats" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Allow HTML in Cats (VladiMIR+AI)',
        'HTML в рубриках',
        'manage_options',
        'vladimir-allow-html-cats-settings',
        'vladimir_allow_html_render_settings_page'
    );
} );

function vladimir_allow_html_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_allow_html_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'Разрешить безопасный HTML в рубриках: Настройки';
                = 'Позволяет использовать ссылки, списки, изображения и стили в описаниях таксономий с защитой от XSS.';
               = 'Настройки успешно сохранены!';
                = 'Стандартные рубрики записей (category)';
                = 'Метки записей (post_tag)';
           = 'Категории товаров WooCommerce (product_cat)';
           = 'Метки товаров WooCommerce (product_tag)';
                 = 'Применять для всех остальных пользовательских таксономий';
           = 'Разрешенные безопасные теги (wp_kses post)';
           = 'Разрешены: &lt;a&gt;, &lt;p&gt;, &lt;strong&gt;, &lt;b&gt;, &lt;em&gt;, &lt;ul&gt;, &lt;ol&gt;, &lt;li&gt;, &lt;h2&gt;-&lt;h5&gt;, &lt;img&gt;, &lt;blockquote&gt;, &lt;table&gt;, &lt;span style=""&gt;. Скрипты &lt;script&gt; и опасные события вырезаются.';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'Povolit bezpečné HTML v kategoriích: Nastavení';
                = 'Umožňuje používat formátování, odkazy a obrázky v popisech kategorií s ochranou proti XSS.';
               = 'Nastavení bylo úspěšně uloženo!';
                = 'Standardní rubriky příspěvků (category)';
                = 'Štítky příspěvků (post_tag)';
           = 'Kategorie produktů WooCommerce (product_cat)';
           = 'Štítky produktů WooCommerce (product_tag)';
                 = 'Povolit pro všechny ostatní taxonomie';
           = 'Povolené bezpečné značky (wp_kses post)';
           = 'Povoleny: &lt;a&gt;, &lt;p&gt;, &lt;strong&gt;, &lt;b&gt;, &lt;em&gt;, &lt;ul&gt;, &lt;ol&gt;, &lt;li&gt;, &lt;img&gt;, &lt;blockquote&gt;. Skripty &lt;script&gt; jsou filtrovány.';
            = 'Uložit nastavení';
    } else {
               = 'Allow Safe HTML in Categories: Settings';
                = 'Allows post-style formatting, links, and lists in taxonomy descriptions without disabling XSS protection.';
               = 'Settings successfully saved!';
                = 'Standard Post Categories (category)';
                = 'Standard Post Tags (post_tag)';
           = 'WooCommerce Product Categories (product_cat)';
           = 'WooCommerce Product Tags (product_tag)';
                 = 'Apply to all custom taxonomies';
           = 'Safe Allowed Tags (wp_kses post)';
           = 'Permitted: &lt;a&gt;, &lt;p&gt;, &lt;strong&gt;, &lt;em&gt;, &lt;ul&gt;, &lt;ol&gt;, &lt;li&gt;, &lt;img&gt;, &lt;blockquote&gt;. Potentially dangerous scripts are automatically stripped.';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🏷️ <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_allow_html_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_allow_html_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="allow_categories" value="1" <?php checked( ['allow_categories'], 1 ); ?>>
                            <?php echo ( 'ru' ===  ) ? 'Включить безопасный HTML в рубриках' : 'Enable HTML in categories'; ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="allow_tags" value="1" <?php checked( ['allow_tags'], 1 ); ?>>
                            <?php echo ( 'ru' ===  ) ? 'Включить безопасный HTML в метках' : 'Enable HTML in tags'; ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="allow_product_cats" value="1" <?php checked( ['allow_product_cats'], 1 ); ?>>
                            <?php echo ( 'ru' ===  ) ? 'Включить в категориях товаров WooCommerce' : 'Enable in WooCommerce product categories'; ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="allow_product_tags" value="1" <?php checked( ['allow_product_tags'], 1 ); ?>>
                            <?php echo ( 'ru' ===  ) ? 'Включить в метках товаров WooCommerce' : 'Enable in WooCommerce product tags'; ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="allow_all_tax" value="1" <?php checked( ['allow_all_tax'], 1 ); ?>>
                            <?php echo ( 'ru' ===  ) ? 'Разрешать во всех остальных пользовательских таксономиях' : 'Allow in all other taxonomies'; ?>
                        </label>
                    </td>
                </tr>
            </table>

            <div style="background:#f8fafc;padding:15px;border:1px solid #e2e8f0;border-radius:6px;margin-top:20px;">
                <h4 style="margin:0 0 5px;"><?php echo esc_html(  ); ?></h4>
                <p style="margin:0;font-size:13px;color:#475569;"><?php echo ; ?></p>
            </div>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-allow-html-cats" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_allow_html_settings', function() {
    check_admin_referer( 'vladimir_save_allow_html_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'allow_categories'   => isset( ['allow_categories'] ) ? 1 : 0,
        'allow_tags'         => isset( ['allow_tags'] ) ? 1 : 0,
        'allow_product_cats' => isset( ['allow_product_cats'] ) ? 1 : 0,
        'allow_product_tags' => isset( ['allow_product_tags'] ) ? 1 : 0,
        'allow_all_tax'      => isset( ['allow_all_tax'] ) ? 1 : 0,
    );

    update_option( '_vladimir_allow_html_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-allow-html-cats-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. SANITIZATION ENGINE
// ─────────────────────────────────────────────

function wahc_sanitize_term_description(  ) {
    return wp_kses( , wp_kses_allowed_html( 'post' ) );
}

remove_filter( 'pre_term_description', 'wp_filter_kses' );
add_filter( 'pre_term_description', 'wahc_sanitize_term_description' );

remove_filter( 'term_description', 'wp_kses_data' );
add_filter( 'term_description', 'wahc_sanitize_term_description' );

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'Разрешить безопасный HTML в категориях (VladiMIR+AI)';
            [  ]['Description'] = 'Разрешает безопасное HTML-форматирование в описаниях рубрик и таксономий без отключения XSS-фильтрации. Включает панель настроек на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'Povolit bezpečné HTML v kategoriích (VladiMIR+AI)';
            [  ]['Description'] = 'Umožňuje bezpečné HTML formátování v popisech kategorií a taxonomií bez vypnutí XSS ochrany. Zahrnuje stránku nastavení.';
        }
    }
    return ;
} );

