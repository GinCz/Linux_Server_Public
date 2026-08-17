<?php
require_once __DIR__ . '/wp-load.php';

global $wpdb;

// 1. Get all Administrator IDs
$admins = $wpdb->get_col("SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'wp_capabilities' AND meta_value LIKE '%administrator%'");

// 2. Get all Authors with any posts, pages, or listings
$authors = $wpdb->get_col("SELECT DISTINCT post_author FROM {$wpdb->posts} WHERE post_author > 0");

// 3. Keep admins, authors, and specific system accounts
$keep = array_unique(array_merge($admins, $authors));

// 4. Find all users to delete
$users = $wpdb->get_results("SELECT ID, user_login, user_email FROM {$wpdb->users}");

$deleted_count = 0;
foreach ($users as $u) {
    if (!in_array($u->ID, $keep)) {
        // Never delete user ID 1 or current admin
        if ($u->ID == 1) continue;
        
        // Clean delete user and all usermeta
        wp_delete_user($u->ID);
        $deleted_count++;
    }
}

echo "Successfully deleted {$deleted_count} zero-post / bot users.\n";
echo "Remaining active users/authors/admins: " . (count($users) - $deleted_count) . "\n";
