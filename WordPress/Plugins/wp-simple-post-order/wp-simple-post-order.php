<?php
/**
 * Plugin Name: WP Simple Post & Category Order (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-simple-post-order
 * Description: Native HTML5 drag-and-drop reordering for posts, pages, WooCommerce products, categories and taxonomies with AJAX updates, plus a configurable default sort order (field and direction) for each admin list. Products are left untouched unless you switch it on.
 * Version:     2026-09__1.28
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-simple-post-order
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-simple-post-order
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

function vladimir_post_order_get_settings() {
    $defaults = array(
        // Drag & drop reordering, per content type.
        'enable_post'        => 1,
        'enable_page'        => 0,
        'enable_product'     => 0,
        'enable_category'    => 1,
        'enable_product_cat' => 1,
        'apply_frontend'     => 1,
        'order_direction'    => 'ASC',

        // Default sorting of the admin list, per content type.
        // 'default' means: do not touch the query at all.
        //
        // Products deliberately default to 'default'. An earlier release forced the
        // product list to date/DESC unconditionally, a shop owner could not understand
        // where freshly added products had gone, and it took a support call to find out
        // that a plugin had quietly taken the sorting over. Nothing is overridden now
        // unless it is switched on here explicitly.
        'admin_orderby_post'    => 'default',
        'admin_order_post'      => 'DESC',
        'admin_orderby_page'    => 'default',
        'admin_order_page'      => 'ASC',
        'admin_orderby_product' => 'default',
        'admin_order_product'   => 'DESC',
    );
    $saved = get_option( '_vladimir_post_order_settings', array() );
    return wp_parse_args( is_array( $saved ) ? $saved : array(), $defaults );
}

/**
 * Sort fields offered for the admin list, keyed by the value stored in settings.
 *
 * @return array<string,string>
 */
function vladimir_post_order_sort_fields() {
    return array(
        'default'    => 'WordPress default (do not touch)',
        'date'       => 'Date created',
        'modified'   => 'Date modified',
        'title'      => 'Title',
        'menu_order' => 'Manual order (menu_order)',
        'ID'         => 'ID',
    );
}

/**
 * Admin-list sorting configured for one post type.
 *
 * @param string $post_type Post type slug.
 * @return array{orderby:string,order:string}
 */
function vladimir_post_order_admin_sort( $post_type ) {
    $settings = vladimir_post_order_get_settings();
    $fields   = vladimir_post_order_sort_fields();

    $orderby = isset( $settings[ 'admin_orderby_' . $post_type ] ) ? (string) $settings[ 'admin_orderby_' . $post_type ] : 'default';
    $order   = isset( $settings[ 'admin_order_' . $post_type ] ) ? strtoupper( (string) $settings[ 'admin_order_' . $post_type ] ) : 'DESC';

    if ( ! isset( $fields[ $orderby ] ) ) {
        $orderby = 'default';
    }

    return array(
        'orderby' => $orderby,
        'order'   => ( 'ASC' === $order ) ? 'ASC' : 'DESC',
    );
}

function vladimir_post_order_active_types() {
    $settings = vladimir_post_order_get_settings();
    $types    = array();
    if ( ! empty( $settings['enable_post'] ) ) {
        $types[] = 'post';
    }
    if ( ! empty( $settings['enable_page'] ) ) {
        $types[] = 'page';
    }
    if ( ! empty( $settings['enable_product'] ) && post_type_exists( 'product' ) ) {
        $types[] = 'product';
    }
    return $types;
}

