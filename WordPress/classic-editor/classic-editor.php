<?php
/**
 * Plugin Name: Classic Editor Ultra-Light (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Включает привычный классический редактор WordPress с вкладками «Визуально» и «Код», полностью отключая тяжелый блочный редактор Gutenberg. 0 нагрузки на сервер.
 * Version:     2026.09.04
 * Author:      VladiMIR + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Отключение редактора блоков Gutenberg для записей и типов записей
add_filter( 'use_block_editor_for_post', '__return_false', 100 );
add_filter( 'use_block_editor_for_post_type', '__return_false', 100 );

// Отключение виджетов на базе блоков Gutenberg (возврат классических виджетов)
add_filter( 'use_widgets_block_editor', '__return_false' );

// Удаление фронтенд-стилей блоков Gutenberg для ускорения загрузки сайта
add_action( 'wp_enqueue_scripts', function() {
    wp_dequeue_style( 'wp-block-library' );
    wp_dequeue_style( 'wp-block-library-theme' );
    wp_dequeue_style( 'global-styles' );
}, 100 );
