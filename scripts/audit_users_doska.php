<?php
require_once __DIR__ . '/wp-load.php';

global $wpdb;
$admins = $wpdb->get_col("SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = 'wp_capabilities' AND meta_value LIKE '%administrator%'");
$authors = $wpdb->get_col("SELECT DISTINCT post_author FROM {$wpdb->posts} WHERE post_author > 0");
$keep = array_unique(array_merge($admins, $authors));

$users = $wpdb->get_results("SELECT ID, user_login, user_email, user_registered FROM {$wpdb->users}");

$to_delete = array();
foreach ($users as $u) {
    if (!in_array($u->ID, $keep)) {
        $to_delete[] = $u;
    }
}

echo "TOTAL USERS: " . count($users) . "\n";
echo "ACTIVE AUTHORS / ADMINS: " . count($keep) . "\n";
echo "ZERO-POST USERS TO DELETE: " . count($to_delete) . "\n\n";

echo "SAMPLE OF ZERO-POST USERS:\n";
for ($i = 0; $i < min(40, count($to_delete)); $i++) {
    $u = $to_delete[$i];
    echo "ID: {$u->ID} | Login: {$u->user_login} | Email: {$u->user_email} | Reg: {$u->user_registered}\n";
}
