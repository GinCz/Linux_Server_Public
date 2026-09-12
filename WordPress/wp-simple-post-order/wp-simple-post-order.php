<?php
/**
 * Plugin Name: WP Simple Post & Category Order (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-simple-post-order
 * Description: Native HTML5 drag-and-drop reordering for posts, pages, WooCommerce products, categories, and taxonomies with sub-millisecond AJAX updates. Flexible per-site granular settings.
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
     = array(
        'enable_post'        => 1,
        'enable_page'        => 0,
        'enable_product'     => 1,
        'enable_category'    => 1,
        'enable_product_cat' => 1,
        'enable_post_tag'    => 0,
        'enable_product_tag' => 0,
        'apply_frontend'     => 1,
        'order_direction'    => 'ASC',
    );
     = get_option( '_vladimir_post_order_settings', array() );
    return wp_parse_args( is_array(  ) ?  : array(),  );
}

function vladimir_post_order_active_types() {
     = vladimir_post_order_get_settings();
        = array();
    if ( ! empty( ['enable_post'] ) ) {
        [] = 'post';
    }
    if ( ! empty( ['enable_page'] ) ) {
        [] = 'page';
    }
    if ( ! empty( ['enable_product'] ) && post_type_exists( 'product' ) ) {
        [] = 'product';
    }
    return ;
}

function vladimir_post_order_active_taxonomies() {
     = vladimir_post_order_get_settings();
         = array();
    if ( ! empty( ['enable_category'] ) ) {
        [] = 'category';
    }
    if ( ! empty( ['enable_product_cat'] ) && taxonomy_exists( 'product_cat' ) ) {
        [] = 'product_cat';
    }
    if ( ! empty( ['enable_post_tag'] ) ) {
        [] = 'post_tag';
    }
    if ( ! empty( ['enable_product_tag'] ) && taxonomy_exists( 'product_tag' ) ) {
        [] = 'product_tag';
    }
    return ;
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function(  ) {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

     = ( 'ru' ===  ) ? 'Настройки' : ( ( 'cs' ===  ) ? 'Nastavení' : 'Settings' );
         = ( 'ru' ===  ) ? 'Документация ↗' : ( ( 'cs' ===  ) ? 'Dokumentace ↗' : 'Documentation ↗' );

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-post-order-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-simple-post-order" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Post & Category Order (VladiMIR+AI)',
        'Сортировка записей и категорий',
        'manage_options',
        'vladimir-post-order-settings',
        'vladimir_post_order_render_settings_page'
    );
} );

function vladimir_post_order_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_post_order_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'Сортировка записей и категорий: Точные настройки для сайта';
                = 'Включайте ручную drag-and-drop сортировку только для тех разделов, где это необходимо (записи, товары, категории магазина).';
               = 'Настройки успешно сохранены!';
           = '1. Сортировка записей и товаров (Post Types)';
               = 'Записи (post)';
               = 'Страницы (page)';
            = 'Товары WooCommerce (product)';
             = '2. Сортировка категорий и таксономий (Taxonomies)';
                = 'Рубрики / Категории записей (category)';
           = 'Категории товаров WooCommerce (product_cat)';
                = 'Метки записей (post_tag)';
           = 'Метки товаров WooCommerce (product_tag)';
             = '3. Отображение на витрине сайта (Frontend)';
               = 'Автоматически применять пользовательский порядок на сайте';
          = 'Применяет сохраненный порядок в основных циклах вывода товаров, записей и списках категорий.';
                 = 'Направление сортировки';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'Řazení příspěvků a kategorií: Nastavení';
                = 'Aktivujte ruční drag-and-drop řazení pouze pro požadované sekce (příspěvky, produkty, kategorie).';
               = 'Nastavení bylo úspěšně uloženo!';
           = '1. Řazení příspěvků a produktů (Post Types)';
               = 'Příspěvky (post)';
               = 'Stránky (page)';
            = 'Produkty WooCommerce (product)';
             = '2. Řazení kategorií a taxonomií (Taxonomies)';
                = 'Rubriky příspěvků (category)';
           = 'Kategorie produktů WooCommerce (product_cat)';
                = 'Štítky příspěvků (post_tag)';
           = 'Štítky produktů WooCommerce (product_tag)';
             = '3. Zobrazení na webu (Frontend)';
               = 'Aplikovat pořadí i na veřejném webu';
          = 'Použije nastavené pořadí ve výpisech.';
                 = 'Směr řazení';
            = 'Uložit nastavení';
    } else {
               = 'Post & Category Order: Granular Settings';
                = 'Enable drag-and-drop reordering selectively for posts, products, and categories.';
               = 'Settings successfully saved!';
           = '1. Post & Product Reordering';
               = 'Posts (post)';
               = 'Pages (page)';
            = 'WooCommerce Products (product)';
             = '2. Category & Taxonomy Reordering';
                = 'Post Categories (category)';
           = 'WooCommerce Product Categories (product_cat)';
                = 'Post Tags (post_tag)';
           = 'WooCommerce Product Tags (product_tag)';
             = '3. Frontend Application';
               = 'Automatically apply custom order to frontend displays';
          = 'Applies saved order to main product/post loops and category listings.';
                 = 'Order Direction';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>↕️ <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_post_order_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_post_order_settings">

            <h3 style="margin-top:0;"><?php echo esc_html(  ); ?></h3>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row">Выбор объектов</th>
                    <td>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_post" value="1" <?php checked( ['enable_post'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_product" value="1" <?php checked( ['enable_product'], 1 ); ?>>
                            <strong><?php echo esc_html(  ); ?></strong>
                        </label>
                        <label style="display:block;">
                            <input type="checkbox" name="enable_page" value="1" <?php checked( ['enable_page'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
            </table>

            <h3 style="margin-top:25px;border-top:1px solid #e2e8f0;padding-top:15px;"><?php echo esc_html(  ); ?></h3>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row">Категории и рубрики</th>
                    <td>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_category" value="1" <?php checked( ['enable_category'], 1 ); ?>>
                            <strong><?php echo esc_html(  ); ?></strong>
                        </label>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_product_cat" value="1" <?php checked( ['enable_product_cat'], 1 ); ?>>
                            <strong><?php echo esc_html(  ); ?></strong>
                        </label>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_post_tag" value="1" <?php checked( ['enable_post_tag'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <label style="display:block;">
                            <input type="checkbox" name="enable_product_tag" value="1" <?php checked( ['enable_product_tag'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
            </table>

            <h3 style="margin-top:25px;border-top:1px solid #e2e8f0;padding-top:15px;"><?php echo esc_html(  ); ?></h3>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="order_direction"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <select name="order_direction" id="order_direction">
                            <option value="ASC" <?php selected( ['order_direction'], 'ASC' ); ?>>ASC (По возрастанию - сверху вниз, стандарт)</option>
                            <option value="DESC" <?php selected( ['order_direction'], 'DESC' ); ?>>DESC (По убыванию)</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Применение</th>
                    <td>
                        <label>
                            <input type="checkbox" name="apply_frontend" value="1" <?php checked( ['apply_frontend'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
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

     = array(
        'enable_post'        => isset( ['enable_post'] ) ? 1 : 0,
        'enable_page'        => isset( ['enable_page'] ) ? 1 : 0,
        'enable_product'     => isset( ['enable_product'] ) ? 1 : 0,
        'enable_category'    => isset( ['enable_category'] ) ? 1 : 0,
        'enable_product_cat' => isset( ['enable_product_cat'] ) ? 1 : 0,
        'enable_post_tag'    => isset( ['enable_post_tag'] ) ? 1 : 0,
        'enable_product_tag' => isset( ['enable_product_tag'] ) ? 1 : 0,
        'apply_frontend'     => isset( ['apply_frontend'] ) ? 1 : 0,
        'order_direction'    => in_array( (string) ( ['order_direction'] ?? 'ASC' ), array( 'ASC', 'DESC' ), true ) ? (string) ['order_direction'] : 'ASC',
    );

    update_option( '_vladimir_post_order_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-post-order-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. AJAX HANDLERS (Posts & Terms)
// ─────────────────────────────────────────────

// Save post order
add_action( 'wp_ajax_wspo_save_order', function() {
    check_ajax_referer( 'wspo_nonce', 'nonce' );
    if ( ! current_user_can( 'edit_posts' ) ) {
        wp_die( 'Forbidden', 403 );
    }

     = array_map( 'intval', (array) ( ['order'] ?? array() ) );
    foreach (  as  =>  ) {
        wp_update_post( array(
            'ID'         => ,
            'menu_order' => ,
        ) );
    }
    wp_send_json_success();
} );

// Save taxonomy term order
add_action( 'wp_ajax_wspo_save_term_order', function() {
    check_ajax_referer( 'wspo_term_nonce', 'nonce' );
    if ( ! current_user_can( 'manage_categories' ) ) {
        wp_die( 'Forbidden', 403 );
    }

     = array_map( 'intval', (array) ( ['order'] ?? array() ) );
    foreach (  as  =>  ) {
        update_term_meta( , '_menu_order',  );
    }
    wp_send_json_success();
} );

// ─────────────────────────────────────────────
// 5. QUERY ORDER HOOKS (Frontend & Backend)
// ─────────────────────────────────────────────

// Posts ordering
add_action( 'pre_get_posts', function( WP_Query  ) {
     = vladimir_post_order_get_settings();
    if ( empty( ['apply_frontend'] ) && ! is_admin() ) {
        return;
    }
    if ( ! ->is_main_query() ) {
        return;
    }

     = vladimir_post_order_active_types();
        = ->get( 'post_type' ) ?: 'post';

    if ( in_array( , , true ) ) {
        ->set( 'orderby', 'menu_order' );
        ->set( 'order', ['order_direction'] );
    }
} );

// Taxonomy terms ordering
add_filter( 'get_terms_args', function( ,  ) {
     = vladimir_post_order_active_taxonomies();
    if ( empty(  ) ) {
        return ;
    }

     = false;
    foreach ( (array)  as  ) {
        if ( in_array( , , true ) ) {
             = true;
            break;
        }
    }

    if (  && ! is_admin() ) {
         = vladimir_post_order_get_settings();
        if ( ! empty( ['apply_frontend'] ) ) {
            ['meta_key'] = '_menu_order';
            ['orderby']  = 'meta_value_num';
            ['order']    = ['order_direction'];
        }
    }

    return ;
}, 10, 2 );

// ─────────────────────────────────────────────
// 6. ADMIN DRAG & DROP UI (Posts & Taxonomy Tables)
// ─────────────────────────────────────────────

// Draggable posts/products
add_action( 'admin_footer-edit.php', function() {
     = get_current_screen();
    if ( !  ) {
        return;
    }

     = vladimir_post_order_active_types();
    if ( ! in_array( ->post_type, , true ) ) {
        return;
    }

     = wp_create_nonce( 'wspo_nonce' );
    echo "<style>#the-list tr{cursor:grab;transition:background .15s}#the-list tr.wspo-over{background:#e8f4ff!important;border-top:2px solid #0073aa}#the-list tr.wspo-drag{opacity:.4}</style>
    <script>
    (function(){
    var list=document.querySelector('#the-list'),drag=null;
    if(!list)return;
    list.addEventListener('dragstart',function(e){drag=e.target.closest('tr');if(drag)drag.classList.add('wspo-drag');});
    list.addEventListener('dragend',function(){list.querySelectorAll('tr').forEach(function(r){r.classList.remove('wspo-drag','wspo-over');});save();});
    list.addEventListener('dragover',function(e){e.preventDefault();var tr=e.target.closest('tr');list.querySelectorAll('tr').forEach(function(r){r.classList.remove('wspo-over');});if(tr&&tr!==drag)tr.classList.add('wspo-over');});
    list.addEventListener('drop',function(e){e.preventDefault();var tr=e.target.closest('tr');if(tr&&tr!==drag)tr.parentNode.insertBefore(drag,tr);});
    list.querySelectorAll('tr').forEach(function(r){r.setAttribute('draggable','true');});
    function save(){var ids=[].slice.call(list.querySelectorAll('tr[id]')).map(function(r){return r.id.replace(/^post-/,'');}).filter(Boolean);var fd=new FormData();fd.append('action','wspo_save_order');fd.append('nonce','" .  . "');ids.forEach(function(id,i){fd.append('order['+i+']',id);});fetch(ajaxurl,{method:'POST',body:fd,credentials:'same-origin'});}
    })();
    </script>";
} );

// Draggable taxonomy categories / tags
add_action( 'admin_footer-edit-tags.php', function() {
     = get_current_screen();
    if ( !  ) {
        return;
    }

     = vladimir_post_order_active_taxonomies();
    if ( ! in_array( ->taxonomy, , true ) ) {
        return;
    }

     = wp_create_nonce( 'wspo_term_nonce' );
    echo "<style>#the-list tr{cursor:grab;transition:background .15s}#the-list tr.wspo-over{background:#e8f4ff!important;border-top:2px solid #0073aa}#the-list tr.wspo-drag{opacity:.4}</style>
    <script>
    (function(){
    var list=document.querySelector('#the-list'),drag=null;
    if(!list)return;
    list.addEventListener('dragstart',function(e){drag=e.target.closest('tr');if(drag)drag.classList.add('wspo-drag');});
    list.addEventListener('dragend',function(){list.querySelectorAll('tr').forEach(function(r){r.classList.remove('wspo-drag','wspo-over');});save();});
    list.addEventListener('dragover',function(e){e.preventDefault();var tr=e.target.closest('tr');list.querySelectorAll('tr').forEach(function(r){r.classList.remove('wspo-over');});if(tr&&tr!==drag)tr.classList.add('wspo-over');});
    list.addEventListener('drop',function(e){e.preventDefault();var tr=e.target.closest('tr');if(tr&&tr!==drag)tr.parentNode.insertBefore(drag,tr);});
    list.querySelectorAll('tr').forEach(function(r){r.setAttribute('draggable','true');});
    function save(){var ids=[].slice.call(list.querySelectorAll('tr[id]')).map(function(r){return r.id.replace(/^tag-/,'');}).filter(Boolean);var fd=new FormData();fd.append('action','wspo_save_term_order');fd.append('nonce','" .  . "');ids.forEach(function(id,i){fd.append('order['+i+']',id);});fetch(ajaxurl,{method:'POST',body:fd,credentials:'same-origin'});}
    })();
    </script>";
} );

// ─────────────────────────────────────────────
// 7. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'WP Сортировка записей и категорий (VladiMIR+AI)';
            [  ]['Description'] = 'Нативная Drag-and-drop сортировка записей, товаров и категорий в админке без сторонних библиотек. Гибкие настройки выбора разделов и порядка на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'WP Řazení příspěvků a kategorií (VladiMIR+AI)';
            [  ]['Description'] = 'Nativní drag-and-drop přetahovací řazení příspěvků, produktů a kategorií v administraci s přehlednou stránkou podrobného nastavení.';
        }
    }
    return ;
} );

