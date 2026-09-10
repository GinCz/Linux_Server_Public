<?php
/**
 * Plugin Name: WP Auto SKU 5 Digits (VladiMIR+AI)
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
    if ( ! current_user_can( 'manage_woocommerce' ) ) {
        wp_die( esc_html__( 'You are not allowed to manage SKUs.', 'wp-auto-sku' ) );
    }

    $regenerated = isset( $_GET['regenerated'] ) ? absint( $_GET['regenerated'] ) : 0;
    ?>
    <div class="wrap">
        <h1><?php esc_html_e( 'Auto SKU', 'wp-auto-sku' ); ?></h1>
        <p><?php esc_html_e( 'New products without an SKU receive an unused five-digit numeric value automatically.', 'wp-auto-sku' ); ?></p>
        <p><strong><?php esc_html_e( 'Regenerate all SKUs overwrites every product SKU. Product variations are not changed.', 'wp-auto-sku' ); ?></strong></p>
        <?php if ( $regenerated ) : ?>
            <div class="notice notice-success"><p><?php echo esc_html( sprintf( __( 'Regenerated %d product SKUs.', 'wp-auto-sku' ), $regenerated ) ); ?></p></div>
        <?php endif; ?>
        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
            <?php wp_nonce_field( 'wask_regenerate_all', 'wask_nonce' ); ?>
            <input type="hidden" name="action" value="wask_regenerate_all">
            <?php submit_button( __( 'Regenerate All Product SKUs', 'wp-auto-sku' ), 'delete', 'wask_regenerate', false, array( 'onclick' => "return confirm('This overwrites every product SKU. Continue?');" ) ); ?>
        </form>
    </div>
    <?php
}

function wask_regenerate_all_skus() {
    check_admin_referer( 'wask_regenerate_all', 'wask_nonce' );

    if ( ! current_user_can( 'manage_woocommerce' ) ) {
        wp_die( esc_html__( 'You are not allowed to manage SKUs.', 'wp-auto-sku' ) );
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
        wp_die( esc_html__( 'Five-digit SKU space is exhausted.', 'wp-auto-sku' ) );
    }

    foreach ( $product_ids as $index => $product_id ) {
        update_post_meta( $product_id, '_sku', sprintf( '%05d', $index + 1 ) );
    }

    wp_safe_redirect( add_query_arg( array( 'page' => 'wp-auto-sku', 'regenerated' => count( $product_ids ) ), admin_url( 'tools.php' ) ) );
    exit;
}
add_action( 'admin_post_wask_regenerate_all', 'wask_regenerate_all_skus' );
