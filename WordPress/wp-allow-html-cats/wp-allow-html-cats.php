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

// Multilingual plugin metadata (EN / CS / RU)
add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Разрешить безопасный HTML в категориях (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Разрешает использование безопасного HTML-форматирования (ссылки, списки, выделения) в описаниях рубрик и таксономий без отключения XSS-фильтрации WordPress.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Povolit bezpečné HTML v kategoriích (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Umožňuje používat bezpečné HTML formátování (odkazy, seznamy, zvýraznění) v popisech kategorií a taxonomií bez vypnutí XSS ochrany WordPressu.';
        }
    }
    return $plugins;
} );

