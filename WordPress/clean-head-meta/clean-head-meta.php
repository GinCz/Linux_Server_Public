<?php
/**
 * Plugin Name: Clean Head Meta & Anti-Fingerprint (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Cleans WordPress <head> clutter, removes generator version tags, disables XML-RPC pingback links and emoji scripts, and adds clean author and designer meta tags (VladiMIR).
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

// 2. Remove pingback and XML-RPC links from headers
add_filter( 'pings_open', '__return_false', 9999 );
add_filter( 'bloginfo_url', function( $output, $show ) {
    if ( 'pingback_url' === $show ) {
        return '';
    }
    return $output;
}, 10, 2 );
add_filter( 'bloginfo', function( $output, $show ) {
    if ( 'pingback_url' === $show ) {
        return '';
    }
    return $output;
}, 10, 2 );

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

// 5. Output clean author and designer meta tags at top of <head>
add_action( 'wp_head', function() {
    echo "\n<!-- Clean Meta Tags (VladiMIR+AI) -->\n";
    echo '<meta name="author" content="VladiMIR" />' . "\n";
    echo '<meta name="designer" content="VladiMIR" />' . "\n";
}, 0 );
