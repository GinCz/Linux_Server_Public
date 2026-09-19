<?php
/**
 * Uninstall routine for Live Active Users & Visitors Counter (VladiMIR+AI).
 * Triggered only when the plugin is deleted via WordPress Admin.
 *
 * The meta key and the transient prefix below MUST match the ones written by the
 * plugin (_vladimir_last_seen / _voc_g_). They did not match before 2026-09__1.18,
 * so deleting the plugin left every row behind.
 */

if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
    exit;
}

global $wpdb;

// 1. Per-user activity timestamps.
$wpdb->query(
    $wpdb->prepare(
        "DELETE FROM {$wpdb->usermeta} WHERE meta_key = %s",
        '_vladimir_last_seen'
    )
);

// 2. Guest activity transients (value rows and their timeout rows).
$wpdb->query(
    "DELETE FROM {$wpdb->options}
     WHERE option_name LIKE '\_transient\_\_voc\_g\_%'
        OR option_name LIKE '\_transient\_timeout\_\_voc\_g\_%'
        OR option_name IN ( '_transient__voc_stats', '_transient_timeout__voc_stats' )"
);

// 3. Plugin settings.
delete_option( '_vladimir_oc_settings' );
delete_site_option( '_vladimir_oc_settings' );
