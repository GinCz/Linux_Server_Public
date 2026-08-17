<?php
/**
 * migrate_services_rychlik_to_carbus.php
 * Migrates 19 service posts from autoservis-rychlik.cz to car-bus-autoservice.cz (category: osobni-auta)
 */

$source_path = '/var/www/andrey-autoservis/data/www/autoservis-rychlik.cz';
$target_path = '/var/www/andrey-autoservis/data/www/car-bus-autoservice.cz';

// 1. Load Source WP
require_once $source_path . '/wp-load.php';

$source_category_slug = 'sluzby';
$source_posts = get_posts(array(
    'post_type'      => 'post',
    'posts_per_page' => -1,
    'post_status'    => 'publish',
    'tax_query'      => array(
        array(
            'taxonomy' => 'category',
            'field'    => 'slug',
            'terms'    => $source_category_slug,
        ),
    ),
));

echo "Found " . count($source_posts) . " source posts to migrate.\n";

$data_to_migrate = array();

foreach ($source_posts as $p) {
    $thumbnail_id = get_post_thumbnail_id($p->ID);
    $thumbnail_url = $thumbnail_id ? wp_get_attachment_url($thumbnail_id) : '';
    
    // Get custom post meta (excluding internal wp fields)
    $post_meta = get_post_meta($p->ID);
    
    $data_to_migrate[] = array(
        'title'         => $p->post_title,
        'slug'          => $p->post_name,
        'content'       => $p->post_content,
        'excerpt'       => $p->post_excerpt,
        'date'          => $p->post_date,
        'thumbnail_url' => $thumbnail_url,
        'meta'          => $post_meta,
    );
}

// Unload source WP DB objects
unset($GLOBALS['wpdb']);

// 2. Load Target WP
require_once $target_path . '/wp-load.php';
require_once ABSPATH . 'wp-admin/includes/media.php';
require_once ABSPATH . 'wp-admin/includes/file.php';
require_once ABSPATH . 'wp-admin/includes/image.php';

// Target category: osobni-auta (ID 24)
$target_cat = get_category_by_slug('osobni-auta');
if (!$target_cat) {
    $cat_res = wp_insert_term('Osobní auta', 'category', array('slug' => 'osobni-auta'));
    $target_cat_id = is_array($cat_res) ? $cat_res['term_id'] : 24;
} else {
    $target_cat_id = $target_cat->term_id;
}

echo "Target Category: 'Osobní auta' (ID: {$target_cat_id})\n";

$imported_count = 0;

foreach ($data_to_migrate as $item) {
    echo "--> Migrating: {$item['title']} ({$item['slug']})...\n";
    
    // Check if post with same slug already exists on target
    $existing = get_page_by_path($item['slug'], OBJECT, 'post');
    if ($existing) {
        echo "    Post with slug '{$item['slug']}' already exists (ID: {$existing->ID}). Updating...\n";
        $post_id = $existing->ID;
        wp_update_post(array(
            'ID'           => $post_id,
            'post_title'   => $item['title'],
            'post_content' => $item['content'],
            'post_excerpt' => $item['excerpt'],
            'post_status'  => 'publish',
            'post_category'=> array($target_cat_id),
        ));
    } else {
        $post_id = wp_insert_post(array(
            'post_title'    => $item['title'],
            'post_name'     => $item['slug'],
            'post_content'  => $item['content'],
            'post_excerpt'  => $item['excerpt'],
            'post_status'   => 'publish',
            'post_type'     => 'post',
            'post_category' => array($target_cat_id),
            'post_date'     => $item['date'],
        ));
    }

    if (is_wp_error($post_id)) {
        echo "    ❌ Error creating post: " . $post_id->get_error_message() . "\n";
        continue;
    }

    // Copy Featured Image if exists
    if (!empty($item['thumbnail_url'])) {
        // Download image into target media library
        $att_id = media_sideload_image($item['thumbnail_url'], $post_id, $item['title'], 'id');
        if (!is_wp_error($att_id)) {
            set_post_thumbnail($post_id, $att_id);
            echo "    🖼️ Featured image attached (Attachment ID: {$att_id}).\n";
        } else {
            echo "    ⚠️ Warning attaching featured image: " . $att_id->get_error_message() . "\n";
        }
    }

    // Replace internal links in content
    $content = $item['content'];
    $content = str_replace('https://autoservis-rychlik.cz', 'https://car-bus-autoservice.cz', $content);
    $content = str_replace('http://autoservis-rychlik.cz', 'https://car-bus-autoservice.cz', $content);
    
    // Update post with cleaned content
    wp_update_post(array(
        'ID'           => $post_id,
        'post_content' => $content,
    ));

    $imported_count++;
    echo "    ✅ Successfully migrated (Post ID: {$post_id}).\n";
}

echo "\n============================================\n";
echo "Migration complete! Total posts migrated: {$imported_count}\n";
echo "============================================\n";
