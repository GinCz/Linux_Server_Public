<?php
/**
 * Plugin Name: WooCommerce Admin Products Default Sort by Date DESC (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public
 * Description: Гарантирует сортировку списка товаров в админке WooCommerce по умолчанию по дате от самого свежего товара.
 * Version:     2026-09__1.21
 * Author:      Vladimir Bulancev (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wc-admin-default-sort-date
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wc-admin-default-sort-date
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