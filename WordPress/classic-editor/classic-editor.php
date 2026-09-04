<?php
/**
 * Plugin Name: Classic Editor Ultra-Light (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Enables the classic WordPress editor interface with Visual and Code (Text) tabs, completely disabling Gutenberg block editor and frontend block assets.
 * Version:     2026.09.04
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Disable Gutenberg block editor for posts and post types
add_filter( 'use_block_editor_for_post', '__return_false', 100 );
add_filter( 'use_block_editor_for_post_type', '__return_false', 100 );

// Disable Gutenberg block widgets
add_filter( 'use_widgets_block_editor', '__return_false' );

// Dequeue block library CSS on frontend for faster page loads
add_action( 'wp_enqueue_scripts', function() {
    wp_dequeue_style( 'wp-block-library' );
    wp_dequeue_style( 'wp-block-library-theme' );
    wp_dequeue_style( 'global-styles' );
}, 100 );
