<?php
/**
 * Plugin Name: WooCommerce Admin Products Default Sort by Date DESC
 * Plugin URI:  https://github.com/GinCz/Secret_Privat
 * Description: Гарантирует сортировку списка товаров в админке WooCommerce по умолчанию по дате от самого свежего товара.
 * Version:     1.0.0
 * Author:      Vladimir Bulancev (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

add_action( 'pre_get_posts', function( $query ) {
    if ( ! is_admin() || ! $query->is_main_query() ) {
        return;
    }

    $screen    = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
    $post_type = $screen ? $screen->post_type : ( isset( $_GET['post_type'] ) ? sanitize_key( $_GET['post_type'] ) : '' );
    $is_edit   = ( $screen && 'edit' === $screen->base ) || ( isset( $GLOBALS['pagenow'] ) && 'edit.php' === $GLOBALS['pagenow'] );

    if ( $is_edit && 'product' === $post_type ) {
        // Если колонка сортировки явно не задана пользователем в адресной строке
        if ( empty( $_GET['orderby'] ) ) {
            $query->set( 'orderby', 'date' );
            $query->set( 'order', 'DESC' );
        }
    }
}, 999 );