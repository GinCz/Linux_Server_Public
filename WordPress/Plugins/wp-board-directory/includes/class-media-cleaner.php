<?php
/**
 * Media Cleaner & Auto-Purge Engine
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class VB_Media_Cleaner {

    public static function init() {
        // 1. Auto-delete attached media when an ad or company is deleted
        add_action( 'before_delete_post', [ __CLASS__, 'cleanup_post_media' ] );

        // 2. Admin menu
        add_action( 'admin_menu', [ __CLASS__, 'register_admin_menu' ] );

        // 3. Admin POST action for deleting orphans
        add_action( 'admin_post_vb_delete_orphan_media', [ __CLASS__, 'handle_delete_orphans' ] );

        // 4. WP-CLI
        if ( defined( 'WP_CLI' ) && WP_CLI ) {
            WP_CLI::add_command( 'vb clean-media', [ __CLASS__, 'cli_clean_media' ] );
        }
    }

    /**
     * Automatically clean all attached photos when a listing or company is deleted
     */
    public static function cleanup_post_media( $post_id ) {
        $post_type = get_post_type( $post_id );
        if ( 'vb_listing' !== $post_type && 'acadp_listings' !== $post_type && 'at_biz_dir' !== $post_type ) {
            return;
        }

        // 1. Featured Image
        $thumb_id = get_post_thumbnail_id( $post_id );
        if ( $thumb_id ) {
            wp_delete_attachment( $thumb_id, true );
        }

        // 2. Gallery images from _vb_images, images, _gallery_images, _atbdp_gallery, _listing_images
        $meta_keys = [ '_vb_images', 'images', '_gallery_images', '_listing_images', '_atbdp_gallery', '_atbdp_header_image' ];
        foreach ( $meta_keys as $mk ) {
            $raw_val = get_post_meta( $post_id, $mk, true );
            if ( ! empty( $raw_val ) ) {
                $items = maybe_unserialize( $raw_val );
                if ( is_string( $items ) ) {
                    $items = explode( ',', $items );
                }
                if ( is_array( $items ) ) {
                    foreach ( $items as $img_id ) {
                        if ( is_numeric( $img_id ) && $img_id > 0 ) {
                            wp_delete_attachment( absint( $img_id ), true );
                        }
                    }
                } elseif ( is_numeric( $items ) && $items > 0 ) {
                    wp_delete_attachment( absint( $items ), true );
                }
            }
        }

        // 3. Any attachments with post_parent = $post_id
        $children = get_posts( [
            'post_type'      => 'attachment',
            'post_parent'    => $post_id,
            'posts_per_page' => -1,
            'post_status'    => 'inherit',
            'fields'         => 'ids',
        ] );
        if ( ! empty( $children ) ) {
            foreach ( $children as $child_id ) {
                wp_delete_attachment( $child_id, true );
            }
        }
    }

    /**
     * Register Admin Page under 'Доска и Фирмы'
     */
    public static function register_admin_menu() {
        add_submenu_page(
            'edit.php?post_type=vb_listing',
            'Очистка картинок (Media Cleaner)',
            'Очистка картинок',
            'manage_options',
            'vb-media-cleaner',
            [ __CLASS__, 'render_admin_page' ]
        );
    }

    /**
     * Scan and find all orphan attachments
     */
    public static function get_orphan_attachments() {
        global $wpdb;

        // 1. All thumbnail IDs
        $thumb_ids = $wpdb->get_col( "SELECT DISTINCT meta_value FROM {$wpdb->postmeta} WHERE meta_key = '_thumbnail_id' AND meta_value > 0" );

        // 2. All gallery images from _vb_images, images, _gallery_images, _listing_images, _atbdp_gallery, _atbdp_header_image
        $gallery_meta = $wpdb->get_col( "SELECT meta_value FROM {$wpdb->postmeta} WHERE meta_key IN ('_vb_images', 'images', '_gallery_images', '_listing_images', '_atbdp_gallery', '_atbdp_header_image')" );
        $gallery_ids = [];
        foreach ( $gallery_meta as $val ) {
            $arr = maybe_unserialize( $val );
            if ( is_string( $arr ) && strpos( $arr, ',' ) !== false ) {
                $arr = explode( ',', $arr );
            }
            if ( is_array( $arr ) ) {
                foreach ( $arr as $id ) {
                    if ( is_numeric( $id ) && $id > 0 ) {
                        $gallery_ids[] = (int) $id;
                    }
                }
            } elseif ( is_numeric( $arr ) && $arr > 0 ) {
                $gallery_ids[] = (int) $arr;
            }
        }

        // 3. Attachments with an active parent post
        $parent_ids = $wpdb->get_col( "SELECT a.ID FROM {$wpdb->posts} a JOIN {$wpdb->posts} p ON a.post_parent = p.ID WHERE a.post_type = 'attachment' AND a.post_parent > 0 AND p.post_type != 'attachment'" );

        // 4. Site icon, custom logo, Flatsome logos and all theme mods
        $theme_mod_ids = array_filter( [
            (int) get_option( 'site_icon' ),
            (int) get_theme_mod( 'custom_logo' ),
            (int) get_theme_mod( 'site_logo' ),
            (int) get_theme_mod( 'site_logo_dark' ),
            (int) get_theme_mod( 'site_logo_sticky' ),
        ] );

        $theme_mod_options = $wpdb->get_col( "SELECT option_value FROM {$wpdb->options} WHERE option_name LIKE 'theme_mods_%'" );
        foreach ( $theme_mod_options as $tmo ) {
            $mods = maybe_unserialize( $tmo );
            if ( is_array( $mods ) ) {
                foreach ( $mods as $k => $v ) {
                    if ( is_numeric( $v ) && (int) $v > 0 ) {
                        if ( preg_match( '/(logo|icon|header|image|bg|banner|img)/i', (string) $k ) ) {
                            $theme_mod_ids[] = (int) $v;
                        }
                    }
                }
            }
        }
        $special_ids = array_unique( array_filter( $theme_mod_ids ) );

        // Merge all used IDs
        $used_ids = array_unique( array_merge( $thumb_ids, $gallery_ids, $parent_ids, $special_ids ) );
        $used_ids = array_map( 'absint', $used_ids );
        $used_lookup = array_flip( $used_ids );

        // All attachments
        $all_attachments = $wpdb->get_results( "SELECT ID, post_title, post_date, guid FROM {$wpdb->posts} WHERE post_type = 'attachment'", ARRAY_A );

        $orphans = [];
        foreach ( $all_attachments as $att ) {
            $id = (int) $att['ID'];
            if ( ! isset( $used_lookup[ $id ] ) ) {
                $file = get_attached_file( $id );
                $size = ( $file && file_exists( $file ) ) ? filesize( $file ) : 0;
                $orphans[] = [
                    'id'    => $id,
                    'title' => $att['post_title'] ?: basename( $file ?: $att['guid'] ),
                    'date'  => $att['post_date'],
                    'file'  => $file,
                    'size'  => $size,
                    'url'   => wp_get_attachment_thumb_url( $id ) ?: $att['guid'],
                ];
            }
        }

        return $orphans;
    }

    /**
     * Delete orphan attachments permanently
     */
    public static function delete_orphans( $ids = [] ) {
        if ( empty( $ids ) ) {
            $orphans = self::get_orphan_attachments();
            $ids = wp_list_pluck( $orphans, 'id' );
        }

        $count = 0;
        $freed_bytes = 0;

        foreach ( $ids as $id ) {
            $file = get_attached_file( $id );
            if ( $file && file_exists( $file ) ) {
                $freed_bytes += filesize( $file );
            }
            wp_delete_attachment( $id, true );
            $count++;
        }

        return [ 'count' => $count, 'freed_bytes' => $freed_bytes ];
    }

    /**
     * Handle Admin POST Delete Action
     */
    public static function handle_delete_orphans() {
        if ( ! current_user_can( 'manage_options' ) ) {
            wp_die( 'Недостаточно прав.' );
        }

        check_admin_referer( 'vb_media_cleaner_action', 'vb_cleaner_nonce' );

        $ids = [];
        if ( ! empty( $_POST['item_ids'] ) && is_array( $_POST['item_ids'] ) ) {
            $ids = array_map( 'absint', $_POST['item_ids'] );
        }

        $result = self::delete_orphans( $ids );

        $redirect = add_query_arg( [
            'page'    => 'vb-media-cleaner',
            'deleted' => $result['count'],
            'freed'   => round( $result['freed_bytes'] / ( 1024 * 1024 ), 2 ),
        ], admin_url( 'edit.php?post_type=vb_listing' ) );

        wp_safe_redirect( $redirect );
        exit;
    }

    /**
     * WP-CLI Command: wp vb clean-media [--dry-run]
     */
    public static function cli_clean_media( $args, $assoc_args ) {
        WP_CLI::line( "Scanning for orphan media files..." );
        $orphans = self::get_orphan_attachments();
        $total = count( $orphans );

        if ( $total === 0 ) {
            WP_CLI::success( "No orphan images found! Everything is clean." );
            return;
        }

        $total_bytes = array_sum( wp_list_pluck( $orphans, 'size' ) );
        $mb = round( $total_bytes / ( 1024 * 1024 ), 2 );

        if ( isset( $assoc_args['dry-run'] ) ) {
            WP_CLI::success( "[DRY-RUN] Found {$total} orphan images occupying {$mb} MB. Run without --dry-run to delete." );
            return;
        }

        WP_CLI::line( "Found {$total} orphan images. Cleaning up..." );
        $result = self::delete_orphans();
        $freed_mb = round( $result['freed_bytes'] / ( 1024 * 1024 ), 2 );
        WP_CLI::success( "Deleted {$result['count']} orphan images. Freed {$freed_mb} MB of disk space!" );
    }

    /**
     * Render Admin Cleaner Page
     */
    public static function render_admin_page() {
        // If universal standalone WP_Media_Cleaner_App is active, delegate directly to it
        if ( class_exists( 'WP_Media_Cleaner_App' ) ) {
            WP_Media_Cleaner_App::instance()->render_admin_page();
            return;
        }

        global $wpdb;

        $total_media = (int) $wpdb->get_var( "SELECT count(*) FROM {$wpdb->posts} WHERE post_type = 'attachment'" );
        $orphans     = self::get_orphan_attachments();
        $orphan_count = count( $orphans );

        $total_orphan_size = array_sum( wp_list_pluck( $orphans, 'size' ) );
        $orphan_mb = round( $total_orphan_size / ( 1024 * 1024 ), 2 );
        $used_media = max( 0, $total_media - $orphan_count );

        $deleted_n = isset( $_GET['deleted'] ) ? absint( $_GET['deleted'] ) : 0;
        $freed_mb  = isset( $_GET['freed'] ) ? floatval( $_GET['freed'] ) : 0;
        ?>
        <div class="wrap">
            <h1>🧹 Очистка неиспользуемых картинок (Media Cleaner)</h1>
            <p>Этот инструмент находит все изображения и файлы в медиабиблиотеке, которые <strong>не привязаны ни к одному объявлению, ни к одной компании, ни к страницам сайта</strong>, и позволяет безопасно удалить их вместе с физическими файлами с сервера.</p>

            <?php if ( $deleted_n > 0 ) : ?>
                <div class="notice notice-success is-dismissible" style="padding:12px; font-size:15px;">
                    ✅ <strong>Очистка завершена:</strong> Успешно удалено <strong><?php echo $deleted_n; ?></strong> неиспользуемых файлов. Освобождено <strong><?php echo $freed_mb; ?> МБ</strong> дискового пространства!
                </div>
            <?php endif; ?>

            <!-- Stats Bar -->
            <div style="display:flex; gap:16px; margin:20px 0; flex-wrap:wrap;">
                <div style="background:#fff; border:1px solid #ccd0d4; border-radius:8px; padding:16px 20px; flex:1; min-width:180px;">
                    <div style="font-size:13px; color:#64748b;">Всего файлов в Media</div>
                    <div style="font-size:26px; font-weight:700; color:#1e293b;"><?php echo $total_media; ?></div>
                </div>
                <div style="background:#fff; border:1px solid #ccd0d4; border-radius:8px; padding:16px 20px; flex:1; min-width:180px;">
                    <div style="font-size:13px; color:#16a34a;">Используются на сайте</div>
                    <div style="font-size:26px; font-weight:700; color:#16a34a;"><?php echo $used_media; ?></div>
                </div>
                <div style="background:#fff; border:1px solid #ccd0d4; border-radius:8px; padding:16px 20px; flex:1; min-width:180px;">
                    <div style="font-size:13px; color:#dc2626;">Неиспользуемые (Мусор)</div>
                    <div style="font-size:26px; font-weight:700; color:#dc2626;"><?php echo $orphan_count; ?></div>
                </div>
                <div style="background:#fff; border:1px solid #ccd0d4; border-radius:8px; padding:16px 20px; flex:1; min-width:180px;">
                    <div style="font-size:13px; color:#b45309;">Занимаемый объем</div>
                    <div style="font-size:26px; font-weight:700; color:#b45309;"><?php echo $orphan_mb; ?> МБ</div>
                </div>
            </div>

            <!-- Auto-Purge Status Alert -->
            <div style="background:#ecfdf5; border:1px solid #a7f3d0; border-radius:8px; padding:12px 16px; margin-bottom:20px; color:#065f46;">
                🛡️ <strong>Автоматическая очистка активна:</strong> При каждом удалении объявления или компании в личном кабинете или через админку — все прикрепленные к ним фотографии автоматически и навсегда удаляются с сервера!
            </div>

            <?php if ( $orphan_count === 0 ) : ?>
                <div style="background:#fff; border:1px solid #ccd0d4; border-radius:8px; padding:30px; text-align:center;">
                    <h3 style="color:#16a34a; margin:0 0 10px 0;">🎉 Отлично! На сайте нет лишних картинок.</h3>
                    <p style="color:#64748b; margin:0;">Все загруженные изображения используются в объявлениях или на страницах.</p>
                </div>
            <?php else : ?>
                <form method="POST" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" onsubmit="return confirm('Вы действительно хотите удалить выбранные картинки? Файлы будут безвозвратно удалены с сервера.');">
                    <?php wp_nonce_field( 'vb_media_cleaner_action', 'vb_cleaner_nonce' ); ?>
                    <input type="hidden" name="action" value="vb_delete_orphan_media">

                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px; background:#fff; padding:12px 16px; border:1px solid #ccd0d4; border-radius:8px;">
                        <div>
                            <label style="font-weight:600; cursor:pointer;">
                                <input type="checkbox" id="vb-chk-all-orphans" onclick="document.querySelectorAll('.vb-orphan-chk').forEach(c => c.checked = this.checked);">
                                Выбрать все неиспользуемые (<?php echo $orphan_count; ?>)
                            </label>
                        </div>
                        <div>
                            <button type="submit" class="button button-primary button-large" style="background:#dc2626; border-color:#b91c1c;">
                                🗑️ Удалить все выбранные картинки (<?php echo $orphan_count; ?> шт. / <?php echo $orphan_mb; ?> МБ)
                            </button>
                        </div>
                    </div>

                    <table class="wp-list-table widefat fixed striped">
                        <thead>
                            <tr>
                                <th style="width:40px;"><input type="checkbox" onclick="document.getElementById('vb-chk-all-orphans').click();"></th>
                                <th style="width:70px;">Превью</th>
                                <th>Имя файла / Название</th>
                                <th>Размер</th>
                                <th>Дата загрузки</th>
                                <th>Действие</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ( array_slice( $orphans, 0, 100 ) as $item ) : ?>
                                <tr>
                                    <td>
                                        <input type="checkbox" name="item_ids[]" value="<?php echo esc_attr( $item['id'] ); ?>" class="vb-orphan-chk" checked>
                                    </td>
                                    <td>
                                        <img src="<?php echo esc_url( $item['url'] ); ?>" style="width:50px; height:40px; object-fit:cover; border-radius:4px; border:1px solid #e2e8f0;">
                                    </td>
                                    <td>
                                        <strong><?php echo esc_html( $item['title'] ); ?></strong>
                                        <div style="font-size:11px; color:#64748b;"><?php echo esc_html( $item['file'] ); ?></div>
                                    </td>
                                    <td><?php echo round( $item['size'] / 1024, 1 ); ?> КБ</td>
                                    <td><?php echo esc_html( $item['date'] ); ?></td>
                                    <td>
                                        <button type="button" class="button button-small" style="color:#dc2626;" onclick="if(confirm('Удалить эту картинку?')){document.querySelectorAll('.vb-orphan-chk').forEach(c => c.checked=false); document.getElementById('chk-<?php echo $item['id']; ?>').checked=true; this.closest('form').submit();}">Удалить</button>
                                        <input type="checkbox" id="chk-<?php echo $item['id']; ?>" name="item_ids[]" value="<?php echo esc_attr( $item['id'] ); ?>" style="display:none;">
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                    <?php if ( $orphan_count > 100 ) : ?>
                        <p style="margin-top:12px; color:#64748b;"><em>Показано первые 100 файлов из <?php echo $orphan_count; ?>. При нажатии «Удалить» удалятся все отмеченные.</em></p>
                    <?php endif; ?>
                </form>
            <?php endif; ?>
        </div>
        <?php
    }
}
