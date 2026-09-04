<?php
/**
 * Plugin Name: Smart Image Resizer 1600px 95% (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Automatically resizes uploaded high-resolution images to a maximum of 1600x1600px while maintaining crisp 95% JPEG quality. Zero configuration, replaces heavy image optimization plugins.
 * Version:     2026.09.04
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Set JPEG compression quality to 95%
add_filter( 'jpeg_quality', function() {
    return 95;
} );
add_filter( 'wp_editor_set_quality', function() {
    return 95;
} );

// Intercept original image upload and resize to max 1600x1600
add_filter( 'wp_handle_upload', function( $file ) {
    $allowed_types = array( 'image/jpeg', 'image/png', 'image/webp' );
    if ( ! isset( $file['type'] ) || ! in_array( $file['type'], $allowed_types, true ) ) {
        return $file;
    }

    $filepath = $file['file'];
    $editor = wp_get_image_editor( $filepath );

    if ( is_wp_error( $editor ) ) {
        return $file;
    }

    $size = $editor->get_size();
    $max_dim = 1600;

    // Resize proportionally if dimensions exceed 1600px
    if ( $size['width'] > $max_dim || $size['height'] > $max_dim ) {
        $editor->set_quality( 95 );
        $resized = $editor->resize( $max_dim, $max_dim, false );

        if ( ! is_wp_error( $resized ) ) {
            $editor->save( $filepath );
        }
    }

    return $file;
} );
