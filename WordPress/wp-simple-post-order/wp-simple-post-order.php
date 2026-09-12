<?php
/**
 * Plugin Name: WP Simple Post & Category Order (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-simple-post-order
 * Description: Native HTML5 drag-and-drop reordering for posts, pages, WooCommerce products, categories, and taxonomies with AJAX updates. Flexible per-site granular settings.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: wp-simple-post-order
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_post_order_get_settings() {
    $defaults = array(
        'enable_post'        => 1,
        'enable_page'        => 0,
        'enable_product'     => 1,
        'enable_category'    => 1,
        'enable_product_cat' => 1,
        'apply_frontend'     => 1,
        'order_direction'    => 'ASC',
    );
    $saved = get_option( '_vladimir_post_order_settings', array() );
    return wp_parse_args( is_array( $saved ) ? $saved : array(), $defaults );
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-post-order-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-simple-post-order" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Post & Category Order (VladiMIR+AI)',
        'Сортировка записей',
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
        $txt_dir      = 'Порядок сортировки (Order Direction)';
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
        $txt_dir      = 'Směr řazení';
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
        $txt_dir      = 'Order Direction';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>↕️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
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
                    <th scope="row"><strong>Записи и страницы</strong></th>
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
                    <th scope="row"><strong>Категории</strong></th>
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

            <h2 style="font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-top:20px;">3. Применение на сайте</h2>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Фронтенд</strong></th>
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
                            <option value="ASC" <?php selected( $settings['order_direction'], 'ASC' ); ?>>По возрастанию (ASC - по умолчанию)</option>
                            <option value="DESC" <?php selected( $settings['order_direction'], 'DESC' ); ?>>По убыванию (DESC)</option>
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
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-simple-post-order" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
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

    update_option( '_vladimir_post_order_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-post-order-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
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
    if ( is_admin() ) {
        $screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
        if ( $screen && 'edit' === $screen->base && in_array( $screen->post_type, vladimir_post_order_active_types(), true ) ) {
            $orderby = $query->get( 'orderby' );
            if ( empty( $orderby ) ) {
                $settings = vladimir_post_order_get_settings();
                $query->set( 'orderby', 'menu_order' );
                $query->set( 'order', $settings['order_direction'] );
            }
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

    if ( ! current_user_can( 'edit_posts' ) ) {
        wp_send_json_error( 'Forbidden' );
    }

    $order = isset( $_POST['order'] ) ? array_map( 'intval', (array) $_POST['order'] ) : array();
    global $wpdb;

    foreach ( $order as $menu_order => $post_id ) {
        $wpdb->update(
            $wpdb->posts,
            array( 'menu_order' => $menu_order ),
            array( 'ID' => $post_id ),
            array( '%d' ),
            array( '%d' )
        );
        clean_post_cache( $post_id );
    }

    wp_send_json_success();
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

    $order = isset( $_POST['order'] ) ? array_map( 'intval', (array) $_POST['order'] ) : array();
    foreach ( $order as $index => $term_id ) {
        update_term_meta( $term_id, '_vladimir_term_order', $index );
        clean_term_cache( $term_id );
    }

    wp_send_json_success();
} );

add_filter( 'get_terms_args', function( $args, $taxonomies ) {
    $active = vladimir_post_order_active_taxonomies();
    if ( array_intersect( (array) $taxonomies, $active ) ) {
        $settings = vladimir_post_order_get_settings();
        if ( ! empty( $settings['apply_frontend'] ) || is_admin() ) {
            $args['meta_key'] = '_vladimir_term_order';
            $args['orderby']  = 'meta_value_num';
            $args['order']    = $settings['order_direction'];
        }
    }
    return $args;
}, 10, 2 );

// ─────────────────────────────────────────────
// 6. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP Simple Post & Category Order (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Сортировка записей, товаров WooCommerce и рубрик простым перетаскиванием мышкой (Drag-and-Drop) с гранулярными настройками.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP Simple Post & Category Order (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Ruční řazení příspěvků, produktů WooCommerce a kategorií přetažením myší (drag-and-drop).';
        }
    }
    return $plugins;
} );
