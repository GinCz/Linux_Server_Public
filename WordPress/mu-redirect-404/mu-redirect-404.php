<?php
/**
 * Plugin Name: 301 Redirect 404 to Homepage (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/404-301
 * Description: Ultra-lightweight WordPress plugin to automatically 301-redirect all 404 Not Found error pages to the homepage. Zero database queries, zero log bloat, maximum performance.
 * Version:     2026.09.04
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// 301 Redirect 404 errors to Homepage
add_action( 'template_redirect', function() {
    if ( is_404() ) {
        wp_safe_redirect( home_url( '/' ), 301 );
        exit;
    }
}, 1 );

// Multilingual plugin description (EN / CS / RU)
add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Description'] = 'Сверхлёгкий плагин для автоматического 301-перенаправления всех несуществующих страниц (404 Not Found) на главную страницу сайта. 0 запросов к БД, 0 логов, максимальная скорость.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Description'] = 'Ultralehký plugin pro automatické 301 přesměrování všech neexistujících stránek (chyba 404) na hlavní stránku webu. 0 dotazů do databáze, žádné zatížení logy, maximální rychlost.';
        }
    }
    return $plugins;
} );
