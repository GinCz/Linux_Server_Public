<?php
/**
 * Plugin Name: Clean Head Meta & Anti-Fingerprint (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/clean-head-meta
 * Description: Cleans WordPress <head> clutter, removes generator version tags, strips obsolete XML-RPC pingback links and emoji scripts, and adds clean author and designer meta tags (VladiMIR).
 * Version:     2026.09.04
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// 1. Remove WordPress generator version
remove_action( 'wp_head', 'wp_generator' );
add_filter( 'the_generator', '__return_empty_string' );

// 2. Disable XML-RPC pingbacks
add_filter( 'pings_open', '__return_false', 9999 );

// 3. Remove unnecessary header clutter
remove_action( 'wp_head', 'rsd_link' );
remove_action( 'wp_head', 'wlwmanifest_link' );
remove_action( 'wp_head', 'wp_shortlink_wp_head' );
remove_action( 'wp_head', 'rest_output_link_wp_head' );
remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
remove_action( 'template_redirect', 'rest_output_link_header', 11 );

// 4. Disable WordPress emoji scripts and styles
add_action( 'init', function() {
    remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
    remove_action( 'admin_print_scripts', 'print_emoji_detection_script' );
    remove_action( 'wp_print_styles', 'print_emoji_styles' );
    remove_action( 'admin_print_styles', 'print_emoji_styles' );
    remove_filter( 'the_content_feed', 'wp_staticize_emoji' );
    remove_filter( 'comment_text_rss', 'wp_staticize_emoji' );
    remove_filter( 'wp_mail', 'wp_staticize_emoji_for_email' );
} );

// 5. Output author and designer meta tags at top of <head>
add_action( 'wp_head', function() {
    echo "\n<!-- Author & Designer (VladiMIR+AI) -->\n";
    echo '<meta name="author" content="VladiMIR" />' . "\n";
    echo '<meta name="designer" content="VladiMIR" />' . "\n";
}, 0 );

// 6. Clean theme hardcoded pingback/profile tags from HTML output
add_action( 'template_redirect', function() {
    if ( is_admin() ) {
        return;
    }
    ob_start( function( $html ) {
        if ( empty( $html ) || ! is_string( $html ) ) {
            return $html;
        }
        $html = preg_replace( '/\s*<link\s+rel=[\'"]pingback[\'"][^>]*>/i', '', $html );
        $html = preg_replace( '/\s*<link\s+rel=[\'"]profile[\'"][^>]*>/i', '', $html );
        return $html;
    } );
}, 1 );

// Multilingual plugin description (EN / CS / RU)
add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Description'] = 'Очищает мусор в теге &lt;head&gt;, скрывает версию генератора WordPress, удаляет устаревшие ссылки XML-RPC pingback и эмодзи, добавляет чистые метатеги автора и дизайнера (VladiMIR).';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Description'] = 'Vyčistí záhlaví &lt;head&gt; od zbytečného kódu, skryje verzi WordPressu, odstraní zastaralé odkazy pingback a emoji a přidá čisté meta tagy autora a designéra (VladiMIR).';
        }
    }
    return $plugins;
} );
