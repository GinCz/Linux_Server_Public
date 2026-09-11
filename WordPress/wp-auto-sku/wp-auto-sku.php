<?php
/**
 * Plugin Name: WP WooCommerce Auto SKU-5 Digits (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-auto-sku
 * Description: Assigns unique five-digit numeric SKUs to new WooCommerce products and provides an intentional full-store regeneration tool.
 * Version:     2026.09.11
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Requires Plugins: woocommerce
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function wask_find_available_sku( $start ) {
    if ( ! function_exists( 'wc_get_product_id_by_sku' ) ) {
        return false;
    }

    $start = max( 1, min( 99999, (int) $start ) );

    for ( $offset = 0; $offset < 99999; $offset++ ) {
        $number = ( ( $start + $offset - 1 ) % 99999 ) + 1;
        $sku    = sprintf( '%05d', $number );

        if ( ! wc_get_product_id_by_sku( $sku ) ) {
            return $sku;
        }
    }

    return false;
}

function wask_assign_missing_sku( $product_id ) {
    if ( get_post_meta( $product_id, '_sku', true ) ) {
        return;
    }

    $sku = wask_find_available_sku( $product_id );

    if ( $sku ) {
        update_post_meta( $product_id, '_sku', $sku );
    }
}

function wask_assign_new_product_sku( $post_id, $post, $update ) {
    if ( $update || wp_is_post_revision( $post_id ) || ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) ) {
        return;
    }

    wask_assign_missing_sku( $post_id );
}
add_action( 'save_post_product', 'wask_assign_new_product_sku', 20, 3 );

function wask_add_tools_page() {
    if ( post_type_exists( 'product' ) ) {
        add_management_page( 'Auto SKU', 'Auto SKU', 'manage_woocommerce', 'wp-auto-sku', 'wask_render_tools_page' );
    }
}
add_action( 'admin_menu', 'wask_add_tools_page' );

function wask_render_tools_page() {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    if ( ! current_user_can( 'manage_woocommerce' ) ) {
        $err = ( 'ru' === $lang ) ? 'У вас нет прав для управления артикулами (SKU).' : ( ( 'cs' === $lang ) ? 'Nemáte oprávnění ke správě kódů produktů (SKU).' : 'You are not allowed to manage SKUs.' );
        wp_die( esc_html( $err ) );
    }

    $regenerated = isset( $_GET['regenerated'] ) ? absint( $_GET['regenerated'] ) : 0;

    if ( 'ru' === $lang ) {
        $t_title     = 'Автогенерация артикулов (Auto SKU)';
        $t_desc1     = 'Новые товары без указанного артикула автоматически получают уникальный 5-значный номер (например: 00001, 00002).';
        $t_desc2     = 'Кнопка ниже принудительно перегенерирует артикулы для ВСЕХ простых товаров в магазине. Вариации не затрагиваются.';
        $t_btn       = 'Перегенерировать артикулы для всех товаров';
        $t_confirm   = 'Это действие перезапишет артикулы ВСЕХ товаров в магазине. Продолжить?';
        $t_success   = 'Успешно обновлено %d артикулов товаров.';
    } elseif ( 'cs' === $lang ) {
        $t_title     = 'Automatické SKU (Auto SKU)';
        $t_desc1     = 'Nové produkty bez zadaného SKU automaticky obdrží unikátní 5místný číselný kód (např. 00001, 00002).';
        $t_desc2     = 'Níže uvedené tlačítko přegeneruje kódy SKU pro VŠECHNY produkty v obchodě. Variace produktů zůstanou nezměněny.';
        $t_btn       = 'Přegenerovat SKU pro všechny produkty';
        $t_confirm   = 'Tato akce přepíše SKU u všech produktů. Pokračovat?';
        $t_success   = 'Úspěšně přegenerováno %d kódů SKU produktů.';
    } else {
        $t_title     = 'Auto SKU';
        $t_desc1     = 'New products without an SKU receive an unused five-digit numeric value automatically.';
        $t_desc2     = 'Regenerate all SKUs overwrites every product SKU. Product variations are not changed.';
        $t_btn       = 'Regenerate All Product SKUs';
        $t_confirm   = 'This overwrites every product SKU. Continue?';
        $t_success   = 'Regenerated %d product SKUs.';
    }
    ?>
    <div class="wrap">
        <h1><?php echo esc_html( $t_title ); ?></h1>
        <p><?php echo esc_html( $t_desc1 ); ?></p>
        <p><strong><?php echo esc_html( $t_desc2 ); ?></strong></p>
        <?php if ( $regenerated ) : ?>
            <div class="notice notice-success"><p><?php echo esc_html( sprintf( $t_success, $regenerated ) ); ?></p></div>
        <?php endif; ?>
        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
            <?php wp_nonce_field( 'wask_regenerate_all', 'wask_nonce' ); ?>
            <input type="hidden" name="action" value="wask_regenerate_all">
            <?php submit_button( $t_btn, 'delete', 'wask_regenerate', false, array( 'onclick' => "return confirm('" . esc_js( $t_confirm ) . "');" ) ); ?>
        </form>
    </div>
    <?php
}

function wask_regenerate_all_skus() {
    check_admin_referer( 'wask_regenerate_all', 'wask_nonce' );

    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    if ( ! current_user_can( 'manage_woocommerce' ) ) {
        $err = ( 'ru' === $lang ) ? 'У вас нет прав для управления артикулами (SKU).' : ( ( 'cs' === $lang ) ? 'Nemáte oprávnění ke správě kódů produktů (SKU).' : 'You are not allowed to manage SKUs.' );
        wp_die( esc_html( $err ) );
    }

    $product_ids = get_posts(
        array(
            'post_type'              => 'product',
            'post_status'            => 'any',
            'posts_per_page'         => -1,
            'fields'                 => 'ids',
            'orderby'                => 'ID',
            'order'                  => 'ASC',
            'no_found_rows'          => true,
            'ignore_sticky_posts'    => true,
            'suppress_filters'       => true,
        )
    );

    if ( count( $product_ids ) > 99999 ) {
        $limit_err = ( 'ru' === $lang ) ? 'Превышен лимит пятизначных номеров артикулов (99999).' : ( ( 'cs' === $lang ) ? 'Byl vyčerpán limit 5místných SKU (99999).' : 'Five-digit SKU space is exhausted.' );
        wp_die( esc_html( $limit_err ) );
    }

    foreach ( $product_ids as $index => $product_id ) {
        update_post_meta( $product_id, '_sku', sprintf( '%05d', $index + 1 ) );
    }

    wp_safe_redirect( add_query_arg( array( 'page' => 'wp-auto-sku', 'regenerated' => count( $product_ids ) ), admin_url( 'tools.php' ) ) );
    exit;
}
add_action( 'admin_post_wask_regenerate_all', 'wask_regenerate_all_skus' );

// Multilingual plugin metadata (EN / CS / RU)
add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WooCommerce Авто-артикул 5 цифр (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Автоматически присваивает новым товарам WooCommerce уникальные 5-значные артикулы (SKU) и предоставляет инструмент полной перегенерации артикулов в разделе «Инструменты».';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WooCommerce Auto SKU 5 číslic (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Automaticky přiřazuje novým produktům WooCommerce unikátní pětimístná čísla SKU a v sekci Nástroje nabízí funkci pro hromadné přegenerování kódů.';
        }
    }
    return $plugins;
} );

