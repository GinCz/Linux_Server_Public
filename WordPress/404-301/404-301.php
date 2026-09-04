<?php
/**
 * Plugin Name: 301 Redirect 404 to Homepage (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Ultra-lightweight WordPress plugin to automatically 301-redirect all 404 Not Found error pages to the homepage. Zero database queries, zero log bloat, maximum performance.
 * Version:     2026.09.04
 * Author:      VladiMIR (GinCz)
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
