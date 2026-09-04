<?php
/**
 * Plugin Name: Disable Auto-Update Notification E-mails (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: Отключает назойливые уведомления на почту об автоматических обновлениях ядра WordPress, плагинов и тем. Не нагружает сервер и не создает таблиц в БД.
 * Version:     2026.09.04
 * Author:      VladiMIR + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Отключение писем об автообновлении ядра WordPress
add_filter( 'auto_core_update_send_email', '__return_false' );
add_filter( 'send_core_update_notification_email', '__return_false' );

// Отключение писем об автообновлении плагинов
add_filter( 'auto_plugin_update_send_email', '__return_false' );

// Отключение писем об автообновлении тем
add_filter( 'auto_theme_update_send_email', '__return_false' );
