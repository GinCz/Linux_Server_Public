<?php
/**
 * import_carbus_data.php
 * Imports articles from /tmp/rychlik_exported_data.json into car-bus-autoservice.cz under 'osobni-auta'
 */
$target_path = '/var/www/andrey-autoservis/data/www/car-bus-autoservice.cz';
require_once $target_path . '/wp-load.php';
require_once ABSPATH . 'wp-admin/includes/media.php';
require_once ABSPATH . 'wp-admin/includes/file.php';
require_once ABSPATH . 'wp-admin/includes/image.php';

$json_file = '/tmp/rychlik_exported_data.json';
if (!file_exists($json_file)) {
    die("Export file $json_file not found!\n");
}

$data = json_decode(file_get_contents($json_file), true);
echo "Loaded " . count($data) . " items to import.\n";

$target_cat = get_category_by_slug('osobni-auta');
$target_cat_id = $target_cat ? $target_cat->term_id : 24;

echo "Target category: 'Osobní auta' (ID: $target_cat_id)\n";

$count = 0;
foreach ($data as $item) {
    echo "--> Importing: {$item['title']} ({$item['slug']})...\n";
    
    // Check if post with same slug already exists
    $existing = get_page_by_path($item['slug'], OBJECT, 'post');
    if ($existing) {
        $post_id = $existing->ID;
        wp_update_post(array(
            'ID'            => $post_id,
            'post_title'    => $item['title'],
            'post_content'  => $item['content'],
            'post_excerpt'  => $item['excerpt'],
            'post_status'   => 'publish',
            'post_category' => array($target_cat_id),
        ));
        echo "    Updated existing post (ID: $post_id).\n";
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
        echo "    Created new post (ID: $post_id).\n";
    }

    if (is_wp_error($post_id)) {
        echo "    ❌ Error: " . $post_id->get_error_message() . "\n";
        continue;
    }

    // Process Featured Image
    if (!empty($item['thumb_url'])) {
        $att_id = media_sideload_image($item['thumb_url'], $post_id, $item['title'], 'id');
        if (!is_wp_error($att_id)) {
            set_post_thumbnail($post_id, $att_id);
            echo "    🖼️ Sideloaded featured image (Attachment ID: $att_id).\n";
        } else {
            echo "    ⚠️ Warning attaching featured image: " . $att_id->get_error_message() . "\n";
        }
    }

    // Replace internal links in content
    $content = $item['content'];
    $content = str_replace('https://autoservis-rychlik.cz', 'https://car-bus-autoservice.cz', $content);
    $content = str_replace('http://autoservis-rychlik.cz', 'https://car-bus-autoservice.cz', $content);
    
    // Save updated content
    wp_update_post(array(
        'ID'           => $post_id,
        'post_content' => $content,
    ));

    $count++;
    echo "    ✅ Done.\n";
}

echo "\n============================================\n";
echo "Successfully imported $count articles!\n";
echo "============================================\n";
