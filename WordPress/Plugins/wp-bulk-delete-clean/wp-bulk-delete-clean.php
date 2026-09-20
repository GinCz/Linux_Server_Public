<?php
/**
 * Plugin Name: WP Bulk Delete Clean (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-bulk-delete-clean
 * Description: Fast, batch-processing bulk deletion tool for Posts, WooCommerce Products, Pages, and Custom Post Types by date, status, or taxonomies without server timeouts or ads.
 * Version:     2026-09__1.37
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-bulk-delete-clean
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-bulk-delete-clean
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

if ( is_admin() ) {
    if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
        require_once __DIR__ . '/vladimir-ai-i18n.php';
    }

    add_action( 'admin_menu', 'vladimir_bulk_delete_add_menu' );
    add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), 'vladimir_bulk_delete_action_links' );
    add_action( 'admin_enqueue_scripts', 'vladimir_bulk_delete_admin_assets' );
}

// ─────────────────────────────────────────────
// 1. MENU & ACTION LINKS
// ─────────────────────────────────────────────

function vladimir_bulk_delete_add_menu() {
    add_management_page(
        'WP Bulk Delete Clean',
        '🗑️ WP Bulk Delete',
        'manage_options',
        'wp-bulk-delete-clean',
        'vladimir_bulk_delete_render_page'
    );
}

function vladimir_bulk_delete_action_links( $links ) {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $tool_label = ( 'ru' === $lang ) ? '🗑️ Очистка записей' : ( ( 'cs' === $lang ) ? '🗑️ Hromadné mazání' : '🗑️ Bulk Delete Tool' );
    $docs_label = ( 'ru' === $lang ) ? 'GitHub ↗' : 'GitHub ↗';

    $tool_link = '<a href="' . esc_url( admin_url( 'tools.php?page=wp-bulk-delete-clean' ) ) . '" style="font-weight:600;color:#2271b1;">' . esc_html( $tool_label ) . '</a>';
    $docs_link = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-bulk-delete-clean" target="_blank" rel="noopener noreferrer">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $tool_link );
    $links[] = $docs_link;
    return $links;
}

function vladimir_bulk_delete_admin_assets( $hook ) {
    if ( 'tools_page_wp-bulk-delete-clean' !== $hook ) {
        return;
    }
    wp_enqueue_script( 'jquery' );
}

// ─────────────────────────────────────────────
// 2. HELPER FUNCTIONS FOR QUERY BUILDING
// ─────────────────────────────────────────────

function vladimir_bulk_delete_build_query_args( $params ) {
    $post_type = sanitize_key( $params['post_type'] ?? 'post' );
    $post_status = sanitize_text_field( $params['post_status'] ?? 'any' );
    $date_type = sanitize_text_field( $params['date_type'] ?? 'all' );
    $date_column = ( sanitize_text_field( $params['date_column'] ?? 'post_date' ) === 'post_modified' ) ? 'post_modified' : 'post_date';
    $taxonomy = sanitize_key( $params['taxonomy'] ?? '' );
    $term_id = intval( $params['term_id'] ?? 0 );

    $args = array(
        'post_type'              => $post_type,
        'post_status'            => ( 'any' === $post_status || empty( $post_status ) ) ? array( 'publish', 'draft', 'pending', 'private', 'trash', 'future' ) : $post_status,
        'fields'                 => 'ids',
        'no_found_rows'          => false,
        'update_post_meta_cache' => false,
        'update_post_term_cache' => false,
        'ignore_sticky_posts'    => true,
    );

    // Specific Status
    if ( 'any' !== $post_status && ! empty( $post_status ) ) {
        $args['post_status'] = $post_status;
    }

    // Taxonomy filter
    if ( ! empty( $taxonomy ) && $term_id > 0 ) {
        $args['tax_query'] = array(
            array(
                'taxonomy' => $taxonomy,
                'field'    => 'term_id',
                'terms'    => $term_id,
            ),
        );
    }

    // Date filters
    $date_query = array();
    $column_key = ( 'post_modified' === $date_column ) ? 'post_modified' : 'post_date';

    if ( 'older_than' === $date_type ) {
        $days = max( 1, intval( $params['days_val'] ?? 30 ) );
        $date_query[] = array(
            'column' => $column_key,
            'before' => gmdate( 'Y-m-d H:i:s', strtotime( "-{$days} days" ) ),
            'inclusive' => true,
        );
    } elseif ( 'newer_than' === $date_type ) {
        $days = max( 1, intval( $params['days_val'] ?? 30 ) );
        $date_query[] = array(
            'column' => $column_key,
            'after'  => gmdate( 'Y-m-d H:i:s', strtotime( "-{$days} days" ) ),
            'inclusive' => true,
        );
    } elseif ( 'before_date' === $date_type && ! empty( $params['date_before'] ) ) {
        $date_before = sanitize_text_field( $params['date_before'] );
        $date_query[] = array(
            'column' => $column_key,
            'before' => $date_before . ' 23:59:59',
            'inclusive' => true,
        );
    } elseif ( 'after_date' === $date_type && ! empty( $params['date_after'] ) ) {
        $date_after = sanitize_text_field( $params['date_after'] );
        $date_query[] = array(
            'column' => $column_key,
            'after'  => $date_after . ' 00:00:00',
            'inclusive' => true,
        );
    } elseif ( 'date_range' === $date_type && ! empty( $params['range_from'] ) && ! empty( $params['range_to'] ) ) {
        $range_from = sanitize_text_field( $params['range_from'] );
        $range_to   = sanitize_text_field( $params['range_to'] );
        $date_query[] = array(
            'column'    => $column_key,
            'after'     => $range_from . ' 00:00:00',
            'before'    => $range_to . ' 23:59:59',
            'inclusive' => true,
        );
    }

    if ( ! empty( $date_query ) ) {
        $args['date_query'] = $date_query;
    }

    return $args;
}

// ─────────────────────────────────────────────
// 3. AJAX: GET COUNT / PREVIEW
// ─────────────────────────────────────────────

add_action( 'wp_ajax_vladimir_bulk_delete_count', 'vladimir_bulk_delete_ajax_count' );
function vladimir_bulk_delete_ajax_count() {
    check_ajax_referer( 'vladimir_bulk_delete_nonce', 'nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( array( 'message' => 'Unauthorized user capability.' ) );
    }

    $params = $_POST['filters'] ?? array();
    $args   = vladimir_bulk_delete_build_query_args( $params );
    $args['posts_per_page'] = 1;

    $query = new WP_Query( $args );
    $total = intval( $query->found_posts );

    wp_send_json_success( array(
        'total' => $total,
    ) );
}

// ─────────────────────────────────────────────
// 4. AJAX: DYNAMIC TAXONOMIES & TERMS
// ─────────────────────────────────────────────

add_action( 'wp_ajax_vladimir_bulk_delete_get_terms', 'vladimir_bulk_delete_ajax_get_terms' );
function vladimir_bulk_delete_ajax_get_terms() {
    check_ajax_referer( 'vladimir_bulk_delete_nonce', 'nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( array( 'message' => 'Unauthorized user capability.' ) );
    }

    $post_type = sanitize_key( $_POST['post_type'] ?? 'post' );
    $taxonomies = get_object_taxonomies( $post_type, 'objects' );

    $result = array();
    foreach ( $taxonomies as $tax_name => $tax_obj ) {
        if ( ! $tax_obj->public && ! $tax_obj->show_ui ) {
            continue;
        }

        $terms = get_terms( array(
            'taxonomy'   => $tax_name,
            'hide_empty' => false,
            'number'     => 500,
        ) );

        if ( ! is_wp_error( $terms ) && ! empty( $terms ) ) {
            $term_list = array();
            foreach ( $terms as $term ) {
                $term_list[] = array(
                    'id'    => $term->term_id,
                    'name'  => $term->name . ' (' . $term->count . ')',
                );
            }
            $result[] = array(
                'name'   => $tax_name,
                'label'  => $tax_obj->label . ' (' . $tax_name . ')',
                'terms'  => $term_list,
            );
        }
    }

    wp_send_json_success( array( 'taxonomies' => $result ) );
}

// ─────────────────────────────────────────────
// 5. AJAX: BATCH DELETION STEP
// ─────────────────────────────────────────────

add_action( 'wp_ajax_vladimir_bulk_delete_step', 'vladimir_bulk_delete_ajax_step' );
function vladimir_bulk_delete_ajax_step() {
    check_ajax_referer( 'vladimir_bulk_delete_nonce', 'nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( array( 'message' => 'Unauthorized user capability.' ) );
    }

    // Set high execution limit if allowed
    @set_time_limit( 120 );

    $params      = $_POST['filters'] ?? array();
    $batch_size  = min( 500, max( 10, intval( $_POST['batch_size'] ?? 100 ) ) );
    $delete_mode = sanitize_text_field( $params['delete_mode'] ?? 'permanent' );
    $del_media   = ! empty( $params['delete_media'] );

    $args = vladimir_bulk_delete_build_query_args( $params );
    $args['posts_per_page'] = $batch_size;
    $args['no_found_rows']  = false;

    $query = new WP_Query( $args );
    $post_ids = $query->posts;
    $total_matching = intval( $query->found_posts );

    if ( empty( $post_ids ) ) {
        wp_send_json_success( array(
            'processed' => 0,
            'deleted'   => 0,
            'remaining' => 0,
            'logs'      => array( 'Done: No more items matching criteria.' ),
        ) );
    }

    $deleted_count = 0;
    $logs = array();

    foreach ( $post_ids as $id ) {
        $id = intval( $id );
        if ( ! $id ) {
            continue;
        }

        $post_title = get_the_title( $id );
        if ( empty( $post_title ) ) {
            $post_title = '#' . $id;
        }

        // Cleanup attached media if requested
        if ( $del_media ) {
            $attachments = get_attached_media( '', $id );
            if ( ! empty( $attachments ) ) {
                foreach ( $attachments as $att ) {
                    wp_delete_attachment( $att->ID, true );
                }
            }
            $thumb_id = get_post_thumbnail_id( $id );
            if ( $thumb_id ) {
                wp_delete_attachment( $thumb_id, true );
            }
        }

        if ( 'trash' === $delete_mode ) {
            $res = wp_trash_post( $id );
            if ( $res ) {
                $deleted_count++;
                $logs[] = "Trashed [ID: {$id}] " . esc_html( mb_substr( $post_title, 0, 40 ) );
            }
        } else {
            // Permanent force delete
            $res = wp_delete_post( $id, true );
            if ( $res ) {
                $deleted_count++;
                $logs[] = "Deleted permanently [ID: {$id}] " . esc_html( mb_substr( $post_title, 0, 40 ) );
            }
        }
    }

    // Calculate remaining
    $remaining = max( 0, $total_matching - $deleted_count );

    wp_send_json_success( array(
        'processed' => count( $post_ids ),
        'deleted'   => $deleted_count,
        'remaining' => $remaining,
        'logs'      => $logs,
    ) );
}

// ─────────────────────────────────────────────
// 6. ADMIN UI PAGE
// ─────────────────────────────────────────────

function vladimir_bulk_delete_render_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Access denied.' );
    }

    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    // Registered public post types
    $post_types = get_post_types( array( 'show_ui' => true ), 'objects' );
    unset( $post_types['revision'], $post_types['nav_menu_item'], $post_types['custom_css'], $post_types['customize_changeset'] );

    $nonce = wp_create_nonce( 'vladimir_bulk_delete_nonce' );
    ?>
    <div class="wrap" style="max-width:1100px;margin-top:20px;">
        <h1 style="font-size:24px;font-weight:700;display:flex;align-items:center;gap:10px;margin-bottom:15px;">
            <span class="dashicons dashicons-trash" style="font-size:30px;width:30px;height:30px;color:#d63638;"></span>
            WP Bulk Delete Clean <span style="font-size:13px;font-weight:normal;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;">VladiMIR+AI✅ Fast & Ad-Free</span>
        </h1>

        <div style="background:#fff;border:1px solid #ccd0d4;box-shadow:0 1px 4px rgba(0,0,0,0.05);border-radius:8px;padding:24px;margin-bottom:20px;">
            <p style="font-size:14px;color:#50575e;margin-top:0;">
                <?php if ( 'ru' === $lang ) : ?>
                    Быстрое массовое удаление постов, страниц, товаров WooCommerce и произвольных типов записей частями через AJAX. Никаких лимитов памяти, зависаний сервера, рекламы или PRO-версий.
                <?php elseif ( 'cs' === $lang ) : ?>
                    Rychlé hromadné mazání příspěvků, stránek, WooCommerce produktů a vlastních typů obsahu po dávkách přes AJAX. Bez limitů paměti, zasekávání serveru, reklam či placených verzí.
                <?php else : ?>
                    Fast batch-processing bulk deletion tool for Posts, Pages, WooCommerce Products, and Custom Post Types via AJAX. Zero memory limits, zero server timeouts, zero ads.
                <?php endif; ?>
            </p>

            <form id="vladimir-bulk-delete-form" onsubmit="return false;">
                <div style="display:grid;grid-template-columns:repeat(auto-fit, minmax(320px, 1fr));gap:20px;margin-top:20px;">
                    
                    <!-- BOX 1: Post Type & Status -->
                    <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:6px;padding:16px;">
                        <h3 style="margin-top:0;font-size:15px;color:#1e293b;border-bottom:1px solid #e2e8f0;padding-bottom:8px;">
                            1. <?php echo ( 'ru' === $lang ) ? 'Тип записи и статус' : ( ( 'cs' === $lang ) ? 'Typ obsahu a stav' : 'Post Type & Status' ); ?>
                        </h3>
                        
                        <label style="font-weight:600;display:block;margin-bottom:5px;">
                            <?php echo ( 'ru' === $lang ) ? 'Тип записи:' : ( ( 'cs' === $lang ) ? 'Typ obsahu:' : 'Post Type:' ); ?>
                        </label>
                        <select id="vbd-post-type" name="post_type" style="width:100%;margin-bottom:15px;">
                            <?php foreach ( $post_types as $slug => $obj ) : 
                                $counts = wp_count_posts( $slug );
                                $total_posts = ( isset($counts->publish) ? $counts->publish : 0 ) + ( isset($counts->draft) ? $counts->draft : 0 ) + ( isset($counts->pending) ? $counts->pending : 0 ) + ( isset($counts->private) ? $counts->private : 0 ) + ( isset($counts->trash) ? $counts->trash : 0 );
                            ?>
                                <option value="<?php echo esc_attr( $slug ); ?>">
                                    <?php echo esc_html( $obj->label ); ?> (<?php echo esc_html( $slug ); ?>) — ~<?php echo intval( $total_posts ); ?> <?php echo ( 'ru' === $lang ) ? 'всего' : 'total'; ?>
                                </option>
                            <?php endforeach; ?>
                        </select>

                        <label style="font-weight:600;display:block;margin-bottom:5px;">
                            <?php echo ( 'ru' === $lang ) ? 'Статус записи:' : ( ( 'cs' === $lang ) ? 'Stav obsahu:' : 'Post Status:' ); ?>
                        </label>
                        <select id="vbd-post-status" name="post_status" style="width:100%;">
                            <option value="any"><?php echo ( 'ru' === $lang ) ? 'Любой статус (Опубликовано, Черновики, Корзина...)' : 'Any Status (Publish, Draft, Trash...)'; ?></option>
                            <option value="publish"><?php echo ( 'ru' === $lang ) ? 'Опубликованные (Publish)' : 'Published'; ?></option>
                            <option value="draft"><?php echo ( 'ru' === $lang ) ? 'Черновики (Draft)' : 'Drafts'; ?></option>
                            <option value="pending"><?php echo ( 'ru' === $lang ) ? 'На утверждении (Pending)' : 'Pending Review'; ?></option>
                            <option value="trash"><?php echo ( 'ru' === $lang ) ? 'В корзине (Trash)' : 'In Trash'; ?></option>
                            <option value="private"><?php echo ( 'ru' === $lang ) ? 'Личные (Private)' : 'Private'; ?></option>
                            <option value="future"><?php echo ( 'ru' === $lang ) ? 'Запланированные (Future)' : 'Scheduled / Future'; ?></option>
                        </select>
                    </div>

                    <!-- BOX 2: Date Filters -->
                    <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:6px;padding:16px;">
                        <h3 style="margin-top:0;font-size:15px;color:#1e293b;border-bottom:1px solid #e2e8f0;padding-bottom:8px;">
                            2. <?php echo ( 'ru' === $lang ) ? 'Фильтрация по дате' : ( ( 'cs' === $lang ) ? 'Filtrování podle data' : 'Date Filters' ); ?>
                        </h3>

                        <label style="font-weight:600;display:block;margin-bottom:5px;">
                            <?php echo ( 'ru' === $lang ) ? 'Условие даты:' : ( ( 'cs' === $lang ) ? 'Podmínka data:' : 'Date Criteria:' ); ?>
                        </label>
                        <select id="vbd-date-type" name="date_type" style="width:100%;margin-bottom:12px;">
                            <option value="all"><?php echo ( 'ru' === $lang ) ? 'Все даты (без ограничений)' : 'All Dates (No date filter)'; ?></option>
                            <option value="older_than"><?php echo ( 'ru' === $lang ) ? 'Старше чем X дней' : 'Older than X days'; ?></option>
                            <option value="newer_than"><?php echo ( 'ru' === $lang ) ? 'Создано за последние X дней' : 'Created in the last X days'; ?></option>
                            <option value="before_date"><?php echo ( 'ru' === $lang ) ? 'Создано ДО конкретной даты' : 'Created BEFORE specific date'; ?></option>
                            <option value="after_date"><?php echo ( 'ru' === $lang ) ? 'Создано ПОСЛЕ конкретной даты' : 'Created AFTER specific date'; ?></option>
                            <option value="date_range"><?php echo ( 'ru' === $lang ) ? 'Диапазон дат (От и До)' : 'Specific Date Range (From - To)'; ?></option>
                        </select>

                        <!-- Dynamic Date Inputs -->
                        <div id="vbd-box-days" style="display:none;margin-bottom:12px;">
                            <label style="font-size:13px;display:block;margin-bottom:4px;"><?php echo ( 'ru' === $lang ) ? 'Количество дней:' : 'Number of days:'; ?></label>
                            <input type="number" id="vbd-days-val" name="days_val" value="30" min="1" max="9999" style="width:100px;">
                        </div>

                        <div id="vbd-box-before" style="display:none;margin-bottom:12px;">
                            <label style="font-size:13px;display:block;margin-bottom:4px;"><?php echo ( 'ru' === $lang ) ? 'Дата (включительно):' : 'Date (inclusive):'; ?></label>
                            <input type="date" id="vbd-date-before" name="date_before" value="<?php echo gmdate('Y-m-d'); ?>" style="width:160px;">
                        </div>

                        <div id="vbd-box-after" style="display:none;margin-bottom:12px;">
                            <label style="font-size:13px;display:block;margin-bottom:4px;"><?php echo ( 'ru' === $lang ) ? 'Дата (включительно):' : 'Date (inclusive):'; ?></label>
                            <input type="date" id="vbd-date-after" name="date_after" value="<?php echo gmdate('Y-m-d', strtotime('-30 days')); ?>" style="width:160px;">
                        </div>

                        <div id="vbd-box-range" style="display:none;margin-bottom:12px;">
                            <div style="display:flex;gap:10px;align-items:center;">
                                <div>
                                    <label style="font-size:12px;display:block;"><?php echo ( 'ru' === $lang ) ? 'От:' : 'From:'; ?></label>
                                    <input type="date" id="vbd-range-from" name="range_from" value="<?php echo gmdate('Y-m-d', strtotime('-60 days')); ?>" style="width:140px;">
                                </div>
                                <div>
                                    <label style="font-size:12px;display:block;"><?php echo ( 'ru' === $lang ) ? 'До:' : 'To:'; ?></label>
                                    <input type="date" id="vbd-range-to" name="range_to" value="<?php echo gmdate('Y-m-d'); ?>" style="width:140px;">
                                </div>
                            </div>
                        </div>

                        <div style="margin-top:10px;">
                            <label style="font-size:12px;color:#64748b;">
                                <input type="radio" name="date_column" value="post_date" checked> <?php echo ( 'ru' === $lang ) ? 'Дата публикации' : 'Published Date'; ?>
                            </label>
                            <label style="font-size:12px;color:#64748b;margin-left:12px;">
                                <input type="radio" name="date_column" value="post_modified"> <?php echo ( 'ru' === $lang ) ? 'Дата изменения' : 'Modified Date'; ?>
                            </label>
                        </div>
                    </div>

                    <!-- BOX 3: Taxonomy & Categories -->
                    <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:6px;padding:16px;">
                        <h3 style="margin-top:0;font-size:15px;color:#1e293b;border-bottom:1px solid #e2e8f0;padding-bottom:8px;">
                            3. <?php echo ( 'ru' === $lang ) ? 'Рубрика / Таксономия' : ( ( 'cs' === $lang ) ? 'Kategorie / Taxonomie' : 'Category / Taxonomy' ); ?>
                        </h3>

                        <label style="font-weight:600;display:block;margin-bottom:5px;">
                            <?php echo ( 'ru' === $lang ) ? 'Фильтр по рубрике / метке:' : 'Taxonomy Filter:'; ?>
                        </label>
                        <select id="vbd-taxonomy-select" name="taxonomy_term" style="width:100%;">
                            <option value=""><?php echo ( 'ru' === $lang ) ? '— Все рубрики и категории —' : '— All Categories & Terms —'; ?></option>
                        </select>
                        <p style="font-size:12px;color:#64748b;margin-top:6px;">
                            <?php echo ( 'ru' === $lang ) ? 'Список таксономий автоматически обновляется при смене типа записи.' : 'Taxonomies refresh dynamically when post type changes.'; ?>
                        </p>
                    </div>

                    <!-- BOX 4: Deletion Options & Speed -->
                    <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:6px;padding:16px;">
                        <h3 style="margin-top:0;font-size:15px;color:#1e293b;border-bottom:1px solid #e2e8f0;padding-bottom:8px;">
                            4. <?php echo ( 'ru' === $lang ) ? 'Режим и размер порции' : ( ( 'cs' === $lang ) ? 'Režim a velikost dávky' : 'Mode & Batch Size' ); ?>
                        </h3>

                        <label style="font-weight:600;display:block;margin-bottom:5px;">
                            <?php echo ( 'ru' === $lang ) ? 'Режим удаления:' : 'Deletion Action:'; ?>
                        </label>
                        <select id="vbd-delete-mode" name="delete_mode" style="width:100%;margin-bottom:12px;">
                            <option value="permanent"><?php echo ( 'ru' === $lang ) ? '🔴 Удалить навсегда (мимо корзины)' : '🔴 Permanently Delete (Bypass Trash)'; ?></option>
                            <option value="trash"><?php echo ( 'ru' === $lang ) ? '🟡 Переместить в корзину (мягкое удаление)' : '🟡 Move to Trash (Soft Delete)'; ?></option>
                        </select>

                        <div style="margin-bottom:12px;">
                            <label style="font-size:13px;cursor:pointer;">
                                <input type="checkbox" id="vbd-delete-media" name="delete_media" value="1">
                                <?php echo ( 'ru' === $lang ) ? 'Удалять прикрепленные медиафайлы/картинки' : 'Delete attached media/images'; ?>
                            </label>
                        </div>

                        <div style="display:flex;gap:15px;align-items:center;">
                            <div>
                                <label style="font-size:12px;display:block;font-weight:600;"><?php echo ( 'ru' === $lang ) ? 'Размер порции:' : 'Batch size:'; ?></label>
                                <select id="vbd-batch-size" name="batch_size" style="width:110px;">
                                    <option value="50">50 items</option>
                                    <option value="100" selected>100 items</option>
                                    <option value="250">250 items</option>
                                    <option value="500">500 items</option>
                                </select>
                            </div>
                            <div>
                                <label style="font-size:12px;display:block;font-weight:600;"><?php echo ( 'ru' === $lang ) ? 'Пауза (мс):' : 'Throttle:'; ?></label>
                                <select id="vbd-throttle" name="throttle" style="width:110px;">
                                    <option value="0">0 ms (Fast)</option>
                                    <option value="100" selected>100 ms</option>
                                    <option value="300">300 ms</option>
                                    <option value="500">500 ms (Gentle)</option>
                                </select>
                            </div>
                        </div>
                    </div>

                </div>

                <!-- Action Controls -->
                <div style="margin-top:24px;padding-top:16px;border-top:1px solid #e2e8f0;display:flex;align-items:center;gap:12px;flex-wrap:wrap;">
                    <button type="button" id="vbd-btn-preview" class="button button-secondary button-large" style="display:flex;align-items:center;gap:6px;">
                        <span class="dashicons dashicons-search" style="margin-top:2px;"></span>
                        <?php echo ( 'ru' === $lang ) ? 'Подсчитать количество (Превью)' : ( ( 'cs' === $lang ) ? 'Spočítat položky (Náhled)' : 'Calculate Count (Preview)' ); ?>
                    </button>

                    <button type="button" id="vbd-btn-start" class="button button-primary button-large" style="background:#d63638;border-color:#b32d2e;display:flex;align-items:center;gap:6px;">
                        <span class="dashicons dashicons-trash" style="margin-top:2px;"></span>
                        <?php echo ( 'ru' === $lang ) ? 'Начать массовое удаление' : ( ( 'cs' === $lang ) ? 'Zahájit hromadné mazání' : 'Start Bulk Deletion' ); ?>
                    </button>

                    <button type="button" id="vbd-btn-pause" class="button button-secondary button-large" style="display:none;">
                        <?php echo ( 'ru' === $lang ) ? 'Пауза' : 'Pause'; ?>
                    </button>

                    <button type="button" id="vbd-btn-stop" class="button button-secondary button-large" style="display:none;color:#b32d2e;">
                        <?php echo ( 'ru' === $lang ) ? 'Остановить' : 'Stop'; ?>
                    </button>

                    <span id="vbd-preview-badge" style="display:none;font-weight:600;font-size:14px;padding:6px 12px;background:#e2e8f0;border-radius:4px;color:#1e293b;"></span>
                </div>
            </form>

            <!-- Progress Area -->
            <div id="vbd-progress-wrapper" style="display:none;margin-top:24px;padding:16px;background:#f1f5f9;border-radius:6px;border:1px solid #cbd5e1;">
                <div style="display:flex;justify-content:space-between;font-weight:600;font-size:14px;margin-bottom:8px;color:#334155;">
                    <span id="vbd-progress-status"><?php echo ( 'ru' === $lang ) ? 'Подготовка к удалению...' : 'Preparing deletion...'; ?></span>
                    <span id="vbd-progress-percent">0%</span>
                </div>

                <div style="width:100%;height:18px;background:#e2e8f0;border-radius:9px;overflow:hidden;margin-bottom:12px;">
                    <div id="vbd-progress-bar" style="width:0%;height:100%;background:#2271b1;transition:width 0.2s ease;"></div>
                </div>

                <div style="display:grid;grid-template-columns:repeat(auto-fit, minmax(140px, 1fr));gap:10px;font-size:13px;color:#475569;margin-bottom:12px;">
                    <div><strong><?php echo ( 'ru' === $lang ) ? 'Всего:' : 'Total:'; ?></strong> <span id="vbd-stat-total">0</span></div>
                    <div><strong><?php echo ( 'ru' === $lang ) ? 'Обработано:' : 'Processed:'; ?></strong> <span id="vbd-stat-processed">0</span></div>
                    <div><strong><?php echo ( 'ru' === $lang ) ? 'Удалено:' : 'Deleted:'; ?></strong> <span id="vbd-stat-deleted" style="color:#d63638;font-weight:700;">0</span></div>
                    <div><strong><?php echo ( 'ru' === $lang ) ? 'Осталось:' : 'Remaining:'; ?></strong> <span id="vbd-stat-remaining">0</span></div>
                </div>

                <!-- Live Log Console -->
                <div style="font-weight:600;font-size:12px;color:#475569;margin-bottom:4px;">
                    <?php echo ( 'ru' === $lang ) ? 'Журнал операций (Live Log):' : 'Live Activity Log:'; ?>
                </div>
                <div id="vbd-log-console" style="height:140px;overflow-y:auto;background:#0f172a;color:#38bdf8;font-family:Consolas,Monaco,monospace;font-size:11px;padding:10px;border-radius:4px;line-height:1.5;">
                    <div>[System ready]</div>
                </div>
            </div>
        </div>
    </div>

    <script>
    jQuery(document).ready(function($) {
        var ajaxUrl = '<?php echo esc_url( admin_url( 'admin-ajax.php' ) ); ?>';
        var nonce   = '<?php echo esc_js( $nonce ); ?>';
        var isRunning = false;
        var isPaused  = false;
        var totalCount = 0;
        var totalDeleted = 0;
        var totalProcessed = 0;

        // Date dropdown toggle
        $('#vbd-date-type').on('change', function() {
            var val = $(this).val();
            $('#vbd-box-days, #vbd-box-before, #vbd-box-after, #vbd-box-range').hide();
            if (val === 'older_than' || val === 'newer_than') {
                $('#vbd-box-days').show();
            } else if (val === 'before_date') {
                $('#vbd-box-before').show();
            } else if (val === 'after_date') {
                $('#vbd-box-after').show();
            } else if (val === 'date_range') {
                $('#vbd-box-range').show();
            }
        }).trigger('change');

        // Refresh Taxonomies on Post Type change
        function loadTaxonomies() {
            var postType = $('#vbd-post-type').val();
            $('#vbd-taxonomy-select').html('<option value="">⏳ <?php echo ( 'ru' === $lang ) ? 'Загрузка категорий...' : 'Loading categories...'; ?></option>');

            $.post(ajaxUrl, {
                action: 'vladimir_bulk_delete_get_terms',
                nonce: nonce,
                post_type: postType
            }, function(res) {
                var select = $('#vbd-taxonomy-select');
                select.empty();
                select.append('<option value="">— <?php echo ( 'ru' === $lang ) ? 'Все рубрики и категории' : 'All Categories & Terms'; ?> —</option>');

                if (res.success && res.data && res.data.taxonomies) {
                    res.data.taxonomies.forEach(function(tax) {
                        var optgroup = $('<optgroup>').attr('label', tax.label);
                        tax.terms.forEach(function(term) {
                            optgroup.append($('<option>').attr('value', tax.name + ':' + term.id).text(term.name));
                        });
                        select.append(optgroup);
                    });
                }
            });
        }

        $('#vbd-post-type').on('change', loadTaxonomies);
        loadTaxonomies();

        function getFilterParams() {
            var taxTerm = $('#vbd-taxonomy-select').val();
            var tax = '', termId = 0;
            if (taxTerm && taxTerm.indexOf(':') !== -1) {
                var parts = taxTerm.split(':');
                tax = parts[0];
                termId = parts[1];
            }

            return {
                post_type: $('#vbd-post-type').val(),
                post_status: $('#vbd-post-status').val(),
                date_type: $('#vbd-date-type').val(),
                date_column: $('input[name="date_column"]:checked').val(),
                days_val: $('#vbd-days-val').val(),
                date_before: $('#vbd-date-before').val(),
                date_after: $('#vbd-date-after').val(),
                range_from: $('#vbd-range-from').val(),
                range_to: $('#vbd-range-to').val(),
                taxonomy: tax,
                term_id: termId,
                delete_mode: $('#vbd-delete-mode').val(),
                delete_media: $('#vbd-delete-media').is(':checked') ? 1 : 0
            };
        }

        function appendLog(msg) {
            var consoleEl = $('#vbd-log-console');
            consoleEl.append('<div>' + msg + '</div>');
            consoleEl.scrollTop(consoleEl[0].scrollHeight);
        }

        // Preview / Count Action
        $('#vbd-btn-preview').on('click', function() {
            var btn = $(this);
            var badge = $('#vbd-preview-badge');
            btn.prop('disabled', true);
            badge.show().text('⏳ <?php echo ( 'ru' === $lang ) ? 'Подсчёт...' : 'Counting...'; ?>').css('background', '#fef08a').css('color', '#854d0e');

            $.post(ajaxUrl, {
                action: 'vladimir_bulk_delete_count',
                nonce: nonce,
                filters: getFilterParams()
            }, function(res) {
                btn.prop('disabled', false);
                if (res.success) {
                    var count = res.data.total;
                    totalCount = count;
                    badge.text('🔍 ' + count.toLocaleString() + ' <?php echo ( 'ru' === $lang ) ? 'записей найдено' : 'items found'; ?>')
                         .css('background', count > 0 ? '#bbf7d0' : '#e2e8f0')
                         .css('color', count > 0 ? '#166534' : '#475569');
                } else {
                    badge.text('Error: ' + (res.data ? res.data.message : 'Unknown')).css('background', '#fecaca').css('color', '#991b1b');
                }
            }).fail(function() {
                btn.prop('disabled', false);
                badge.text('AJAX Network Error').css('background', '#fecaca').css('color', '#991b1b');
            });
        });

        // Start Bulk Delete
        $('#vbd-btn-start').on('click', function() {
            var filters = getFilterParams();
            var modeText = (filters.delete_mode === 'trash') ? 
                '<?php echo ( 'ru' === $lang ) ? 'Переместить в корзину' : 'Move to Trash'; ?>' : 
                '<?php echo ( 'ru' === $lang ) ? 'УДАЛИТЬ НАВСЕГДА' : 'PERMANENTLY DELETE'; ?>';

            var confirmMsg = '<?php echo ( 'ru' === $lang ) ? 'Вы уверены? Действие: ' : 'Are you sure? Action: '; ?>' + modeText + '.\n<?php echo ( 'ru' === $lang ) ? 'Запустить процесс?' : 'Start bulk process?'; ?>';
            if (!confirm(confirmMsg)) {
                return;
            }

            // Init state
            isRunning = true;
            isPaused = false;
            totalDeleted = 0;
            totalProcessed = 0;

            $('#vbd-progress-wrapper').slideDown();
            $('#vbd-btn-start, #vbd-btn-preview').hide();
            $('#vbd-btn-pause, #vbd-btn-stop').show();
            $('#vbd-btn-pause').text('<?php echo ( 'ru' === $lang ) ? 'Пауза' : 'Pause'; ?>');
            $('#vbd-log-console').html('<div>[Process started ' + new Date().toLocaleTimeString() + ']</div>');

            // Count initial total
            $.post(ajaxUrl, {
                action: 'vladimir_bulk_delete_count',
                nonce: nonce,
                filters: filters
            }, function(res) {
                if (res.success) {
                    totalCount = res.data.total;
                    $('#vbd-stat-total').text(totalCount.toLocaleString());
                    $('#vbd-stat-remaining').text(totalCount.toLocaleString());
                    if (totalCount === 0) {
                        appendLog('No items found matching criteria.');
                        finishProcess();
                        return;
                    }
                    runBatchStep();
                } else {
                    appendLog('Error getting count: ' + (res.data ? res.data.message : 'Unknown'));
                    finishProcess();
                }
            }).fail(function() {
                appendLog('Network error during initial count.');
                finishProcess();
            });
        });

        // Batch Execution Loop
        function runBatchStep() {
            if (!isRunning) return;
            if (isPaused) return;

            var filters = getFilterParams();
            var batchSize = parseInt($('#vbd-batch-size').val()) || 100;
            var throttle = parseInt($('#vbd-throttle').val()) || 0;

            $('#vbd-progress-status').text('<?php echo ( 'ru' === $lang ) ? 'Удаление порции...' : 'Deleting batch...'; ?>');

            $.post(ajaxUrl, {
                action: 'vladimir_bulk_delete_step',
                nonce: nonce,
                batch_size: batchSize,
                filters: filters
            }, function(res) {
                if (res.success) {
                    var data = res.data;
                    totalProcessed += data.processed;
                    totalDeleted += data.deleted;

                    if (data.logs && data.logs.length) {
                        data.logs.forEach(function(l) {
                            appendLog(l);
                        });
                    }

                    $('#vbd-stat-processed').text(totalProcessed.toLocaleString());
                    $('#vbd-stat-deleted').text(totalDeleted.toLocaleString());
                    $('#vbd-stat-remaining').text(data.remaining.toLocaleString());

                    var percent = totalCount > 0 ? Math.min(100, Math.round((totalDeleted / totalCount) * 100)) : 100;
                    $('#vbd-progress-bar').css('width', percent + '%');
                    $('#vbd-progress-percent').text(percent + '%');

                    if (data.processed === 0 || data.remaining === 0 || totalDeleted >= totalCount) {
                        $('#vbd-progress-bar').css('width', '100%').css('background', '#16a34a');
                        $('#vbd-progress-percent').text('100%');
                        appendLog('✅ <strong><?php echo ( 'ru' === $lang ) ? 'Массовое удаление успешно завершено!' : 'Bulk deletion completed successfully!'; ?></strong>');
                        finishProcess();
                    } else {
                        if (throttle > 0) {
                            setTimeout(runBatchStep, throttle);
                        } else {
                            runBatchStep();
                        }
                    }
                } else {
                    appendLog('❗ Error in batch: ' + (res.data ? res.data.message : 'Unknown'));
                    finishProcess();
                }
            }).fail(function() {
                appendLog('⚠️ Network timeout/error. Retrying step in 3s...');
                setTimeout(runBatchStep, 3000);
            });
        }

        function finishProcess() {
            isRunning = false;
            isPaused = false;
            $('#vbd-progress-status').text('<?php echo ( 'ru' === $lang ) ? 'Завершено' : 'Completed'; ?>');
            $('#vbd-btn-pause, #vbd-btn-stop').hide();
            $('#vbd-btn-start, #vbd-btn-preview').show();
        }

        // Pause / Resume
        $('#vbd-btn-pause').on('click', function() {
            if (!isRunning) return;
            isPaused = !isPaused;
            if (isPaused) {
                $(this).text('<?php echo ( 'ru' === $lang ) ? 'Продолжить' : 'Resume'; ?>');
                $('#vbd-progress-status').text('<?php echo ( 'ru' === $lang ) ? 'Приостановлено' : 'Paused'; ?>');
                appendLog('[Process paused]');
            } else {
                $(this).text('<?php echo ( 'ru' === $lang ) ? 'Пауза' : 'Pause'; ?>');
                $('#vbd-progress-status').text('<?php echo ( 'ru' === $lang ) ? 'Возобновлено' : 'Resumed'; ?>');
                appendLog('[Process resumed]');
                runBatchStep();
            }
        });

        // Stop
        $('#vbd-btn-stop').on('click', function() {
            if (confirm('<?php echo ( 'ru' === $lang ) ? 'Остановить выполнение процесса?' : 'Stop the deletion process?'; ?>')) {
                appendLog('[Process stopped by user]');
                finishProcess();
            }
        });
    });
    </script>
    <?php
}
