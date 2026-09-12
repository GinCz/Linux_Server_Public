<?php
/**
 * Plugin Name: WooCommerce Авто генератор SKU & Поиск по артикулу (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-auto-sku
 * Description: Automatically assigns unique non-sequential 5-digit random SKUs (e.g. 74921, 18304) to new WooCommerce products, enables instant frontend and admin search by SKU, and provides full-store random regeneration.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Requires Plugins: woocommerce
 * Text Domain: wp-auto-sku
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_auto_sku_get_settings() {
     = array(
        'sku_mode'          => 'random', // 'random' (in disorder: 74921) or 'sequential' (00001)
        'sku_digits'        => 5,
        'sku_prefix'        => '',
        'auto_assign_new'   => 1,
        'enable_sku_search' => 1,
    );
     = get_option( '_vladimir_auto_sku_settings', array() );
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

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-auto-sku-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-auto-sku" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS & REGENERATION PAGE
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Auto SKU (VladiMIR+AI)',
        'Генератор SKU',
        'manage_woocommerce',
        'vladimir-auto-sku-settings',
        'vladimir_auto_sku_render_page'
    );
    if ( post_type_exists( 'product' ) ) {
        add_management_page( 'Auto SKU', 'Auto SKU', 'manage_woocommerce', 'wp-auto-sku', 'vladimir_auto_sku_render_page' );
    }
} );

function vladimir_auto_sku_render_page() {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

    if ( ! current_user_can( 'manage_woocommerce' ) && ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

        = vladimir_auto_sku_get_settings();
         = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];
     = isset( ['regenerated'] ) ? absint( ['regenerated'] ) : 0;

    if ( 'ru' ===  ) {
               = 'WooCommerce Случайный генератор SKU (вразброс) & Поиск: Настройки';
                = 'Автоматическое присвоение случайных 5-значных артикулов вразброс (например: 74921, 18304, 95210) и мгновенный поиск по SKU.';
               = 'Настройки успешно сохранены!';
                = 'Алгоритм генерации артикула';
            = '🎲 Случайные 5-значные числа вразброс (74921, 18304, 95210 — рекомендуется)';
            = '🔢 Порядковые номера по цепочке (00001, 00002, 00003)';
              = 'Количество цифр в артикуле';
         = 'Стандартное значение: 5 цифр (от 10000 до 99999).';
              = 'Префикс артикула (необязательно)';
         = 'Например: ART- или SKU- (результат: ART-74921).';
                = 'Автоматически генерировать и присваивать случайный артикул при публикации нового товара';
              = 'Включить мгновенный поиск товаров по артикулу (на сайте для клиентов и в админке)';
         = 'Пакетная генерация случайных артикулов для всех товаров';
          = 'Кнопка ниже сгенерирует и перезапишет уникальные случайные 5-значные артикулы вразброс для ВСЕХ товаров магазина.';
           = 'Перегенерировать случайные артикулы всех товаров';
             = 'Это действие перезапишет артикулы ВСЕХ товаров магазина случайными кодами. Продолжить?';
             = 'Успешно сгенерировано и обновлено %d уникальных артикулов!';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'WooCommerce Náhodný generátor SKU & Hledání: Nastavení';
                = 'Automatické přiřazování náhodných 5místných číselných kódů SKU a vyhledávání podle SKU.';
               = 'Nastavení bylo úspěšně uloženo!';
                = 'Způsob generování SKU';
            = '🎲 Náhodná 5místná čísla (např. 74921, 18304 — doporučeno)';
            = '🔢 Postupná čísla (00001, 00002)';
              = 'Počet číslic v SKU';
         = 'Standardní hodnota: 5 číslic (10000 až 99999).';
              = 'Prefix SKU (volitelně)';
         = 'Např. ART- (výsledek: ART-74921).';
                = 'Automaticky přiřadit náhodné SKU při vytvoření produktu';
              = 'Aktivovat rychlé vyhledávání podle SKU v obchodě i administraci';
         = 'Hromadné přegenerování náhodných SKU pro všechny produkty';
          = 'Níže uvedené tlačítko přegeneruje náhodná unikátní SKU pro všechny produkty.';
           = 'Přegenerovat náhodná SKU pro všechny produkty';
             = 'Tato akce přepíše SKU všech produktů náhodnými kódy. Pokračovat?';
             = 'Úspěšně přegenerováno %d unikátních SKU kódů!';
            = 'Uložit nastavení';
    } else {
               = 'WooCommerce Random SKU Generator & Search: Settings';
                = 'Automatic assignment of random 5-digit SKUs (e.g. 74921, 18304) and instant SKU search.';
               = 'Settings successfully saved!';
                = 'Generation Algorithm';
            = '🎲 Random non-sequential numbers (e.g. 74921, 18304 — recommended)';
            = '🔢 Sequential numbers (00001, 00002)';
              = 'Number of Digits';
         = 'Default: 5 digits (10000 to 99999).';
              = 'SKU Prefix (Optional)';
         = 'e.g. ART- (renders as ART-74921).';
                = 'Automatically assign random SKU when creating new product';
              = 'Enable instant search by SKU on frontend and admin';
         = 'Storewide Random SKU Regeneration';
          = 'The button below overwrites SKUs for all products with fresh random 5-digit codes.';
           = 'Regenerate Random SKUs for All Products';
             = 'This action overwrites SKUs with new random codes. Continue?';
             = 'Successfully regenerated %d product SKUs!';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🎲 <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>
        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html( sprintf( ,  ) ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_auto_sku_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_auto_sku_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label style="display:block;margin-bottom:8px;font-weight:600;">
                            <input type="radio" name="sku_mode" value="random" <?php checked( ['sku_mode'], 'random' ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <label style="display:block;color:#475569;">
                            <input type="radio" name="sku_mode" value="sequential" <?php checked( ['sku_mode'], 'sequential' ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="sku_digits"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <select name="sku_digits" id="sku_digits">
                            <option value="5" <?php selected( ['sku_digits'], 5 ); ?>>5 цифр (10000 - 99999, стандарт)</option>
                            <option value="6" <?php selected( ['sku_digits'], 6 ); ?>>6 цифр (100000 - 999999)</option>
                            <option value="4" <?php selected( ['sku_digits'], 4 ); ?>>4 цифры (1000 - 9999)</option>
                        </select>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="sku_prefix"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="text" name="sku_prefix" id="sku_prefix" value="<?php echo esc_attr( ['sku_prefix'] ); ?>" class="regular-text" style="max-width:200px;" placeholder="ART-">
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Автоприсвоение</th>
                    <td>
                        <label>
                            <input type="checkbox" name="auto_assign_new" value="1" <?php checked( ['auto_assign_new'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Поиск по артикулу</th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_sku_search" value="1" <?php checked( ['enable_sku_search'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
            </div>
        </form>

        <div style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);margin-top:25px;">
            <h3 style="margin-top:0;color:#0f172a;"><?php echo esc_html(  ); ?></h3>
            <p style="color:#64748b;font-size:14px;"><?php echo esc_html(  ); ?></p>
            <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
                <?php wp_nonce_field( 'wask_regenerate_all', 'wask_nonce' ); ?>
                <input type="hidden" name="action" value="wask_regenerate_all">
                <?php submit_button( , 'delete', 'wask_regenerate', false, array( 'onclick' => "return confirm('" . esc_js(  ) . "');" ) ); ?>
            </form>
        </div>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-auto-sku" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_auto_sku_settings', function() {
    check_admin_referer( 'vladimir_save_auto_sku_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_woocommerce' ) && ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'sku_mode'          => in_array( (string) ( ['sku_mode'] ?? 'random' ), array( 'random', 'sequential' ), true ) ? (string) ['sku_mode'] : 'random',
        'sku_digits'        => in_array( (int) ( ['sku_digits'] ?? 5 ), array( 4, 5, 6 ), true ) ? (int) ['sku_digits'] : 5,
        'sku_prefix'        => sanitize_text_field( (string) ( ['sku_prefix'] ?? '' ) ),
        'auto_assign_new'   => isset( ['auto_assign_new'] ) ? 1 : 0,
        'enable_sku_search' => isset( ['enable_sku_search'] ) ? 1 : 0,
    );

    update_option( '_vladimir_auto_sku_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-auto-sku-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. RANDOM / SEQUENTIAL SKU GENERATOR
// ─────────────────────────────────────────────

function wask_generate_unique_sku() {
    if ( ! function_exists( 'wc_get_product_id_by_sku' ) ) {
        return false;
    }

     = vladimir_auto_sku_get_settings();
         = ['sku_mode'];
       = (int) ['sku_digits'];
       = (string) ['sku_prefix'];

     = (int) pow( 10,  - 1 ); // e.g. 10000
     = (int) ( pow( 10,  ) - 1 ); // e.g. 99999

    if ( 'random' ===  ) {
        // Random 5-digit number generator (non-sequential, e.g. 74921, 18304)
        for (  = 0;  < 300; ++ ) {
             = wp_rand( ,  );
             =  . (string) ;

            if ( ! wc_get_product_id_by_sku(  ) ) {
                return ;
            }
        }
    }

    // Sequential fallback if random space dense or sequential mode selected
     =  . '%0' .  . 'd';
    for (  = 1;  <= ; ++ ) {
         = sprintf( ,  );
        if ( ! wc_get_product_id_by_sku(  ) ) {
            return ;
        }
    }

    return false;
}

function wask_assign_missing_sku(  ) {
    if ( get_post_meta( , '_sku', true ) ) {
        return;
    }

     = wask_generate_unique_sku();
    if (  ) {
        update_post_meta( , '_sku',  );
    }
}

add_action( 'save_post_product', function( , ,  ) {
    if (  || wp_is_post_revision(  ) || ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) ) {
        return;
    }

     = vladimir_auto_sku_get_settings();
    if ( empty( ['auto_assign_new'] ) ) {
        return;
    }

    wask_assign_missing_sku(  );
}, 20, 3 );

// ─────────────────────────────────────────────
// 5. SKU SEARCH (Frontend & Admin)
// ─────────────────────────────────────────────

add_filter( 'posts_search', function( ,  ) {
    global ;

     = vladimir_auto_sku_get_settings();
    if ( empty( ['enable_sku_search'] ) ) {
        return ;
    }

    if ( ! is_admin() && empty( ->query_vars['wc_query'] ) && ! ->is_search() ) {
        return ;
    }

     = ->get( 's' );
    if ( empty(  ) ) {
        return ;
    }

     = ->get_col( ->prepare(
        "SELECT DISTINCT post_id FROM {->postmeta} WHERE meta_key = '_sku' AND meta_value LIKE %s",
        '%' . ->esc_like( trim(  ) ) . '%'
    ) );

    if ( ! empty(  ) ) {
         = ->get_col(
            "SELECT DISTINCT post_parent FROM {->posts} WHERE ID IN (" . implode( ',', array_map( 'absint',  ) ) . ") AND post_parent > 0"
        );
         = array_unique( array_merge( ,  ) );

        if ( ! empty(  ) ) {
             = implode( ',', array_map( 'absint',  ) );
              = str_replace( 'AND (((', "AND (({->posts}.ID IN ({})) OR ((",  );
        }
    }

    return ;
}, 20, 2 );

// ─────────────────────────────────────────────
// 6. STOREWIDE RANDOM REGENERATION HANDLER
// ─────────────────────────────────────────────

add_action( 'admin_post_wask_regenerate_all', function() {
    check_admin_referer( 'wask_regenerate_all', 'wask_nonce' );

    if ( ! current_user_can( 'manage_woocommerce' ) && ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = vladimir_auto_sku_get_settings();
       = (int) ['sku_digits'];
       = (string) ['sku_prefix'];
         = ['sku_mode'];

     = (int) pow( 10,  - 1 );
     = (int) ( pow( 10,  ) - 1 );

     = get_posts(
        array(
            'post_type'           => 'product',
            'post_status'         => 'any',
            'posts_per_page'      => -1,
            'fields'              => 'ids',
            'orderby'             => 'ID',
            'order'               => 'ASC',
            'no_found_rows'       => true,
            'ignore_sticky_posts' => true,
            'suppress_filters'    => true,
        )
    );

     = array();

    foreach (  as  =>  ) {
        if ( 'random' ===  ) {
            // Generate unique random 5-digit in disorder
            do {
                 = wp_rand( ,  );
                 =  . (string) ;
            } while ( isset( [  ] ) );
            [  ] = true;
        } else {
             =  . sprintf( '%0' .  . 'd',  + 1 );
        }

        update_post_meta( , '_sku',  );
    }

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-auto-sku-settings', 'regenerated' => count(  ) ), admin_url( 'options-general.php' ) ) );
    exit;
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
            [  ]['Name']        = 'WooCommerce Авто генератор SKU & Поиск по артикулу (VladiMIR+AI)';
            [  ]['Description'] = 'Автоматически генерирует уникальные случайные 5-значные артикулы вразброс (74921, 18304), включает поиск по артикулу на сайте и в админке, и пакетную генерацию на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'WooCommerce Auto SKU & Hledání podle SKU (VladiMIR+AI)';
            [  ]['Description'] = 'Automaticky generuje náhodná 5místná SKU čísla pro produkty, zapíná vyhledávání podle SKU a hromadnou regeneraci na jedné přehledné stránce.';
        }
    }
    return ;
} );

