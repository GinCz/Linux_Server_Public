<?php
/**
 * Plugin Name: Disable Auto-Update Notification E-mails (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/disable-update-emails
 * Description: Disables annoying automatic core, plugin, and theme update notification emails sent to site administrators and users. Zero database queries and zero configuration required.
 * Version:     2026.09.04
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Disable core update emails
add_filter( 'auto_core_update_send_email', '__return_false' );
add_filter( 'send_core_update_notification_email', '__return_false' );

// Disable plugin update emails
add_filter( 'auto_plugin_update_send_email', '__return_false' );

// Disable theme update emails
add_filter( 'auto_theme_update_send_email', '__return_false' );

// Multilingual plugin description (EN / CS / RU)
add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Description'] = 'Отключает назойливые уведомления на почту об автоматических обновлениях ядра WordPress, плагинов и тем. Не нагружает сервер и не создает таблиц в БД.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Description'] = 'Vypíná e-mailová oznámení o automatických aktualizacích jádra WordPressu, pluginů a šablon odesílaná správcům a uživatelům. 0 dotazů do databáze.';
        }
    }
    return $plugins;
} );
