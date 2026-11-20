<?php
/**
 * Database Schema & Table Manager
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class VB_DB {

    /**
     * Create or update custom database tables
     */
    public static function create_tables() {
        global $wpdb;

        $charset_collate = $wpdb->get_charset_collate();
        require_once ABSPATH . 'wp-admin/includes/upgrade.php';

        // 1. Ratings & Reviews Table (with strict anti-fraud unique keys)
        $table_ratings = $wpdb->prefix . 'vb_ratings';
        $sql_ratings = "CREATE TABLE {$table_ratings} (
            id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            target_type VARCHAR(20) NOT NULL, -- 'listing' or 'author'
            target_id BIGINT(20) UNSIGNED NOT NULL,
            user_id BIGINT(20) UNSIGNED NOT NULL,
            rating TINYINT(2) NOT NULL, -- 1 to 5, or 1 (+1) / -1 (-1)
            review_title VARCHAR(255) DEFAULT '',
            review_content TEXT,
            ip_address VARCHAR(45) NOT NULL,
            status VARCHAR(20) DEFAULT 'approved',
            created_at DATETIME NOT NULL,
            PRIMARY KEY  (id),
            UNIQUE KEY unique_user_vote (target_type, target_id, user_id),
            KEY target_lookup (target_type, target_id),
            KEY user_votes (user_id),
            KEY ip_lookup (ip_address)
        ) {$charset_collate};";

        dbDelta( $sql_ratings );

        // 2. High-Speed Index Table for Instant Search & Filters
        $table_index = $wpdb->prefix . 'vb_index';
        $sql_index = "CREATE TABLE {$table_index} (
            listing_id BIGINT(20) UNSIGNED NOT NULL,
            listing_type VARCHAR(20) NOT NULL DEFAULT 'classified', -- 'classified' or 'company'
            category_id BIGINT(20) UNSIGNED NOT NULL DEFAULT 0,
            location_id BIGINT(20) UNSIGNED NOT NULL DEFAULT 0,
            author_id BIGINT(20) UNSIGNED NOT NULL,
            price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
            currency VARCHAR(5) NOT NULL DEFAULT 'CZK',
            is_featured TINYINT(1) NOT NULL DEFAULT 0,
            is_urgent TINYINT(1) NOT NULL DEFAULT 0,
            likes_count INT(11) NOT NULL DEFAULT 0,
            dislikes_count INT(11) NOT NULL DEFAULT 0,
            rating_score INT(11) NOT NULL DEFAULT 0,
            rating_count INT(11) NOT NULL DEFAULT 0,
            views_count INT(11) NOT NULL DEFAULT 0,
            phone_reveals INT(11) NOT NULL DEFAULT 0,
            updated_at DATETIME NOT NULL,
            PRIMARY KEY  (listing_id),
            KEY type_idx (listing_type),
            KEY cat_idx (category_id),
            KEY loc_idx (location_id),
            KEY author_idx (author_id),
            KEY price_idx (price),
            KEY featured_idx (is_featured),
            KEY rating_idx (rating_score)
        ) {$charset_collate};";

        dbDelta( $sql_index );
    }
}
