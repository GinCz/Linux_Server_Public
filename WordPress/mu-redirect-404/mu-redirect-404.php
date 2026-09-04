<?php
/**
 * Plugin Name: 301 Redirect 404 to Homepage (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Сверхлёгкий плагин для 301-перенаправления любых несуществующих страниц (404 Not Found) на главную страницу сайта. 0 запросов к БД, 0 логов, максимальная скорость.
 * Version:     2026.09.04
 * Author:      VladiMIR + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

add_action( 'template_redirect', function() {
    if ( is_404() ) {
        wp_safe_redirect( home_url( '/' ), 301 );
        exit;
    }
}, 1 );
