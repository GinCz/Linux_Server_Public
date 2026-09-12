<?php
/**
 * Uninstall routine for WP Online Active Users (VladiMIR+AI)
 * Triggered only when plugin is deleted via WordPress Admin.
 */

if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
    exit;
}

global $wpdb;

// 1. Delete all user activity timestamps
$wpdb->query(
    $wpdb->prepare(
        "DELETE FROM {$wpdb->usermeta} WHERE meta_key = %s",
        '_vladimir_last_active'
    )
);

// 2. Delete all guest counter transients and timeouts
$wpdb->query(
    "DELETE FROM {$wpdb->options} 
     WHERE option_name LIKE '_transient__vladimir_guest_%' 
        OR option_name LIKE '_transient_timeout__vladimir_guest_%'"
);

// 3. Clear scheduled cron hook
wp_clear_scheduled_hook( 'wp_oc_daily_cleanup' );