function vladimir_post_order_active_taxonomies() {
    $settings = vladimir_post_order_get_settings();
    $taxes    = array();
    if ( ! empty( $settings['enable_category'] ) ) {
        $taxes[] = 'category';
    }
    if ( ! empty( $settings['enable_product_cat'] ) && taxonomy_exists( 'product_cat' ) ) {
        $taxes[] = 'product_cat';
    }
    return $taxes;
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function( $links ) {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $settings_label = ( 'ru' === $lang ) ? 'Настройки' : ( ( 'cs' === $lang ) ? 'Nastavení' : 'Settings' );
    $docs_label     = ( 'ru' === $lang ) ? 'Документация ↗' : ( ( 'cs' === $lang ) ? 'Dokumentace ↗' : 'Documentation ↗' );

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-post-order-settings' ) ) . '" style="white-space:nowrap;">' . esc_html( $settings_label ) . '</a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-simple-post-order" target="_blank" style="white-space:nowrap;">' . esc_html( $docs_label ) . '</a>';

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
        'Post & Category Order (VladiMIR+AI✅)',
        'Post & Category Order',
        'manage_options',
        'vladimir-post-order-settings',
        'vladimir_post_order_render_settings_page'
    );
} );

function vladimir_post_order_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_post_order_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Сортировка записей и рубрик: Гранулярные настройки';
        $txt_subtitle = 'Включение перетаскивания мышкой (drag-and-drop) отдельно для записей, страниц, товаров и категорий WooCommerce.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_post     = 'Записи блога (Posts)';
        $txt_page     = 'Страницы сайта (Pages)';
        $txt_prod     = 'Товары интернет-магазина (WooCommerce Products)';
        $txt_cat      = 'Рубрики записей (Categories)';
        $txt_pcat     = 'Категории товаров WooCommerce (Product Categories)';
        $txt_front    = 'Автоматически применять порядок сортировки на фронтенде сайта';
        $txt_dir       = 'Порядок сортировки (Order Direction)';
        $txt_sort_h    = '2b. Сортировка списков в админке';
        $txt_sort_note = 'Чем сортировать список в админке, когда пользователь сам не выбрал колонку. «WordPress default» — плагин не вмешивается вообще. Для товаров это значение стоит по умолчанию намеренно: раньше плагин молча забирал сортировку товаров себе, и свежедобавленные товары «пропадали» из начала списка.';
        $txt_desc      = 'По убыванию (новые сверху)';
        $txt_asc       = 'По возрастанию';
        $txt_save     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Řazení příspěvků a kategorií: Nastavení';
        $txt_subtitle = 'Přetažení myší (drag-and-drop) samostatně pro příspěvky, stránky, produkty a kategorie WooCommerce.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_post     = 'Příspěvky (Posts)';
        $txt_page     = 'Stránky (Pages)';
        $txt_prod     = 'Produkty WooCommerce (Products)';
        $txt_cat      = 'Kategorie příspěvků';
        $txt_pcat     = 'Kategorie produktů WooCommerce';
        $txt_front    = 'Automaticky aplikovat řazení na webu';
        $txt_dir       = 'Směr řazení';
        $txt_sort_h    = '2b. Řazení seznamů v administraci';
        $txt_sort_note = 'Podle čeho řadit seznam v administraci, když uživatel sám nezvolí sloupec. „WordPress default“ znamená, že plugin do řazení nezasahuje. U produktů je to záměrně výchozí volba.';
        $txt_desc      = 'Sestupně (nejnovější nahoře)';
        $txt_asc       = 'Vzestupně';
        $txt_save     = 'Uložit nastavení';
    } else {
        $txt_title    = 'Post & Category Order: Granular Settings';
        $txt_subtitle = 'Enable HTML5 drag-and-drop ordering for posts, pages, products, and categories.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_post     = 'Blog Posts';
        $txt_page     = 'Static Pages';
        $txt_prod     = 'WooCommerce Products';
        $txt_cat      = 'Post Categories';
        $txt_pcat     = 'WooCommerce Product Categories';
        $txt_front    = 'Automatically Apply Order to Frontend Queries';
        $txt_dir       = 'Order Direction';
        $txt_sort_h    = '2b. Admin list sorting';
        $txt_sort_note = 'How the admin list is sorted when the user has not picked a column. "WordPress default" means the plugin does not interfere at all. For products that is the default on purpose: an earlier release silently took product sorting over and freshly added products seemed to disappear from the top of the list.';
        $txt_desc      = 'Descending (newest first)';
        $txt_asc       = 'Ascending';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>↕️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI✅)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_post_order_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_post_order_settings">

            <h2 style="font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-top:0;">1. Типы записей (Drag & Drop)</h2>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Posts and pages</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="enable_post" value="1" <?php checked( $settings['enable_post'], 1 ); ?>>
                                <?php echo esc_html( $txt_post ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_page" value="1" <?php checked( $settings['enable_page'], 1 ); ?>>
                                <?php echo esc_html( $txt_page ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_product" value="1" <?php checked( $settings['enable_product'], 1 ); ?>>
                                <?php echo esc_html( $txt_prod ); ?>
                            </label>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <h2 style="font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-top:20px;">2. Таксономии и Рубрики</h2>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Categories</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="enable_category" value="1" <?php checked( $settings['enable_category'], 1 ); ?>>
                                <?php echo esc_html( $txt_cat ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_product_cat" value="1" <?php checked( $settings['enable_product_cat'], 1 ); ?>>
                                <?php echo esc_html( $txt_pcat ); ?>
                            </label>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <h2 style="font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-top:20px;"><?php echo esc_html( $txt_sort_h ); ?></h2>
            <p style="color:#64748b;font-size:13px;margin:8px 0 12px;"><?php echo esc_html( $txt_sort_note ); ?></p>
            <table class="form-table" role="presentation">
                <?php
                $sort_rows = array(
                    'post'    => $txt_post,
                    'page'    => $txt_page,
                    'product' => $txt_prod,
                );
                $sort_fields = vladimir_post_order_sort_fields();

                foreach ( $sort_rows as $pt => $label ) :
                    if ( 'product' === $pt && ! post_type_exists( 'product' ) ) {
                        continue;
                    }
                    $current = vladimir_post_order_admin_sort( $pt );
                    ?>
                    <tr>
                        <th scope="row"><label for="admin_orderby_<?php echo esc_attr( $pt ); ?>"><strong><?php echo esc_html( $label ); ?></strong></label></th>
                        <td>
                            <select name="admin_orderby_<?php echo esc_attr( $pt ); ?>" id="admin_orderby_<?php echo esc_attr( $pt ); ?>" style="min-width:250px;">
                                <?php foreach ( $sort_fields as $value => $title ) : ?>
                                    <option value="<?php echo esc_attr( $value ); ?>" <?php selected( $current['orderby'], $value ); ?>><?php echo esc_html( $title ); ?></option>
                                <?php endforeach; ?>
                            </select>
                            <select name="admin_order_<?php echo esc_attr( $pt ); ?>" style="min-width:150px;margin-left:8px;">
                                <option value="DESC" <?php selected( $current['order'], 'DESC' ); ?>><?php echo esc_html( $txt_desc ); ?></option>
                                <option value="ASC" <?php selected( $current['order'], 'ASC' ); ?>><?php echo esc_html( $txt_asc ); ?></option>
                            </select>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </table>

            <h2 style="font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-top:20px;">3. Применение на сайте</h2>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Frontend</strong></th>
                    <td>
                        <label>
                            <input type="checkbox" name="apply_frontend" value="1" <?php checked( $settings['apply_frontend'], 1 ); ?>>
                            <?php echo esc_html( $txt_front ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="order_direction"><strong><?php echo esc_html( $txt_dir ); ?></strong></label></th>
                    <td>
                        <select name="order_direction" id="order_direction" style="min-width:180px;">
                            <option value="ASC" <?php selected( $settings['order_direction'], 'ASC' ); ?>>Ascending (ASC - default)</option>
                            <option value="DESC" <?php selected( $settings['order_direction'], 'DESC' ); ?>>Descending (DESC)</option>
                        </select>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-simple-post-order" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_post_order_settings', function() {
    check_admin_referer( 'vladimir_save_post_order_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'enable_post'        => isset( $_POST['enable_post'] ) ? 1 : 0,
        'enable_page'        => isset( $_POST['enable_page'] ) ? 1 : 0,
        'enable_product'     => isset( $_POST['enable_product'] ) ? 1 : 0,
        'enable_category'    => isset( $_POST['enable_category'] ) ? 1 : 0,
        'enable_product_cat' => isset( $_POST['enable_product_cat'] ) ? 1 : 0,
        'apply_frontend'     => isset( $_POST['apply_frontend'] ) ? 1 : 0,
        'order_direction'    => ( isset( $_POST['order_direction'] ) && 'DESC' === $_POST['order_direction'] ) ? 'DESC' : 'ASC',
    );

    // Admin-list sorting, one pair of values per post type, both validated against
    // the allow-lists rather than trusted from the form.
    $sort_fields = vladimir_post_order_sort_fields();

    foreach ( array( 'post', 'page', 'product' ) as $pt ) {
        $orderby = isset( $_POST[ 'admin_orderby_' . $pt ] ) ? sanitize_key( wp_unslash( $_POST[ 'admin_orderby_' . $pt ] ) ) : 'default';
        $order   = isset( $_POST[ 'admin_order_' . $pt ] ) ? strtoupper( sanitize_key( wp_unslash( $_POST[ 'admin_order_' . $pt ] ) ) ) : 'DESC';

        // sanitize_key() lowercases, so the allow-list is matched case-insensitively.
        $matched = 'default';
        foreach ( array_keys( $sort_fields ) as $candidate ) {
            if ( strtolower( $candidate ) === $orderby ) {
                $matched = $candidate;
                break;
            }
        }

        $updated[ 'admin_orderby_' . $pt ] = $matched;
        $updated[ 'admin_order_' . $pt ]   = ( 'ASC' === $order ) ? 'ASC' : 'DESC';
    }

    update_option( '_vladimir_post_order_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-post-order-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 3b. MERGED PLUGIN NOTICE
// ─────────────────────────────────────────────
// wc-admin-default-sort-date was merged into this plugin in 2026-09__1.22. Its job is
// now the "Admin list sorting" row for products - switched off by default, so nothing
// takes the product order over behind the shop owner's back.

add_action( 'admin_notices', function() {
    $screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
    if ( ! $screen || ! in_array( $screen->id, array( 'plugins', 'settings_page_vladimir-post-order-settings' ), true ) ) {
        return;
    }

    if ( ! current_user_can( 'activate_plugins' ) ) {
        return;
    }

    if ( ! function_exists( 'is_plugin_active' ) ) {
        require_once ABSPATH . 'wp-admin/includes/plugin.php';
    }

    if ( ! is_plugin_active( 'wc-admin-default-sort-date/wc-admin-default-sort-date.php' ) ) {
        return;
    }

    echo '<div class="notice notice-warning"><p><strong>WP Simple Post &amp; Category Order:</strong> '
        . 'the plugin "WooCommerce Admin Products Default Sort by Date" is still active. '
        . 'It has been merged into this one - deactivate and delete it, then set the product row '
        . 'under "Admin list sorting" if you want that behaviour back.</p></div>';
} );

// ─────────────────────────────────────────────
// 4. POST REORDERING ENGINE (DRAG & DROP)
// ─────────────────────────────────────────────

add_action( 'admin_init', function() {
    $active_types = vladimir_post_order_active_types();
    foreach ( $active_types as $pt ) {
        add_post_type_support( $pt, 'page-attributes' );
    }
} );

add_action( 'pre_get_posts', function( $query ) {
    if ( is_admin() && $query->is_main_query() ) {
        $screen    = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
        $post_type = $screen ? $screen->post_type : ( isset( $_GET['post_type'] ) ? sanitize_key( $_GET['post_type'] ) : '' );
        $is_edit   = ( $screen && 'edit' === $screen->base ) || ( isset( $GLOBALS['pagenow'] ) && 'edit.php' === $GLOBALS['pagenow'] );

        // Nothing below runs once the user has clicked a column header: an explicit
        // ?orderby= in the URL always wins over anything configured here.
        if ( ! $is_edit || '' === $post_type || ! empty( $_GET['orderby'] ) || '' !== (string) $query->get( 'orderby' ) ) {
            return;
        }

        $settings = vladimir_post_order_get_settings();

        // 1. Drag & drop is on for this type: the manual order is the point of it.
        if ( in_array( $post_type, vladimir_post_order_active_types(), true ) ) {
            $query->set( 'orderby', 'menu_order' );
            $query->set( 'order', $settings['order_direction'] );
            return;
        }

        // 2. Otherwise apply the admin-list sorting configured for this type - and only
        //    if it was configured. 'default' means the plugin keeps its hands off.
        $sort = vladimir_post_order_admin_sort( $post_type );
        if ( 'default' !== $sort['orderby'] ) {
            $query->set( 'orderby', $sort['orderby'] );
            $query->set( 'order', $sort['order'] );
        }
    } else {
        $settings = vladimir_post_order_get_settings();
        if ( ! empty( $settings['apply_frontend'] ) && $query->is_main_query() ) {
            $post_type = $query->get( 'post_type' ) ?: 'post';
            if ( is_array( $post_type ) ? array_intersect( $post_type, vladimir_post_order_active_types() ) : in_array( $post_type, vladimir_post_order_active_types(), true ) ) {
                if ( empty( $query->get( 'orderby' ) ) ) {
                    $query->set( 'orderby', 'menu_order title' );
                    $query->set( 'order', $settings['order_direction'] );
                }
            }
        }
    }
} );

add_action( 'admin_enqueue_scripts', function( $hook ) {
    if ( 'edit.php' !== $hook ) {
        return;
    }

    $screen = get_current_screen();
    if ( ! $screen || ! in_array( $screen->post_type, vladimir_post_order_active_types(), true ) ) {
        return;
    }

    wp_enqueue_script( 'jquery-ui-sortable' );

    $nonce = wp_create_nonce( 'vladimir_post_order_nonce' );
    $script = "
    jQuery(document).ready(function($) {
        var fixHelper = function(e, ui) {
            ui.children().each(function() {
                $(this).width($(this).width());
            });
            return ui;
        };
        $('table.wp-list-table tbody#the-list').sortable({
            items: 'tr',
            cursor: 'move',
            axis: 'y',
            helper: fixHelper,
            opacity: 0.8,
            update: function(e, ui) {
                var order = [];
                $('table.wp-list-table tbody#the-list tr').each(function() {
                    var id = $(this).attr('id');
                    if (id) {
                        order.push(id.replace('post-', ''));
                    }
                });
                $.post(ajaxurl, {
                    action: 'vladimir_update_post_order',
                    order: order,
                    nonce: '{$nonce}'
                });
            }
        });
    });";
    wp_add_inline_script( 'jquery-ui-sortable', $script );
} );

add_action( 'wp_ajax_vladimir_update_post_order', function() {
    check_ajax_referer( 'vladimir_post_order_nonce', 'nonce' );

    // edit_posts was too weak: a Contributor could reorder everyone else's content.
    if ( ! current_user_can( 'edit_others_posts' ) ) {
        wp_send_json_error( 'Forbidden', 403 );
    }

    $order = isset( $_POST['order'] ) ? array_map( 'intval', (array) wp_unslash( $_POST['order'] ) ) : array();
    if ( empty( $order ) ) {
        wp_send_json_error( 'Empty order', 400 );
    }

    $allowed_types = vladimir_post_order_active_types();

    global $wpdb;
    $written = 0;

    foreach ( $order as $menu_order => $post_id ) {
        if ( $post_id <= 0 ) {
            continue;
        }

        // The previous version wrote menu_order for any ID the browser sent, with no check
        // that the row was even a post type this plugin manages.
        $post_type = get_post_type( $post_id );
        if ( ! $post_type || ! in_array( $post_type, $allowed_types, true ) ) {
            continue;
        }

        if ( ! current_user_can( 'edit_post', $post_id ) ) {
            continue;
        }

        $wpdb->update(
            $wpdb->posts,
            array( 'menu_order' => (int) $menu_order ),
            array( 'ID' => $post_id ),
            array( '%d' ),
            array( '%d' )
        );
        clean_post_cache( $post_id );
        $written++;
    }

    wp_send_json_success( array( 'updated' => $written ) );
} );

// ─────────────────────────────────────────────
// 5. TAXONOMY REORDERING ENGINE (CATEGORIES)
// ─────────────────────────────────────────────

add_action( 'admin_enqueue_scripts', function( $hook ) {
    if ( 'edit-tags.php' !== $hook ) {
        return;
    }

    $screen = get_current_screen();
    if ( ! $screen || ! in_array( $screen->taxonomy, vladimir_post_order_active_taxonomies(), true ) ) {
        return;
    }

    wp_enqueue_script( 'jquery-ui-sortable' );

    $nonce = wp_create_nonce( 'vladimir_tax_order_nonce' );
    $script = "
    jQuery(document).ready(function($) {
        var fixHelper = function(e, ui) {
            ui.children().each(function() {
                $(this).width($(this).width());
            });
            return ui;
        };
        $('table.wp-list-table tbody#the-list').sortable({
            items: 'tr',
            cursor: 'move',
            axis: 'y',
            helper: fixHelper,
            opacity: 0.8,
            update: function(e, ui) {
                var order = [];
                $('table.wp-list-table tbody#the-list tr').each(function() {
                    var id = $(this).attr('id');
                    if (id) {
                        order.push(id.replace('tag-', ''));
                    }
                });
                $.post(ajaxurl, {
                    action: 'vladimir_update_tax_order',
                    order: order,
                    nonce: '{$nonce}'
                });
            }
        });
    });";
    wp_add_inline_script( 'jquery-ui-sortable', $script );
} );

add_action( 'wp_ajax_vladimir_update_tax_order', function() {
    check_ajax_referer( 'vladimir_tax_order_nonce', 'nonce' );

    if ( ! current_user_can( 'manage_categories' ) ) {
        wp_send_json_error( 'Forbidden' );
    }

    $order  = isset( $_POST['order'] ) ? array_map( 'intval', (array) wp_unslash( $_POST['order'] ) ) : array();
    $active = vladimir_post_order_active_taxonomies();

    foreach ( $order as $index => $term_id ) {
        if ( $term_id <= 0 ) {
            continue;
        }

        $term = get_term( $term_id );
        if ( ! $term || is_wp_error( $term ) || ! in_array( $term->taxonomy, $active, true ) ) {
            continue;
        }

        update_term_meta( $term_id, '_vladimir_term_order', $index );
        clean_term_cache( $term_id, $term->taxonomy );
    }

    wp_send_json_success();
} );

add_filter( 'terms_clauses', function( $clauses, $taxonomies, $args ) {
    $active = vladimir_post_order_active_taxonomies();
    if ( ! array_intersect( (array) $taxonomies, $active ) ) {
        return $clauses;
    }

    // Do NOT alter term queries looking for specific terms (e.g. by slug, name, ID)
    if ( ! empty( $args['slug'] ) || ! empty( $args['include'] ) || ! empty( $args['name'] ) ) {
        return $clauses;
    }

    $settings = vladimir_post_order_get_settings();
    if ( empty( $settings['apply_frontend'] ) && ! is_admin() ) {
        return $clauses;
    }

    global $wpdb;
    $order_dir = ( isset( $settings['order_direction'] ) && 'DESC' === $settings['order_direction'] ) ? 'DESC' : 'ASC';

    // LEFT JOIN prevents un-ordered terms from being excluded from get_terms()
    if ( false === strpos( $clauses['join'], 'vladimir_tm' ) ) {
        $clauses['join'] .= " LEFT JOIN {$wpdb->termmeta} AS vladimir_tm ON (t.term_id = vladimir_tm.term_id AND vladimir_tm.meta_key = '_vladimir_term_order')";
    }

    $clauses['orderby'] = "ORDER BY CAST(vladimir_tm.meta_value AS UNSIGNED) {$order_dir}, t.name";
    $clauses['order']   = $order_dir;

    return $clauses;
}, 10, 3 );

