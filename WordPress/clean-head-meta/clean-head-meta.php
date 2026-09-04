<?php
/**
 * Plugin Name: Clean Head Meta & Anti-Fingerprint (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Удаляет следы и подписи WordPress в коде страницы (генератор версии, лишние ссылки rsd/wlwmanifest, эмодзи) и устанавливает чистые метатеги автора (Vladimir).
 * Version:     2026.09.04
 * Author:      VladiMIR + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// 1. Удаление версии и подписи генератора WordPress
remove_action( 'wp_head', 'wp_generator' );
add_filter( 'the_generator', '__return_empty_string' );

// 2. Удаление лишних ссылок и мусора из <head>
remove_action( 'wp_head', 'rsd_link' );
remove_action( 'wp_head', 'wlwmanifest_link' );
remove_action( 'wp_head', 'wp_shortlink_wp_head' );
remove_action( 'wp_head', 'rest_output_link_wp_head' );
remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
remove_action( 'template_redirect', 'rest_output_link_header', 11 );

// 3. Отключение тяжелых скриптов и стилей эмодзи WordPress
add_action( 'init', function() {
    remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
    remove_action( 'admin_print_scripts', 'print_emoji_detection_script' );
    remove_action( 'wp_print_styles', 'print_emoji_styles' );
    remove_action( 'admin_print_styles', 'print_emoji_styles' );
    remove_filter( 'the_content_feed', 'wp_staticize_emoji' );
    remove_filter( 'comment_text_rss', 'wp_staticize_emoji' );
    remove_filter( 'wp_mail', 'wp_staticize_emoji_for_email' );
} );

// 4. Добавление чистых метатегов автора и сайта
add_action( 'wp_head', function() {
    echo "\n<!-- Clean Meta -->\n";
    echo '<meta name="author" content="Vladimir" />' . "\n";
    echo '<meta name="designer" content="Vladimir" />' . "\n";
}, 1 );
