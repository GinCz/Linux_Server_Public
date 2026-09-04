<?php
/**
 * Plugin Name: Smart Image Resizer 1600px 95% (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Автоматически уменьшает загружаемые фото до максимального размера 1600x1600px с высоким качеством 95% (без мыла и потери детализации). Заменяет тяжелые плагины оптимизации картинок.
 * Version:     2026.09.04
 * Author:      VladiMIR + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Установка качества сжатия JPEG в WordPress на 95%
add_filter( 'jpeg_quality', function() {
    return 95;
} );
add_filter( 'wp_editor_set_quality', function() {
    return 95;
} );

// Перехват загрузки оригинального изображения и ресайз до 1600x1600
add_filter( 'wp_handle_upload', function( $file ) {
    // Проверяем тип файла
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

    // Если ширина или высота больше 1600px — пропорционально масштабируем
    if ( $size['width'] > $max_dim || $size['height'] > $max_dim ) {
        $editor->set_quality( 95 );
        $resized = $editor->resize( $max_dim, $max_dim, false );

        if ( ! is_wp_error( $resized ) ) {
            $editor->save( $filepath );
        }
    }

    return $file;
} );
