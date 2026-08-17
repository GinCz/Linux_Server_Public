<?php
/**
 * export_rychlik_data.php
 * Exports 19 service articles with full metadata and image URLs to JSON
 */
$source_path = '/var/www/andrey-autoservis/data/www/autoservis-rychlik.cz';
require_once $source_path . '/wp-load.php';

$source_posts = get_posts(array(
    'post_type'      => 'post',
    'posts_per_page' => -1,
    'post_status'    => 'publish',
    'tax_query'      => array(
        array(
            'taxonomy' => 'category',
            'field'    => 'slug',
            'terms'    => 'sluzby',
        ),
    ),
));

$data = array();
foreach ($source_posts as $p) {
    $thumb_id = get_post_thumbnail_id($p->ID);
    $thumb_url = $thumb_id ? wp_get_attachment_url($thumb_id) : '';
    
    // Grab all post meta
    $meta = get_post_meta($p->ID);
    
    $data[] = array(
        'title'        => $p->post_title,
        'slug'         => $p->post_name,
        'content'      => $p->post_content,
        'excerpt'      => $p->post_excerpt,
        'date'         => $p->post_date,
        'thumb_url'    => $thumb_url,
        'meta'         => $meta,
    );
}

file_put_contents('/tmp/rychlik_exported_data.json', json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
echo "Successfully exported " . count($data) . " posts to /tmp/rychlik_exported_data.json\n";
