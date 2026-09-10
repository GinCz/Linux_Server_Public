<?php
/**
 * Plugin Name: WP Allow Safe HTML in Categories (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-allow-html-cats
 * Description: Allows safe post-style HTML in taxonomy descriptions without disabling WordPress XSS filtering.
 * Version:     2026.09.11
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function wahc_sanitize_term_description( $description ) {
    return wp_kses( $description, wp_kses_allowed_html( 'post' ) );
}

remove_filter( 'pre_term_description', 'wp_filter_kses' );
add_filter( 'pre_term_description', 'wahc_sanitize_term_description' );

remove_filter( 'term_description', 'wp_kses_data' );
add_filter( 'term_description', 'wahc_sanitize_term_description' );
