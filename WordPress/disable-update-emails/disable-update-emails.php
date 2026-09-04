<?php
/**
 * Plugin Name: Disable Auto-Update Notification E-mails (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
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
