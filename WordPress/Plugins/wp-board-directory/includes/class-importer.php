<?php
/**
 * 1-Click Migration Engine (ACADP & Directorist -> WP Board & Directory)
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class VB_Importer {

    public static function init() {
        if ( defined( 'WP_CLI' ) && WP_CLI ) {
            WP_CLI::add_command( 'vb migrate', [ __CLASS__, 'cli_migrate' ] );
        }
        add_action( 'admin_menu', [ __CLASS__, 'register_admin_page' ] );
        add_action( 'wp_ajax_vb_run_migration', [ __CLASS__, 'ajax_run_migration' ] );
    }

    public static function register_admin_page() {
        add_submenu_page(
            'edit.php?post_type=vb_listing',
            'Миграция данных (1-Click)',
            'Миграция (1-Click)',
            'manage_options',
            'vb-migration',
            [ __CLASS__, 'render_admin_page' ]
        );
    }

    public static function render_admin_page() {
        ?>
        <div class="wrap">
            <h1>Мастер миграции 1-Click: ACADP & Directorist &rarr; WP Board & Directory</h1>
            <p>Этот инструмент переносит все существующие рубрики, объявления, компании, фотографии и контакты в новый единый движок с полным сохранением связей с пользователями.</p>
            
            <div style="background: #fff; padding: 20px; border-radius: 8px; border: 1px solid #ccd0d4; max-width: 800px; margin-top: 20px;">
                <h3>Статистика для импорта:</h3>
                <ul>
                    <li>Категорий ACADP: <strong><?php echo wp_count_terms( [ 'taxonomy' => 'acadp_categories', 'hide_empty' => false ] ); ?></strong></li>
                    <li>Объявлений ACADP: <strong><?php echo wp_count_posts( 'acadp_listings' )->publish ?? 0; ?></strong></li>
                    <li>Компаний Directorist: <strong><?php echo wp_count_posts( 'at_biz_dir' )->publish ?? 0; ?></strong></li>
                </ul>
                <hr>
                <button type="button" id="btn-run-vb-migration" class="button button-primary button-hero">Запустить миграцию 1-Click</button>
                <div id="vb-migration-status" style="margin-top: 15px; font-weight: bold;"></div>
            </div>
        </div>

        <script>
        document.getElementById('btn-run-vb-migration').addEventListener('click', function() {
            var btn = this;
            var statusDiv = document.getElementById('vb-migration-status');
            btn.disabled = true;
            statusDiv.innerHTML = '<span style="color: blue;">⏳ Выполняется миграция данных... Пожалуйста, подождите.</span>';

            fetch(ajaxurl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'vb_run_migration',
                    nonce: '<?php echo wp_create_nonce( 'vb_migration_nonce' ); ?>'
                })
            })
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (data.success) {
                    statusDiv.innerHTML = '<span style="color: green;">✅ ' + data.data.message + '</span>';
                } else {
                    statusDiv.innerHTML = '<span style="color: red;">❌ Ошибка: ' + data.data.message + '</span>';
                    btn.disabled = false;
                }
            })
            .catch(function(err) {
                statusDiv.innerHTML = '<span style="color: red;">❌ Сетевая ошибка при миграции.</span>';
                btn.disabled = false;
            });
        });
        </script>
        <?php
    }

    public static function ajax_run_migration() {
        check_ajax_referer( 'vb_migration_nonce', 'nonce' );
        if ( ! current_user_can( 'manage_options' ) ) {
            wp_send_json_error( [ 'message' => 'Недостаточно прав.' ] );
        }

        $res = self::run_full_migration();
        wp_send_json_success( $res );
    }

    public static function cli_migrate( $args, $assoc_args ) {
        WP_CLI::line( "Starting migration to WP Board & Directory..." );
        $res = self::run_full_migration();
        WP_CLI::success( $res['message'] );
    }

    public static function run_full_migration() {
        global $wpdb;

        // 1. Ensure DB tables exist
        VB_DB::create_tables();

        $cat_map = []; // old_acadp_term_id => new_vb_cat_id
        $imported_cats = 0;
        $imported_ads  = 0;
        $imported_dirs = 0;

        // 2. Migrate ACADP Categories
        if ( taxonomy_exists( 'acadp_categories' ) ) {
            $acadp_terms = get_terms( [
                'taxonomy'   => 'acadp_categories',
                'hide_empty' => false,
                'orderby'    => 'parent',
                'order'      => 'ASC',
            ] );

            if ( ! is_wp_error( $acadp_terms ) ) {
                foreach ( $acadp_terms as $term ) {
                    $parent_id = 0;
                    if ( $term->parent && isset( $cat_map[ $term->parent ] ) ) {
                        $parent_id = $cat_map[ $term->parent ];
                    }

                    $existing = get_term_by( 'slug', $term->slug, 'vb_category' );
                    if ( $existing ) {
                        $new_term_id = $existing->term_id;
                    } else {
                        $inserted = wp_insert_term( $term->name, 'vb_category', [
                            'slug'   => $term->slug,
                            'parent' => $parent_id,
                        ] );
                        $new_term_id = is_array( $inserted ) ? $inserted['term_id'] : 0;
                        if ( $new_term_id ) {
                            $imported_cats++;
                        }
                    }

                    if ( $new_term_id ) {
                        $cat_map[ $term->term_id ] = $new_term_id;
                    }
                }
            }
        }

        // 2b. Migrate ACADP Locations to vb_location
        $loc_map = [];
        if ( taxonomy_exists( 'acadp_locations' ) ) {
            $acadp_loc_terms = get_terms( [
                'taxonomy'   => 'acadp_locations',
                'hide_empty' => false,
                'orderby'    => 'parent',
                'order'      => 'ASC',
            ] );

            if ( ! is_wp_error( $acadp_loc_terms ) ) {
                foreach ( $acadp_loc_terms as $term ) {
                    $parent_id = 0;
                    if ( $term->parent && isset( $loc_map[ $term->parent ] ) ) {
                        $parent_id = $loc_map[ $term->parent ];
                    }

                    $existing = get_term_by( 'slug', $term->slug, 'vb_location' );
                    if ( $existing ) {
                        $new_loc_id = $existing->term_id;
                    } else {
                        $inserted = wp_insert_term( $term->name, 'vb_location', [
                            'slug'   => $term->slug,
                            'parent' => $parent_id,
                        ] );
                        $new_loc_id = is_array( $inserted ) ? $inserted['term_id'] : 0;
                    }

                    if ( $new_loc_id ) {
                        $loc_map[ $term->term_id ] = $new_loc_id;
                    }
                }
            }
        }

        // 3. Migrate ACADP Listings
        $acadp_posts = get_posts( [
            'post_type'      => 'acadp_listings',
            'post_status'    => 'any',
            'posts_per_page' => -1,
        ] );

        $table_index = $wpdb->prefix . 'vb_index';

        foreach ( $acadp_posts as $post ) {
            $existing_new = get_posts( [
                'post_type'      => 'vb_listing',
                'meta_key'       => '_vb_migrated_from_id',
                'meta_value'     => $post->ID,
                'post_status'    => 'any',
                'posts_per_page' => 1,
            ] );

            $new_post_id = ! empty( $existing_new ) ? $existing_new[0]->ID : 0;

            if ( ! $new_post_id ) {
                $new_post_id = wp_insert_post( [
                    'post_title'   => $post->post_title,
                    'post_content' => $post->post_content,
                    'post_status'  => $post->post_status,
                    'post_author'  => $post->post_author,
                    'post_date'    => $post->post_date,
                    'post_type'    => 'vb_listing',
                ] );
                $imported_ads++;
            }

            if ( $new_post_id ) {
                update_post_meta( $new_post_id, '_vb_type', 'classified' );
                update_post_meta( $new_post_id, '_vb_migrated_from_id', $post->ID );

                $old_meta = get_post_meta( $post->ID );
                $price    = floatval( $old_meta['price'][0] ?? 0 );
                $phone    = sanitize_text_field( $old_meta['phone'][0] ?? '' );
                $email    = sanitize_email( $old_meta['email'][0] ?? '' );
                $address  = sanitize_text_field( $old_meta['address'][0] ?? '' );

                update_post_meta( $new_post_id, '_vb_price', $price );
                update_post_meta( $new_post_id, '_vb_phone', $phone );
                update_post_meta( $new_post_id, '_vb_email', $email );
                update_post_meta( $new_post_id, '_vb_address', $address );

                // Thumbnail & Images
                $thumb_id = get_post_thumbnail_id( $post->ID );
                if ( $thumb_id ) {
                    set_post_thumbnail( $new_post_id, $thumb_id );
                }
                if ( ! empty( $old_meta['images'][0] ) ) {
                    update_post_meta( $new_post_id, '_vb_images', maybe_unserialize( $old_meta['images'][0] ) );
                }

                // Safeguard: Re-link attachments post_parent to new post
                $wpdb->update(
                    $wpdb->posts,
                    [ 'post_parent' => $new_post_id ],
                    [ 'post_parent' => $post->ID, 'post_type' => 'attachment' ]
                );

                // Map location from at_biz_dir-location
                $old_dir_locs = wp_get_post_terms( $post->ID, 'at_biz_dir-location', [ 'fields' => 'slugs' ] );
                if ( ! empty( $old_dir_locs ) && ! is_wp_error( $old_dir_locs ) ) {
                    $dir_loc_ids = [];
                    foreach ( $old_dir_locs as $dslug ) {
                        $vterm = get_term_by( 'slug', $dslug, 'vb_location' );
                        if ( $vterm ) {
                            $dir_loc_ids[] = $vterm->term_id;
                        }
                    }
                    if ( ! empty( $dir_loc_ids ) ) {
                        wp_set_post_terms( $new_post_id, $dir_loc_ids, 'vb_location' );
                    }
                }

                // Map category
                $old_terms = wp_get_post_terms( $post->ID, 'acadp_categories', [ 'fields' => 'ids' ] );
                $new_cats  = [];
                if ( ! is_wp_error( $old_terms ) ) {
                    foreach ( $old_terms as $ot_id ) {
                        if ( isset( $cat_map[ $ot_id ] ) ) {
                            $new_cats[] = $cat_map[ $ot_id ];
                        }
                    }
                    if ( ! empty( $new_cats ) ) {
                        wp_set_post_terms( $new_post_id, $new_cats, 'vb_category' );
                    }
                }

                // Map location if acadp_locations exists
                $old_loc_terms = wp_get_post_terms( $post->ID, 'acadp_locations', [ 'fields' => 'slugs' ] );
                if ( ! empty( $old_loc_terms ) && ! is_wp_error( $old_loc_terms ) ) {
                    $new_loc_ids = [];
                    foreach ( $old_loc_terms as $lslug ) {
                        $vterm = get_term_by( 'slug', $lslug, 'vb_location' );
                        if ( $vterm ) {
                            $new_loc_ids[] = $vterm->term_id;
                        }
                    }
                    if ( ! empty( $new_loc_ids ) ) {
                        wp_set_post_terms( $new_post_id, $new_loc_ids, 'vb_location' );
                    }
                }

                $primary_cat = ! empty( $new_cats ) ? $new_cats[0] : 0;

                // Sync with High-Speed Index
                $wpdb->replace(
                    $table_index,
                    [
                        'listing_id'   => $new_post_id,
                        'listing_type' => 'classified',
                        'category_id'  => $primary_cat,
                        'author_id'    => $post->post_author,
                        'price'        => $price,
                        'currency'     => 'CZK',
                        'updated_at'   => current_time( 'mysql' ),
                    ],
                    [ '%d', '%s', '%d', '%d', '%f', '%s', '%s' ]
                );
            }
        }

        // 4. Migrate Directorist Companies
        $dir_posts = get_posts( [
            'post_type'      => 'at_biz_dir',
            'post_status'    => 'any',
            'posts_per_page' => -1,
        ] );

        foreach ( $dir_posts as $post ) {
            $existing_new = get_posts( [
                'post_type'      => 'vb_listing',
                'meta_key'       => '_vb_migrated_from_dir_id',
                'meta_value'     => $post->ID,
                'post_status'    => 'any',
                'posts_per_page' => 1,
            ] );

            $new_post_id = ! empty( $existing_new ) ? $existing_new[0]->ID : 0;

            if ( ! $new_post_id ) {
                $new_post_id = wp_insert_post( [
                    'post_title'   => $post->post_title,
                    'post_content' => $post->post_content,
                    'post_status'  => $post->post_status,
                    'post_author'  => $post->post_author,
                    'post_date'    => $post->post_date,
                    'post_type'    => 'vb_listing',
                ] );
                $imported_dirs++;
            }

            if ( $new_post_id ) {
                update_post_meta( $new_post_id, '_vb_type', 'company' );
                update_post_meta( $new_post_id, '_vb_migrated_from_dir_id', $post->ID );

                $old_meta = get_post_meta( $post->ID );
                update_post_meta( $new_post_id, '_vb_tagline', sanitize_text_field( $old_meta['_tagline'][0] ?? '' ) );
                update_post_meta( $new_post_id, '_vb_address', sanitize_text_field( $old_meta['_address'][0] ?? '' ) );
                update_post_meta( $new_post_id, '_vb_phone', sanitize_text_field( $old_meta['_phone'][0] ?? '' ) );
                update_post_meta( $new_post_id, '_vb_email', sanitize_email( $old_meta['_email'][0] ?? '' ) );
                update_post_meta( $new_post_id, '_vb_website', esc_url_raw( $old_meta['_website'][0] ?? '' ) );

                // Logo & Attachments reparenting
                $logo_id = (int) ( $old_meta['_listing_prv_img'][0] ?? $old_meta['_thumbnail_id'][0] ?? 0 );
                if ( ! $logo_id ) {
                    $atts = get_posts( [ 'post_type' => 'attachment', 'post_parent' => $post->ID, 'posts_per_page' => 1 ] );
                    if ( ! empty( $atts ) ) {
                        $logo_id = $atts[0]->ID;
                    }
                }
                if ( $logo_id ) {
                    set_post_thumbnail( $new_post_id, $logo_id );
                }

                // Safeguard: Re-link attachments post_parent to new post
                $wpdb->update(
                    $wpdb->posts,
                    [ 'post_parent' => $new_post_id ],
                    [ 'post_parent' => $post->ID, 'post_type' => 'attachment' ]
                );

                // Map location from at_biz_dir-location
                $old_dir_locs = wp_get_post_terms( $post->ID, 'at_biz_dir-location', [ 'fields' => 'slugs' ] );
                if ( ! empty( $old_dir_locs ) && ! is_wp_error( $old_dir_locs ) ) {
                    $dir_loc_ids = [];
                    foreach ( $old_dir_locs as $dslug ) {
                        $vterm = get_term_by( 'slug', $dslug, 'vb_location' );
                        if ( $vterm ) {
                            $dir_loc_ids[] = $vterm->term_id;
                        }
                    }
                    if ( ! empty( $dir_loc_ids ) ) {
                        wp_set_post_terms( $new_post_id, $dir_loc_ids, 'vb_location' );
                    }
                }

                // Sync with Index
                $wpdb->replace(
                    $table_index,
                    [
                        'listing_id'   => $new_post_id,
                        'listing_type' => 'company',
                        'category_id'  => 0,
                        'author_id'    => $post->post_author,
                        'price'        => 0.00,
                        'currency'     => 'CZK',
                        'updated_at'   => current_time( 'mysql' ),
                    ],
                    [ '%d', '%s', '%d', '%d', '%f', '%s', '%s' ]
                );
            }
        }

        // 5. Refresh term counts
        $all_vb_terms = get_terms( [ 'taxonomy' => 'vb_category', 'hide_empty' => false, 'fields' => 'ids' ] );
        if ( ! empty( $all_vb_terms ) && ! is_wp_error( $all_vb_terms ) ) {
            wp_update_term_count_now( $all_vb_terms, 'vb_category' );
        }

        return [
            'imported_cats' => $imported_cats,
            'imported_ads'  => $imported_ads,
            'imported_dirs' => $imported_dirs,
            'message'       => sprintf(
                'Миграция завершена! Перенесено рубрик: %d, объявлений: %d, компаний: %d. Все связи с авторами сохранены.',
                $imported_cats,
                $imported_ads,
                $imported_dirs
            ),
        ];
    }
}
