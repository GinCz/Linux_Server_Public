<?php
/**
 * Shortcodes & Frontend Views
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class VB_Shortcodes {

    public static function init() {
        add_shortcode( 'vb_categories', [ __CLASS__, 'render_categories' ] );
        add_shortcode( 'acadp_categories', [ __CLASS__, 'render_categories' ] );

        add_shortcode( 'vb_listings', [ __CLASS__, 'render_listings' ] );
        add_shortcode( 'acadp_listings', [ __CLASS__, 'render_listings' ] );

        add_shortcode( 'vb_companies', [ __CLASS__, 'render_companies' ] );
        add_shortcode( 'directorist_all_listings', [ __CLASS__, 'render_companies' ] );

        add_shortcode( 'vb_dashboard', [ __CLASS__, 'render_dashboard' ] );
        add_shortcode( 'acadp_user_dashboard', [ __CLASS__, 'render_dashboard' ] );
        add_shortcode( 'directorist_user_dashboard', [ __CLASS__, 'render_dashboard' ] );

        add_shortcode( 'vb_submit', [ __CLASS__, 'render_submit_form' ] );
        add_shortcode( 'acadp_listing_form', [ __CLASS__, 'render_submit_form' ] );
        add_shortcode( 'directorist_add_listing', [ __CLASS__, 'render_submit_form' ] );

        // Search shortcodes
        add_shortcode( 'vb_search', [ __CLASS__, 'render_search' ] );
        add_shortcode( 'acadp_search_form', [ __CLASS__, 'render_search' ] );
        add_shortcode( 'acadp_search', [ __CLASS__, 'render_search' ] );

        // Handle profile save POST
        add_action( 'init', [ __CLASS__, 'handle_profile_save' ] );

        // Handle dashboard actions (bulk delete, bulk renewals, single delete)
        add_action( 'init', [ __CLASS__, 'handle_dashboard_actions' ] );

        // Handle listing submission (admin-post)
        add_action( 'admin_post_vb_handle_submit_listing', [ __CLASS__, 'handle_listing_submission' ] );
        add_action( 'admin_post_nopriv_vb_handle_submit_listing', [ __CLASS__, 'handle_listing_submission' ] );

        // Template routing (Single ad, single company, category archive)
        add_filter( 'template_include', [ __CLASS__, 'route_templates' ] );

        // 301 Redirect for legacy /all-listings/ to /company/
        add_action( 'template_redirect', [ __CLASS__, 'handle_legacy_redirects' ] );

        // Hook into ACADP categories template to balance rows & dividers
        add_filter( 'acadp_get_template', [ __CLASS__, 'filter_acadp_template' ], 10, 3 );
        add_filter( 'acadp_load_template', [ __CLASS__, 'filter_acadp_load_template' ], 10, 2 );
    }

    /**
     * Handle user profile save from Unified Dashboard
     */
    public static function handle_profile_save() {
        if ( 'POST' !== $_SERVER['REQUEST_METHOD'] || empty( $_POST['vb_action'] ) || 'save_profile' !== $_POST['vb_action'] ) {
            return;
        }

        if ( ! is_user_logged_in() || ! check_admin_referer( 'vb_save_profile_action', 'vb_profile_nonce' ) ) {
            return;
        }

        $uid = get_current_user_id();

        $display_name = sanitize_text_field( $_POST['display_name'] ?? '' );
        $first_name   = sanitize_text_field( $_POST['first_name'] ?? '' );
        $phone        = sanitize_text_field( $_POST['phone'] ?? '' );
        $city         = sanitize_text_field( $_POST['city'] ?? '' );
        $company      = sanitize_text_field( $_POST['company'] ?? '' );
        $bio          = sanitize_textarea_field( $_POST['description'] ?? '' );

        if ( ! empty( $display_name ) ) {
            wp_update_user( [
                'ID'           => $uid,
                'display_name' => $display_name,
                'first_name'   => $first_name ?: $display_name,
                'description'  => $bio,
            ] );
        }

        // Phone meta (update across all known keys for full compatibility)
        update_user_meta( $uid, 'phone', $phone );
        update_user_meta( $uid, 'acadp_phone', $phone );
        update_user_meta( $uid, 'atbdp_phone', $phone );
        update_user_meta( $uid, 'billing_phone', $phone );

        // City & Address
        update_user_meta( $uid, 'address', $city );
        update_user_meta( $uid, 'user_city', $city );

        // Company name
        update_user_meta( $uid, 'company_name', $company );
        update_user_meta( $uid, 'user_company', $company );

        $referer = wp_get_referer() ?: home_url( '/kabinet/' );
        $redirect = add_query_arg( [ 'saved' => '1', 'tab' => 'profile' ], $referer );
        wp_safe_redirect( $redirect );
        exit;
    }

    /**
     * Handle Dashboard Actions: Single Delete, Bulk Delete, Bulk Renewals
     */
    public static function handle_dashboard_actions() {
        if ( ! is_user_logged_in() ) {
            return;
        }

        $current_user_id = get_current_user_id();

        // 1. Single Delete Action (GET)
        if ( isset( $_GET['vb_action'] ) && 'delete_item' === $_GET['vb_action'] && ! empty( $_GET['item_id'] ) ) {
            $item_id = absint( $_GET['item_id'] );
            $tab     = sanitize_key( $_GET['tab'] ?? 'ads' );

            if ( ! wp_verify_nonce( $_GET['_wpnonce'] ?? '', 'vb_delete_item_' . $item_id ) ) {
                wp_die( 'Ошибка безопасности (неверный nonce).' );
            }

            $post = get_post( $item_id );
            if ( ! $post || ( (int) $post->post_author !== $current_user_id && ! current_user_can( 'manage_options' ) ) ) {
                wp_die( 'У вас нет прав на удаление этой записи.' );
            }

            wp_delete_post( $item_id, true );

            $redirect_url = remove_query_arg( [ 'vb_action', 'item_id', '_wpnonce' ] );
            $redirect_url = add_query_arg( [ 'tab' => $tab, 'deleted' => 1 ], $redirect_url );
            wp_safe_redirect( $redirect_url );
            exit;
        }

        // 2. Bulk Actions (POST)
        if ( 'POST' === $_SERVER['REQUEST_METHOD'] && ! empty( $_POST['vb_action'] ) && 'dash_bulk_action' === $_POST['vb_action'] ) {
            if ( ! check_admin_referer( 'vb_dash_bulk_action', 'vb_dash_nonce' ) ) {
                wp_die( 'Ошибка безопасности (неверный nonce).' );
            }

            $tab      = sanitize_key( $_POST['tab'] ?? 'ads' );
            $bulk_op  = sanitize_key( $_POST['bulk_op'] ?? '' );
            $item_ids = array_map( 'absint', (array) ( $_POST['item_ids'] ?? [] ) );

            $base_redirect = wp_get_referer() ?: home_url( '/kabinet/' );

            if ( empty( $item_ids ) || empty( $bulk_op ) ) {
                wp_safe_redirect( add_query_arg( [ 'tab' => $tab ], $base_redirect ) );
                exit;
            }

            $count = 0;

            if ( 'delete' === $bulk_op ) {
                foreach ( $item_ids as $id ) {
                    $post = get_post( $id );
                    if ( $post && ( (int) $post->post_author === $current_user_id || current_user_can( 'manage_options' ) ) ) {
                        wp_delete_post( $id, true );
                        $count++;
                    }
                }
                $redirect = add_query_arg( [ 'tab' => $tab, 'deleted' => $count ], $base_redirect );
                wp_safe_redirect( $redirect );
                exit;
            }

            // Renewal intervals
            $renew_intervals = [
                'renew_1m' => [ '+1 month', '1 месяц' ],
                'renew_3m' => [ '+3 months', '3 месяца' ],
                'renew_6m' => [ '+6 months', '6 месяцев' ],
                'renew_1y' => [ '+1 year', '1 год' ],
            ];

            if ( isset( $renew_intervals[ $bulk_op ] ) ) {
                list( $interval_str, $interval_label ) = $renew_intervals[ $bulk_op ];
                $now_ts = current_time( 'timestamp' );

                foreach ( $item_ids as $id ) {
                    $post = get_post( $id );
                    if ( ! $post || ( (int) $post->post_author !== $current_user_id && ! current_user_can( 'manage_options' ) ) ) {
                        continue;
                    }

                    // Check existing expiry date
                    $curr_expiry = get_post_meta( $id, 'expiry_date', true ) ?: get_post_meta( $id, '_expiry_date', true ) ?: get_post_meta( $id, '_vb_expiry_date', true );
                    $base_ts = $now_ts;
                    if ( $curr_expiry ) {
                        $curr_ts = strtotime( $curr_expiry );
                        if ( $curr_ts && $curr_ts > $now_ts ) {
                            $base_ts = $curr_ts;
                        }
                    }

                    $new_expiry_ts  = strtotime( $interval_str, $base_ts );
                    $new_expiry_str = date( 'Y-m-d H:i:s', $new_expiry_ts );

                    update_post_meta( $id, 'expiry_date', $new_expiry_str );
                    update_post_meta( $id, '_expiry_date', $new_expiry_str );
                    update_post_meta( $id, '_vb_expiry_date', $new_expiry_str );

                    // Refresh post date and ensure published status
                    wp_update_post( [
                        'ID'            => $id,
                        'post_status'   => 'publish',
                        'post_date'     => current_time( 'mysql' ),
                        'post_date_gmt' => current_time( 'mysql', 1 ),
                    ] );

                    $count++;
                }

                $redirect = add_query_arg( [
                    'tab'      => $tab,
                    'renewed'  => $count,
                    'interval' => rawurlencode( $interval_label ),
                ], $base_redirect );
                wp_safe_redirect( $redirect );
                exit;
            }
        }
    }

    /**
     * Handle legacy 301 redirects
     */
    public static function handle_legacy_redirects() {
        $req = trim( $_SERVER['REQUEST_URI'] ?? '', '/' );
        if ( 'all-listings' === $req || preg_match( '#^all-listings/?$#', $req ) ) {
            wp_safe_redirect( home_url( '/company/' ), 301 );
            exit;
        }
    }

    /**
     * Route single listing and category templates
     */
    public static function route_templates( $template ) {
        if ( is_singular( 'vb_listing' ) ) {
            $custom = VB_BOARD_PATH . 'templates/single-listing.php';
            if ( file_exists( $custom ) ) {
                return $custom;
            }
        }

        if ( is_tax( 'vb_category' ) || is_tax( 'vb_location' ) ) {
            $custom = VB_BOARD_PATH . 'templates/taxonomy-category.php';
            if ( file_exists( $custom ) ) {
                return $custom;
            }
        }

        return $template;
    }

    /**
     * Render Frontend Submission Form
     */
    public static function render_submit_form( $atts = [] ) {
        ob_start();
        include VB_BOARD_PATH . 'templates/submit-form.php';
        return ob_get_clean();
    }

    /**
     * Handle Frontend Ad / Company Submission POST
     */
    public static function handle_listing_submission() {
        if ( ! check_admin_referer( 'vb_submit_listing_action', 'vb_submit_nonce' ) ) {
            wp_die( 'Ошибка безопасности (неверный nonce).' );
        }

        // Verify Cloudflare Turnstile if available
        if ( function_exists( 'cfturnstile_check' ) && ! cfturnstile_check() ) {
            $referer = wp_get_referer() ?: home_url( '/new/' );
            wp_safe_redirect( add_query_arg( [ 'error' => rawurlencode( 'Пожалуйста, подтвердите проверку Turnstile.' ) ], $referer ) );
            exit;
        }

        $title        = sanitize_text_field( $_POST['title'] ?? '' );
        if ( mb_strlen( $title, 'UTF-8' ) > 100 ) {
            $title = mb_substr( $title, 0, 100, 'UTF-8' );
        }
        $category_id  = absint( $_POST['category_id'] ?? 0 );
        $location_val = sanitize_text_field( $_POST['location_id'] ?? '' );
        $price        = floatval( $_POST['price'] ?? 0 );
        $phone        = sanitize_text_field( $_POST['phone'] ?? '' );
        $whatsapp     = sanitize_text_field( $_POST['whatsapp'] ?? '' );
        $telegram     = sanitize_text_field( $_POST['telegram'] ?? '' );
        $email        = sanitize_email( $_POST['email'] ?? '' );
        $address      = sanitize_text_field( $_POST['address'] ?? '' );
        $description  = wp_kses_post( $_POST['description'] ?? '' );
        $type         = ( isset( $_POST['listing_type'] ) && 'company' === $_POST['listing_type'] ) ? 'company' : 'classified';

        if ( empty( $title ) || empty( $description ) ) {
            $referer = wp_get_referer() ?: home_url( '/new/' );
            wp_safe_redirect( add_query_arg( [ 'error' => rawurlencode( 'Заполните обязательные поля.' ) ], $referer ) );
            exit;
        }

        $author_id = get_current_user_id() ?: 1;

        // Enforce limit: maximum 10 listings per account/email in one category
        if ( $category_id > 0 && ! current_user_can( 'manage_options' ) ) {
            $author_filter = ( $author_id > 1 ) ? [ 'author' => $author_id ] : [];
            $existing_user_listings = get_posts( array_merge( [
                'post_type'      => 'vb_listing',
                'post_status'    => [ 'publish', 'draft', 'pending' ],
                'posts_per_page' => -1,
                'fields'         => 'ids',
                'tax_query'      => [
                    [
                        'taxonomy' => 'vb_category',
                        'field'    => 'term_id',
                        'terms'    => $category_id,
                    ],
                ],
            ], $author_filter ) );

            $existing_count = count( $existing_user_listings );
            if ( $author_id === 1 && ! empty( $email ) ) {
                $email_listings = get_posts( [
                    'post_type'      => 'vb_listing',
                    'post_status'    => [ 'publish', 'draft', 'pending' ],
                    'posts_per_page' => -1,
                    'fields'         => 'ids',
                    'meta_query'     => [
                        [
                            'key'     => '_vb_email',
                            'value'   => $email,
                            'compare' => '=',
                        ],
                    ],
                    'tax_query'      => [
                        [
                            'taxonomy' => 'vb_category',
                            'field'    => 'term_id',
                            'terms'    => $category_id,
                        ],
                    ],
                ] );
                $existing_count = max( $existing_count, count( $email_listings ) );
            }

            if ( $existing_count >= 10 ) {
                $referer = wp_get_referer() ?: home_url( '/new/' );
                wp_safe_redirect( add_query_arg( [ 'error' => rawurlencode( 'Превышен лимит: разрешено максимум 10 объявлений от одного аккаунта в одну рубрику.' ) ], $referer ) );
                exit;
            }
        }

        // Create vb_listing post
        $post_id = wp_insert_post( [
            'post_title'   => $title,
            'post_content' => $description,
            'post_status'  => 'publish',
            'post_type'    => 'vb_listing',
            'post_author'  => $author_id,
        ] );

        if ( is_wp_error( $post_id ) ) {
            $referer = wp_get_referer() ?: home_url( '/new/' );
            wp_safe_redirect( add_query_arg( [ 'error' => rawurlencode( $post_id->get_error_message() ) ], $referer ) );
            exit;
        }

        // Set metadata
        update_post_meta( $post_id, '_vb_type', $type );
        update_post_meta( $post_id, '_vb_price', $price );
        update_post_meta( $post_id, '_vb_phone', $phone );
        update_post_meta( $post_id, '_vb_whatsapp', $whatsapp );
        update_post_meta( $post_id, '_vb_telegram', $telegram );
        update_post_meta( $post_id, '_vb_email', $email );
        update_post_meta( $post_id, '_vb_address', $address );

        // Expiry date (Vladimir: eternal 2099; Others: default 6 months)
        $is_vladimir = ( 1 === (int) $author_id || strtolower( trim( $email ) ) === 'gin@volny.cz' || strtolower( trim( $email ) ) === 'gin.vladimir@gmail.com' );
        if ( $is_vladimir ) {
            $expiry_str = '2099-12-31 23:59:59';
            update_post_meta( $post_id, 'never_expires', 1 );
            update_post_meta( $post_id, '_never_expires', 1 );
            update_post_meta( $post_id, '_vb_never_expires', 1 );
        } else {
            $expiry_str = date( 'Y-m-d H:i:s', strtotime( '+6 months', current_time( 'timestamp' ) ) );
            delete_post_meta( $post_id, 'never_expires' );
            delete_post_meta( $post_id, '_never_expires' );
            delete_post_meta( $post_id, '_vb_never_expires' );
        }
        update_post_meta( $post_id, 'expiry_date', $expiry_str );
        update_post_meta( $post_id, '_expiry_date', $expiry_str );
        update_post_meta( $post_id, '_vb_expiry_date', $expiry_str );

        // Assign category
        if ( $category_id ) {
            wp_set_post_terms( $post_id, [ $category_id ], 'vb_category' );
        }

        // Assign location
        if ( $location_val ) {
            $loc_term = get_term_by( 'slug', $location_val, 'vb_location' );
            if ( $loc_term ) {
                wp_set_post_terms( $post_id, [ $loc_term->term_id ], 'vb_location' );
            }
        }

        // Handle WebP compressed base64 photos
        if ( ! empty( $_POST['vb_photos_webp'] ) && is_array( $_POST['vb_photos_webp'] ) ) {
            require_once ABSPATH . 'wp-admin/includes/file.php';
            require_once ABSPATH . 'wp-admin/includes/image.php';
            require_once ABSPATH . 'wp-admin/includes/media.php';

            $attached_ids = [];
            $upload_dir   = wp_upload_dir();

            foreach ( array_slice( $_POST['vb_photos_webp'], 0, 15 ) as $i => $data_uri ) {
                if ( ! preg_match( '/^data:image\/(\w+);base64,/', $data_uri, $type_matches ) ) {
                    continue;
                }
                $data = substr( $data_uri, strpos( $data_uri, ',' ) + 1 );
                $decoded = base64_decode( $data );
                if ( false === $decoded ) {
                    continue;
                }

                $filename = 'ad_' . $post_id . '_' . time() . '_' . $i . '.webp';
                $filepath = $upload_dir['path'] . '/' . $filename;

                if ( file_put_contents( $filepath, $decoded ) ) {
                    $attachment = [
                        'post_mime_type' => 'image/webp',
                        'post_title'     => sanitize_file_name( $filename ),
                        'post_content'   => '',
                        'post_status'    => 'inherit',
                    ];
                    $attach_id = wp_insert_attachment( $attachment, $filepath, $post_id );
                    if ( $attach_id && ! is_wp_error( $attach_id ) ) {
                        $attach_data = wp_generate_attachment_metadata( $attach_id, $filepath );
                        wp_update_attachment_metadata( $attach_id, $attach_data );
                        $attached_ids[] = $attach_id;

                        if ( empty( $attached_ids[1] ) && $i === 0 ) {
                            set_post_thumbnail( $post_id, $attach_id );
                        }
                    }
                }
            }

            if ( ! empty( $attached_ids ) ) {
                update_post_meta( $post_id, '_vb_images', $attached_ids );
            }
        }

        // Redirect to newly published listing
        wp_safe_redirect( get_permalink( $post_id ) );
        exit;
    }

    /**
     * Filter ACADP deprecated template loader
     */
    public static function filter_acadp_template( $template_file, $name, $widget = '' ) {
        if ( strpos( $name, 'acadp-public-categories-text-list-display.php' ) !== false ) {
            $custom = VB_BOARD_PATH . 'templates/acadp-categories-list.php';
            if ( file_exists( $custom ) ) {
                return $custom;
            }
        }
        return $template_file;
    }

    /**
     * Filter ACADP standard template loader
     */
    public static function filter_acadp_load_template( $template_file, $options = [] ) {
        if ( strpos( $template_file, 'layout-list.php' ) !== false && strpos( $template_file, 'categories' ) !== false ) {
            $custom = VB_BOARD_PATH . 'templates/acadp-categories-list.php';
            if ( file_exists( $custom ) ) {
                return $custom;
            }
        }
        return $template_file;
    }

    /**
     * Hierarchical 3-Column Categories Grid (Exact layout with full keywords, H2 and H3)
     */
    public static function render_categories( $atts ) {
        $tax = 'vb_category';

        $preferred_cols = [
            0 => [ 'auto', 'business', 'phones', 'avto', 'rabota-i-biznes', 'sredstva-svyazi' ],
            1 => [ 'home', 'entertainment', 'household', 'dlya-doma', 'razvlecheniya', 'hozyajstvo' ],
            2 => [ 'realty', 'other', 'electronics', 'nedvizhimost', 'raznoe', 'elektronika' ],
        ];

        // 1. Fetch all top-level parent categories
        $all_parents = get_terms( [
            'taxonomy'   => $tax,
            'hide_empty' => false,
            'parent'     => 0,
            'orderby'    => 'term_id',
            'order'      => 'ASC',
        ] );

        if ( is_wp_error( $all_parents ) || empty( $all_parents ) ) {
            return '';
        }

        $parents_by_slug = [];
        foreach ( $all_parents as $p ) {
            $parents_by_slug[ $p->slug ] = $p;
        }

        $cols = [ 0 => [], 1 => [], 2 => [] ];
        $used_ids = [];

        // Distribute preferred categories across columns
        foreach ( $preferred_cols as $c_idx => $slug_list ) {
            foreach ( $slug_list as $slug ) {
                if ( isset( $parents_by_slug[ $slug ] ) ) {
                    $p = $parents_by_slug[ $slug ];
                    if ( ! in_array( $p->term_id, $used_ids, true ) ) {
                        $cols[ $c_idx ][] = $p;
                        $used_ids[] = $p->term_id;
                    }
                }
            }
        }

        // Place any remaining or custom top-level categories
        $col_target = 0;
        foreach ( $all_parents as $p ) {
            if ( ! in_array( $p->term_id, $used_ids, true ) ) {
                $cols[ $col_target % 3 ][] = $p;
                $used_ids[] = $p->term_id;
                $col_target++;
            }
        }

        ob_start();
        ?>
        <div class="vb-categories-columns-wrap">
            <div class="vb-cat-row">
                <?php for ( $col = 0; $col < 3; $col++ ) : ?>
                    <div class="vb-cat-col">
                        <?php foreach ( $cols[ $col ] as $parent ) : 
                            if ( ! $parent ) continue;

                            $children = get_terms( [
                                'taxonomy'   => $tax,
                                'hide_empty' => false,
                                'parent'     => $parent->term_id,
                                'orderby'    => 'name',
                                'order'      => 'ASC',
                            ] );

                            $padded_count = (int) $parent->count;
                            if ( ! empty( $children ) && ! is_wp_error( $children ) ) {
                                foreach ( $children as $ch ) {
                                    $padded_count += (int) $ch->count;
                                }
                            }

                            $parent_url = get_term_link( $parent );
                            $clean_parent_name = trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $parent->name ) );
                        ?>
                            <div class="vb-cat-group">
                                <div class="vb-cat-accent-line"></div>
                                <h2 class="vb-cat-parent-title">
                                    <a href="<?php echo esc_url( $parent_url ); ?>">
                                        <span class="vb-cat-bullet" aria-hidden="true">◉</span> <?php echo esc_html( $clean_parent_name ); ?>
                                        <span class="vb-count">(<?php echo esc_html( $padded_count ); ?>)</span>
                                    </a>
                                </h2>

                                <?php if ( ! empty( $children ) && ! is_wp_error( $children ) ) : ?>
                                    <ul class="vb-subcat-list">
                                        <?php foreach ( $children as $child ) : 
                                            $child_url = get_term_link( $child );
                                            $clean_child_name = trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $child->name ) );
                                        ?>
                                            <li class="vb-subcat-item">
                                                <div class="vb-subcat-title">
                                                    <a href="<?php echo esc_url( $child_url ); ?>">
                                                        <?php echo esc_html( $clean_child_name ); ?>
                                                        <span class="vb-count">(<?php echo (int) $child->count; ?>)</span>
                                                    </a>
                                                </div>
                                            </li>
                                        <?php endforeach; ?>
                                    </ul>
                                <?php endif; ?>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endfor; ?>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }

    /**
     * Companies Directory View with Filter Bar (Category, Region/Location, Keywords Search)
     */
    public static function render_companies( $atts ) {
        $atts = shortcode_atts( [
            'per_page' => 24,
            'orderby'  => 'date',
            'order'    => 'DESC',
        ], $atts, 'vb_companies' );

        $search_val = sanitize_text_field( $_GET['vb_search'] ?? '' );
        $cat_slug   = sanitize_text_field( $_GET['vb_cat'] ?? '' );
        $loc_slug   = sanitize_text_field( $_GET['vb_loc'] ?? '' );

        $args = [
            'post_type'      => 'vb_listing',
            'post_status'    => 'publish',
            'posts_per_page' => (int) $atts['per_page'],
            'orderby'        => $atts['orderby'],
            'order'          => $atts['order'],
        ];

        if ( ! empty( $search_val ) ) {
            $args['s'] = $search_val;
        }

        $tax_query = [];
        if ( ! empty( $cat_slug ) ) {
            $tax_query[] = [
                'taxonomy' => taxonomy_exists( 'acadp_categories' ) ? 'acadp_categories' : 'vb_category',
                'field'    => 'slug',
                'terms'    => $cat_slug,
            ];
        }
        if ( ! empty( $loc_slug ) ) {
            $tax_query[] = [
                'taxonomy' => taxonomy_exists( 'acadp_locations' ) ? 'acadp_locations' : 'vb_location',
                'field'    => 'slug',
                'terms'    => $loc_slug,
            ];
        }
        if ( ! empty( $tax_query ) ) {
            $args['tax_query'] = $tax_query;
        }

        $args['meta_query'] = [
            'relation' => 'OR',
            [
                'key'     => '_vb_type',
                'value'   => 'company',
                'compare' => '=',
            ],
            [
                'key'     => '_vb_type',
                'compare' => 'NOT EXISTS',
            ],
        ];

        $query = new WP_Query( $args );

        // Fetch categories for dropdown
        $tax_cat = taxonomy_exists( 'acadp_categories' ) ? 'acadp_categories' : 'vb_category';
        $top_cats = get_terms( [
            'taxonomy'   => $tax_cat,
            'hide_empty' => false,
            'parent'     => 0,
            'orderby'    => 'name',
            'order'      => 'ASC',
        ] );

        // Fetch Czech Republic locations for dropdown
        $tax_loc = taxonomy_exists( 'acadp_locations' ) ? 'acadp_locations' : 'vb_location';
        $czech_term = get_term_by( 'slug', 'chehiya', $tax_loc );
        $locations = [];
        if ( $czech_term ) {
            $locations = get_terms( [
                'taxonomy'   => $tax_loc,
                'hide_empty' => false,
                'parent'     => $czech_term->term_id,
                'orderby'    => 'name',
                'order'      => 'ASC',
            ] );
        }
        if ( empty( $locations ) || is_wp_error( $locations ) ) {
            $locations = get_terms( [
                'taxonomy'   => $tax_loc,
                'hide_empty' => false,
                'orderby'    => 'name',
                'order'      => 'ASC',
            ] );
        }

        $has_filters = ( ! empty( $search_val ) || ! empty( $cat_slug ) || ! empty( $loc_slug ) );

        ob_start();
        ?>
        <div class="vb-company-directory-wrap">
            <!-- Filter Bar -->
            <form method="GET" action="<?php echo esc_url( get_permalink() ); ?>" class="vb-company-filter-bar">
                <div class="vb-filter-grid">
                    <div class="vb-filter-cell vb-filter-search-cell">
                        <span class="vb-f-icon">🔍</span>
                        <input type="text" name="vb_search" value="<?php echo esc_attr( $search_val ); ?>" placeholder="Поиск компании или услуги..." class="vb-f-input">
                    </div>

                    <div class="vb-filter-cell">
                        <span class="vb-f-icon">📁</span>
                        <select name="vb_cat" class="vb-f-select">
                            <option value="">Все категории</option>
                            <?php if ( ! empty( $top_cats ) && ! is_wp_error( $top_cats ) ) : ?>
                                <?php foreach ( $top_cats as $cat ) : 
                                    $c_clean = trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $cat->name ) );
                                ?>
                                    <option value="<?php echo esc_attr( $cat->slug ); ?>" <?php selected( $cat_slug, $cat->slug ); ?>>
                                        ◉ <?php echo esc_html( $c_clean ); ?>
                                    </option>
                                    <?php 
                                    $sub_cats = get_terms( [
                                        'taxonomy'   => $tax_cat,
                                        'hide_empty' => false,
                                        'parent'     => $cat->term_id,
                                        'orderby'    => 'name',
                                        'order'      => 'ASC',
                                    ] );
                                    if ( ! empty( $sub_cats ) && ! is_wp_error( $sub_cats ) ) :
                                        foreach ( $sub_cats as $sub ) : ?>
                                            <option value="<?php echo esc_attr( $sub->slug ); ?>" <?php selected( $cat_slug, $sub->slug ); ?>>
                                                &nbsp;&nbsp;— <?php echo esc_html( $sub->name ); ?>
                                            </option>
                                        <?php endforeach;
                                    endif; ?>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </select>
                    </div>

                    <div class="vb-filter-cell">
                        <span class="vb-f-icon">📍</span>
                        <select name="vb_loc" class="vb-f-select">
                            <option value="">Все регионы Чехии</option>
                            <?php if ( ! empty( $locations ) && ! is_wp_error( $locations ) ) : ?>
                                <?php foreach ( $locations as $loc ) : ?>
                                    <option value="<?php echo esc_attr( $loc->slug ); ?>" <?php selected( $loc_slug, $loc->slug ); ?>>
                                        <?php echo esc_html( $loc->name ); ?>
                                    </option>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </select>
                    </div>

                    <div class="vb-filter-cell vb-filter-btn-cell">
                        <button type="submit" class="vb-f-btn-submit">Найти</button>
                        <?php if ( $has_filters ) : ?>
                            <a href="<?php echo esc_url( get_permalink() ); ?>" class="vb-f-btn-reset">Сброс</a>
                        <?php endif; ?>
                    </div>
                </div>
            </form>

            <?php if ( ! $query->have_posts() ) : ?>
                <div class="vb-empty-box">
                    <p>По вашему запросу компаний не найдено.</p>
                    <?php if ( $has_filters ) : ?>
                        <p><a href="<?php echo esc_url( get_permalink() ); ?>" class="button is-outline">Сбросить фильтры</a></p>
                    <?php endif; ?>
                </div>
            <?php else : ?>
                <div class="vb-company-grid">
                    <?php while ( $query->have_posts() ) : $query->the_post(); 
                        $id       = get_the_ID();
                        $address  = get_post_meta( $id, '_vb_address', true ) ?: get_post_meta( $id, '_address', true );
                        $phone    = get_post_meta( $id, '_vb_phone', true ) ?: get_post_meta( $id, '_phone', true );
                        $website  = get_post_meta( $id, '_vb_website', true ) ?: get_post_meta( $id, '_website', true );
                        $tagline  = get_post_meta( $id, '_vb_tagline', true ) ?: get_post_meta( $id, '_tagline', true );
                        $thumb    = get_the_post_thumbnail_url( $id, 'medium' ) ?: '/wp-content/plugins/wp-board-directory/assets/no-logo.svg';

                        $vote_stats = VB_Ratings::get_vote_stats( 'company', $id );
                        $likes      = $vote_stats['likes'];
                        $dislikes   = $vote_stats['dislikes'];
                    ?>
                        <div class="vb-company-card" data-id="<?php echo esc_attr( $id ); ?>">
                            <div class="vb-company-logo-wrap">
                                <a href="<?php the_permalink(); ?>">
                                    <img src="<?php echo esc_url( $thumb ); ?>" alt="<?php the_title_attribute(); ?>" loading="lazy" class="vb-company-logo">
                                </a>
                            </div>

                            <div class="vb-company-body">
                                <h3 class="vb-company-card-title">
                                    <a href="<?php the_permalink(); ?>" title="<?php the_title_attribute(); ?>"><?php the_title(); ?></a>
                                </h3>

                                <?php if ( ! empty( $tagline ) && trim( $tagline ) !== '' ) : ?>
                                    <div class="vb-company-tagline"><?php echo esc_html( $tagline ); ?></div>
                                <?php endif; ?>

                                <div class="vb-company-fields">
                                    <div class="vb-c-field">
                                        <span class="vb-c-icon">🌍</span>
                                        <span class="vb-c-text" title="<?php echo esc_attr( $address ?: '—' ); ?>"><?php echo esc_html( $address ?: '—' ); ?></span>
                                    </div>

                                    <div class="vb-c-field">
                                        <span class="vb-c-icon">📞</span>
                                        <?php if ( $phone ) : ?>
                                            <a href="tel:<?php echo esc_attr( preg_replace( '/\s+/', '', $phone ) ); ?>" class="vb-c-link"><?php echo esc_html( $phone ); ?></a>
                                        <?php else : ?>
                                            <span class="vb-c-text">—</span>
                                        <?php endif; ?>
                                    </div>

                                    <div class="vb-c-field">
                                        <span class="vb-c-icon">🌐</span>
                                        <?php if ( $website ) : ?>
                                            <a href="<?php echo esc_url( $website ); ?>" target="_blank" rel="noopener noreferrer" class="vb-c-link">
                                                <?php echo esc_html( preg_replace( '#^https?://(www\.)?#', '', rtrim( $website, '/' ) ) ); ?>
                                            </a>
                                        <?php else : ?>
                                            <span class="vb-c-text">—</span>
                                        <?php endif; ?>
                                    </div>
                                </div>

                                <div class="vb-company-footer">
                                    <div class="vb-rating-dual" title="Оцените компанию (только для зарегистрированных)">
                                        <button type="button" class="vb-btn-vote vb-vote-up" data-target="company" data-id="<?php echo esc_attr( $id ); ?>" data-vote="1" title="Поставить лайк">
                                            <span class="vb-vote-icon">👍</span>
                                            <span class="vb-vote-num" id="vb-likes-<?php echo esc_attr( $id ); ?>"><?php echo esc_html( $likes ); ?></span>
                                        </button>
                                        <button type="button" class="vb-btn-vote vb-vote-down" data-target="company" data-id="<?php echo esc_attr( $id ); ?>" data-vote="-1" title="Поставить дизлайк">
                                            <span class="vb-vote-icon">👎</span>
                                            <span class="vb-vote-num" id="vb-dislikes-<?php echo esc_attr( $id ); ?>"><?php echo esc_html( $dislikes ); ?></span>
                                        </button>
                                    </div>
                                    <a href="<?php the_permalink(); ?>" class="vb-btn-view-profile">Подробнее &rarr;</a>
                                </div>
                            </div>
                        </div>
                    <?php endwhile; wp_reset_postdata(); ?>
                </div>
            <?php endif; ?>
        </div>
        <?php
        return ob_get_clean();
    }

    /**
     * Listings Grid
     */
    public static function render_listings( $atts ) {
        $atts = shortcode_atts( [
            'per_page'          => 30,
            'listings_per_page' => 30,
            'type'              => 'classified',
            'orderby'           => 'date',
            'order'             => 'DESC',
            'category'          => '',
        ], $atts, 'vb_listings' );

        $per_page = ! empty( $atts['listings_per_page'] ) ? (int) $atts['listings_per_page'] : (int) $atts['per_page'];

        $query_args = [
            'post_type'      => 'vb_listing',
            'post_status'    => 'publish',
            'posts_per_page' => $per_page,
            'meta_query'     => [
                [
                    'key'   => '_vb_type',
                    'value' => $atts['type'],
                ],
            ],
            'orderby'        => $atts['orderby'] === 'rand' ? 'rand' : $atts['orderby'],
            'order'          => $atts['order'],
        ];

        if ( ! empty( $atts['category'] ) ) {
            $query_args['tax_query'] = [
                [
                    'taxonomy' => 'vb_category',
                    'field'    => is_numeric( $atts['category'] ) ? 'term_id' : 'slug',
                    'terms'    => $atts['category'],
                ],
            ];
        }

        $query = new WP_Query( $query_args );

        if ( ! $query->have_posts() ) {
            return '<p class="vb-empty-state">Объявления не найдены.</p>';
        }

        ob_start();
        ?>
        <div class="vb-listings-grid">
            <?php while ( $query->have_posts() ) : $query->the_post(); 
                $id       = get_the_ID();
                $price    = get_post_meta( $id, '_vb_price', true );
                $thumb    = get_the_post_thumbnail_url( $id, 'medium' );
                if ( ! $thumb ) {
                    $raw_imgs = get_post_meta( $id, '_vb_images', true );
                    $imgs = maybe_unserialize( $raw_imgs );
                    if ( is_array( $imgs ) && ! empty( $imgs ) && is_numeric( $imgs[0] ) ) {
                        $thumb = wp_get_attachment_image_url( (int) $imgs[0], 'medium' );
                    }
                }
                if ( ! $thumb ) {
                    $thumb = defined( 'VB_BOARD_URL' ) ? ( VB_BOARD_URL . 'assets/no-photo.svg' ) : '/wp-content/plugins/wp-board-directory/assets/no-photo.svg';
                }
                $cats     = wp_get_post_terms( $id, 'vb_category', [ 'fields' => 'names' ] );
                $cat_name = ! empty( $cats ) ? $cats[0] : '';
                $stats    = VB_Ratings::get_vote_stats( 'listing', $id );
            ?>
                <div class="vb-card" data-id="<?php echo esc_attr( $id ); ?>">
                    <div class="vb-card-img-wrap">
                        <a href="<?php the_permalink(); ?>">
                            <img src="<?php echo esc_url( $thumb ); ?>" alt="<?php the_title_attribute(); ?>" loading="lazy" class="vb-card-img">
                        </a>
                    </div>
                    <div class="vb-card-body">
                        <?php if ( $cat_name ) : ?>
                            <div class="vb-card-category"><?php echo esc_html( $cat_name ); ?></div>
                        <?php endif; ?>
                        <h4 class="vb-card-title">
                            <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                        </h4>
                        <div class="vb-card-price">
                            <?php if ( $price > 0 ) : ?>
                                <strong><?php echo number_format( (float) $price, 0, '.', ' ' ); ?> <?php echo esc_html( VB_CPT::get_currency_symbol() ); ?></strong>
                            <?php else : ?>
                                <strong class="vb-price-free">Договорная / Бесплатно</strong>
                            <?php endif; ?>
                        </div>
                        <div class="vb-card-meta">
                            <span class="vb-meta-date">🕒 <?php echo esc_html( get_the_date( 'd.m.Y' ) ); ?></span>
                            <div class="vb-rating-dual">
                                <button type="button" class="vb-btn-vote vb-vote-up" data-target="listing" data-id="<?php echo esc_attr( $id ); ?>" data-vote="1" title="Лайк">
                                    👍 <span id="vb-likes-<?php echo esc_attr( $id ); ?>"><?php echo esc_html( $stats['likes'] ); ?></span>
                                </button>
                                <button type="button" class="vb-btn-vote vb-vote-down" data-target="listing" data-id="<?php echo esc_attr( $id ); ?>" data-vote="-1" title="Дизлайк">
                                    👎 <span id="vb-dislikes-<?php echo esc_attr( $id ); ?>"><?php echo esc_html( $stats['dislikes'] ); ?></span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            <?php endwhile; wp_reset_postdata(); ?>
        </div>
        <?php
        return ob_get_clean();
    }

    private static $search_rendered = false;

    /**
     * Dedicated Universal Search Page & Shortcode ([vb_search], [acadp_search_form], [acadp_search])
     */
    public static function render_search( $atts = [] ) {
        if ( self::$search_rendered ) {
            return '';
        }
        self::$search_rendered = true;

        $atts = shortcode_atts( [
            'per_page' => 24,
        ], $atts, 'vb_search' );

        $search_term = sanitize_text_field( $_GET['s'] ?? $_GET['q'] ?? $_GET['vb_search'] ?? '' );
        $cat_slug    = sanitize_text_field( $_GET['category'] ?? $_GET['cat'] ?? $_GET['vb_cat'] ?? '' );
        $loc_slug    = sanitize_text_field( $_GET['location'] ?? $_GET['city'] ?? $_GET['vb_loc'] ?? '' );
        $type_filter = sanitize_text_field( $_GET['type'] ?? $_GET['vb_type'] ?? '' );
        $sort_val    = sanitize_key( $_GET['sort'] ?? 'newest' );
        $paged       = max( 1, (int) ( $_GET['paged'] ?? get_query_var( 'paged' ) ?: 1 ) );

        $args = [
            'post_type'      => 'vb_listing',
            'post_status'    => 'publish',
            'posts_per_page' => (int) $atts['per_page'],
            'paged'          => $paged,
        ];

        if ( ! empty( $search_term ) ) {
            $args['s'] = $search_term;
        }

        if ( in_array( $type_filter, [ 'classified', 'company' ], true ) ) {
            $args['meta_query'][] = [
                'key'   => '_vb_type',
                'value' => $type_filter,
            ];
        }

        $tax_query = [];
        if ( ! empty( $cat_slug ) ) {
            $tax_query[] = [
                'taxonomy' => 'vb_category',
                'field'    => 'slug',
                'terms'    => $cat_slug,
            ];
        }
        if ( ! empty( $loc_slug ) ) {
            $tax_query[] = [
                'taxonomy' => 'vb_location',
                'field'    => 'slug',
                'terms'    => $loc_slug,
            ];
        }
        if ( ! empty( $tax_query ) ) {
            if ( count( $tax_query ) > 1 ) {
                $tax_query['relation'] = 'AND';
            }
            $args['tax_query'] = $tax_query;
        }

        if ( 'price_asc' === $sort_val ) {
            $args['meta_key'] = '_vb_price';
            $args['orderby']  = 'meta_value_num';
            $args['order']    = 'ASC';
        } elseif ( 'price_desc' === $sort_val ) {
            $args['meta_key'] = '_vb_price';
            $args['orderby']  = 'meta_value_num';
            $args['order']    = 'DESC';
        } elseif ( 'oldest' === $sort_val ) {
            $args['orderby'] = 'date';
            $args['order']   = 'ASC';
        } else {
            $args['orderby'] = 'date';
            $args['order']   = 'DESC';
        }

        $query = new WP_Query( $args );

        $categories = get_terms( [
            'taxonomy'   => 'vb_category',
            'hide_empty' => false,
            'parent'     => 0,
            'orderby'    => 'name',
            'order'      => 'ASC',
        ] );

        $locations = get_terms( [
            'taxonomy'   => 'vb_location',
            'hide_empty' => false,
            'orderby'    => 'name',
            'order'      => 'ASC',
        ] );

        $has_filters = ( ! empty( $search_term ) || ! empty( $cat_slug ) || ! empty( $loc_slug ) || ! empty( $type_filter ) || ( 'newest' !== $sort_val && ! empty( $sort_val ) ) );
        $form_action = strtok( $_SERVER['REQUEST_URI'] ?? '', '?' );

        ob_start();
        ?>
        <div class="vb-search-container">
            <div class="vb-search-hero">
                <h2 class="vb-search-heading">🔍 Поиск объявлений и компаний</h2>
                <p class="vb-search-subheading">Быстрый поиск товаров, услуг, недвижимости, работы и компаний</p>
            </div>

            <form method="GET" action="<?php echo esc_url( $form_action ); ?>" class="vb-search-form">
                <!-- Search Keyword Row -->
                <div class="vb-search-main-row">
                    <div class="vb-search-input-wrap">
                        <span class="vb-search-icon">🔍</span>
                        <input type="text" name="q" value="<?php echo esc_attr( $search_term ); ?>" placeholder="Что вы ищете? Например: авто, квартира, работа, ремонт, юрист..." class="vb-search-input">
                        <?php if ( ! empty( $search_term ) ) : ?>
                            <a href="<?php echo esc_url( $form_action ); ?>" class="vb-search-clear" title="Очистить">✕</a>
                        <?php endif; ?>
                    </div>
                    <button type="submit" class="vb-search-submit-btn">
                        <span>Найти</span>
                    </button>
                </div>

                <!-- Secondary Filters Row -->
                <div class="vb-search-filters-row">
                    <div class="vb-sf-item">
                        <label class="vb-sf-label">📁 Рубрика:</label>
                        <select name="category" class="vb-sf-select">
                            <option value="">Все рубрики</option>
                            <?php if ( ! empty( $categories ) && ! is_wp_error( $categories ) ) : ?>
                                <?php foreach ( $categories as $cat ) : 
                                    $c_clean = trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $cat->name ) );
                                ?>
                                    <option value="<?php echo esc_attr( $cat->slug ); ?>" <?php selected( $cat_slug, $cat->slug ); ?>>
                                        ◉ <?php echo esc_html( $c_clean ); ?> (<?php echo (int) $cat->count; ?>)
                                    </option>
                                    <?php 
                                    $subs = get_terms( [
                                        'taxonomy'   => 'vb_category',
                                        'hide_empty' => false,
                                        'parent'     => $cat->term_id,
                                        'orderby'    => 'name',
                                        'order'      => 'ASC',
                                    ] );
                                    if ( ! empty( $subs ) && ! is_wp_error( $subs ) ) :
                                        foreach ( $subs as $sub ) : ?>
                                            <option value="<?php echo esc_attr( $sub->slug ); ?>" <?php selected( $cat_slug, $sub->slug ); ?>>
                                                &nbsp;&nbsp;— <?php echo esc_html( $sub->name ); ?> (<?php echo (int) $sub->count; ?>)
                                            </option>
                                        <?php endforeach;
                                    endif; ?>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </select>
                    </div>

                    <div class="vb-sf-item">
                        <label class="vb-sf-label">📍 Город / Регион:</label>
                        <select name="location" class="vb-sf-select">
                            <option value="">Все города и регионы</option>
                            <?php if ( ! empty( $locations ) && ! is_wp_error( $locations ) ) : ?>
                                <?php foreach ( $locations as $loc ) : ?>
                                    <option value="<?php echo esc_attr( $loc->slug ); ?>" <?php selected( $loc_slug, $loc->slug ); ?>>
                                        <?php echo esc_html( $loc->name ); ?> (<?php echo (int) $loc->count; ?>)
                                    </option>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </select>
                    </div>

                    <div class="vb-sf-item">
                        <label class="vb-sf-label">🏷️ Тип:</label>
                        <select name="type" class="vb-sf-select">
                            <option value="">Все публикации</option>
                            <option value="classified" <?php selected( $type_filter, 'classified' ); ?>>📢 Только объявления</option>
                            <option value="company" <?php selected( $type_filter, 'company' ); ?>>🏢 Только компании</option>
                        </select>
                    </div>

                    <div class="vb-sf-item">
                        <label class="vb-sf-label">⇅ Сортировка:</label>
                        <select name="sort" class="vb-sf-select" onchange="this.form.submit();">
                            <option value="newest" <?php selected( $sort_val, 'newest' ); ?>>Сначала новые</option>
                            <option value="oldest" <?php selected( $sort_val, 'oldest' ); ?>>Сначала старые</option>
                            <option value="price_asc" <?php selected( $sort_val, 'price_asc' ); ?>>Сначала дешевле</option>
                            <option value="price_desc" <?php selected( $sort_val, 'price_desc' ); ?>>Сначала дороже</option>
                        </select>
                    </div>

                    <?php if ( $has_filters ) : ?>
                        <div class="vb-sf-item vb-sf-reset">
                            <a href="<?php echo esc_url( $form_action ); ?>" class="vb-sf-reset-btn">✕ Сбросить фильтры</a>
                        </div>
                    <?php endif; ?>
                </div>
            </form>

            <!-- Results Summary Bar -->
            <div class="vb-search-results-bar">
                <?php if ( $has_filters ) : ?>
                    <span class="vb-srb-count">Найдено публикаций: <strong><?php echo (int) $query->found_posts; ?></strong></span>
                    <?php if ( ! empty( $search_term ) ) : ?>
                        <span class="vb-srb-query">по запросу «<strong><?php echo esc_html( $search_term ); ?></strong>»</span>
                    <?php endif; ?>
                <?php else : ?>
                    <span class="vb-srb-count">Свежие объявления и компании:</span>
                <?php endif; ?>
            </div>

            <!-- Results Grid -->
            <?php if ( $query->have_posts() ) : ?>
                <div class="vb-listings-grid">
                    <?php while ( $query->have_posts() ) : $query->the_post(); 
                        $id       = get_the_ID();
                        $type     = get_post_meta( $id, '_vb_type', true ) ?: 'classified';
                        $price    = get_post_meta( $id, '_vb_price', true );
                        $thumb    = get_the_post_thumbnail_url( $id, 'medium' );
                        if ( ! $thumb ) {
                            $raw_imgs = get_post_meta( $id, '_vb_images', true );
                            $imgs = maybe_unserialize( $raw_imgs );
                            if ( is_array( $imgs ) && ! empty( $imgs ) && is_numeric( $imgs[0] ) ) {
                                $thumb = wp_get_attachment_image_url( (int) $imgs[0], 'medium' );
                            }
                        }
                        if ( ! $thumb ) {
                            $thumb = defined( 'VB_BOARD_URL' ) ? ( VB_BOARD_URL . 'assets/no-photo.svg' ) : '/wp-content/plugins/wp-board-directory/assets/no-photo.svg';
                        }
                        $cats     = wp_get_post_terms( $id, 'vb_category', [ 'fields' => 'names' ] );
                        $cat_name = ! empty( $cats ) ? $cats[0] : '';
                        $locs     = wp_get_post_terms( $id, 'vb_location', [ 'fields' => 'names' ] );
                        $loc_name = ! empty( $locs ) ? $locs[0] : '';
                        $stats    = VB_Ratings::get_vote_stats( $type === 'company' ? 'company' : 'listing', $id );
                    ?>
                        <div class="vb-card" data-id="<?php echo esc_attr( $id ); ?>">
                            <div class="vb-card-img-wrap">
                                <a href="<?php the_permalink(); ?>">
                                    <img src="<?php echo esc_url( $thumb ); ?>" alt="<?php the_title_attribute(); ?>" loading="lazy" class="vb-card-img">
                                </a>
                                <span class="vb-badge-type <?php echo 'company' === $type ? 'vb-badge-company' : 'vb-badge-ad'; ?>">
                                    <?php echo 'company' === $type ? '🏢 Компания' : '📢 Объявление'; ?>
                                </span>
                            </div>
                            <div class="vb-card-body">
                                <div class="vb-card-meta-top">
                                    <?php if ( $cat_name ) : ?>
                                        <span class="vb-card-category"><?php echo esc_html( $cat_name ); ?></span>
                                    <?php endif; ?>
                                    <?php if ( $loc_name ) : ?>
                                        <span class="vb-card-location">📍 <?php echo esc_html( $loc_name ); ?></span>
                                    <?php endif; ?>
                                </div>
                                <h4 class="vb-card-title">
                                    <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                                </h4>
                                <div class="vb-card-price">
                                    <?php if ( 'company' === $type ) : 
                                        $web = get_post_meta( $id, '_vb_website', true ) ?: get_post_meta( $id, '_website', true );
                                    ?>
                                        <strong class="vb-price-company"><?php echo $web ? '🌐 ' . esc_html( preg_replace( '#^https?://#', '', rtrim( $web, '/' ) ) ) : '🏢 Каталог фирм'; ?></strong>
                                    <?php elseif ( $price > 0 ) : ?>
                                        <strong><?php echo number_format( (float) $price, 0, '.', ' ' ); ?> <?php echo esc_html( VB_CPT::get_currency_symbol() ); ?></strong>
                                    <?php else : ?>
                                        <strong class="vb-price-free">Договорная / Бесплатно</strong>
                                    <?php endif; ?>
                                </div>
                                <div class="vb-card-meta">
                                    <span class="vb-meta-date">🕒 <?php echo esc_html( get_the_date( 'd.m.Y' ) ); ?></span>
                                    <div class="vb-rating-dual">
                                        <button type="button" class="vb-btn-vote vb-vote-up" data-target="<?php echo 'company' === $type ? 'company' : 'listing'; ?>" data-id="<?php echo esc_attr( $id ); ?>" data-vote="1" title="Лайк">
                                            👍 <span id="vb-likes-<?php echo esc_attr( $id ); ?>"><?php echo esc_html( $stats['likes'] ); ?></span>
                                        </button>
                                        <button type="button" class="vb-btn-vote vb-vote-down" data-target="<?php echo 'company' === $type ? 'company' : 'listing'; ?>" data-id="<?php echo esc_attr( $id ); ?>" data-vote="-1" title="Дизлайк">
                                            👎 <span id="vb-dislikes-<?php echo esc_attr( $id ); ?>"><?php echo esc_html( $stats['dislikes'] ); ?></span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    <?php endwhile; wp_reset_postdata(); ?>
                </div>

                <!-- Numbered Pagination -->
                <?php if ( $query->max_num_pages > 1 ) : ?>
                    <div class="vb-pagination">
                        <?php 
                        echo paginate_links( [
                            'base'      => add_query_arg( 'paged', '%#%' ),
                            'format'    => '',
                            'current'   => $paged,
                            'total'     => $query->max_num_pages,
                            'prev_text' => '&laquo; Назад',
                            'next_text' => 'Вперед &raquo;',
                        ] );
                        ?>
                    </div>
                <?php endif; ?>

            <?php else : ?>
                <div class="vb-search-empty-box">
                    <div class="vb-seb-icon">🔎</div>
                    <h3>По вашему запросу ничего не найдено</h3>
                    <p>К сожалению, объявлений или компаний с такими параметрами не обнаружено.</p>
                    <div class="vb-seb-tips">
                        <p><strong>Полезные советы для поиска:</strong></p>
                        <ul>
                            <li>Проверьте написание поисковых слов на наличие опечаток.</li>
                            <li>Попробуйте использовать более общие слова (например, «авто» вместо конкретной модификации).</li>
                            <li>Попробуйте выбрать «Все рубрики» или «Все города и регионы».</li>
                        </ul>
                    </div>
                    <?php if ( $has_filters ) : ?>
                        <a href="<?php echo esc_url( $form_action ); ?>" class="vb-f-btn-submit" style="display:inline-block; margin-top:16px;">Показать все объявления</a>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
        </div>
        <?php
        return ob_get_clean();
    }

    /**
     * Turnkey Unified User Personal Dashboard & Profile
     */
    public static function render_dashboard() {
        if ( ! is_user_logged_in() ) {
            return '
            <div class="vb-auth-box">
                <div class="vb-auth-icon">🔒</div>
                <h3>Вход в личный кабинет</h3>
                <p>Для управления вашими объявлениями, компаниями и профилем, пожалуйста, войдите в систему.</p>
                <div class="vb-auth-buttons">
                    <a href="' . esc_url( wp_login_url( get_permalink() ) ) . '" class="vb-btn-auth-login">Войти</a>
                    <a href="' . esc_url( wp_registration_url() ) . '" class="vb-btn-auth-reg">Регистрация</a>
                </div>
            </div>';
        }

        $user_id = get_current_user_id();
        $user    = wp_get_current_user();

        $active_tab = sanitize_key( $_GET['tab'] ?? 'profile' );
        if ( ! in_array( $active_tab, [ 'profile', 'ads', 'companies' ] ) ) {
            $active_tab = 'profile';
        }

        $phone   = get_user_meta( $user_id, 'phone', true ) ?: get_user_meta( $user_id, 'acadp_phone', true ) ?: get_user_meta( $user_id, 'atbdp_phone', true );
        $city    = get_user_meta( $user_id, 'address', true ) ?: get_user_meta( $user_id, 'user_city', true );
        $company = get_user_meta( $user_id, 'company_name', true ) ?: get_user_meta( $user_id, 'user_company', true );

        // Fetch user classified ads
        $user_ads = get_posts( [
            'post_type'      => [ 'acadp_listings', 'vb_listing' ],
            'post_status'    => [ 'publish', 'draft', 'pending' ],
            'author'         => $user_id,
            'posts_per_page' => -1,
            'meta_query'     => [
                'relation' => 'OR',
                [
                    'key'     => '_vb_type',
                    'value'   => 'classified',
                    'compare' => '=',
                ],
                [
                    'key'     => '_vb_type',
                    'compare' => 'NOT EXISTS',
                ],
            ],
        ] );

        // Fetch user companies
        $user_companies = get_posts( [
            'post_type'      => [ 'at_biz_dir', 'vb_listing' ],
            'post_status'    => [ 'publish', 'draft', 'pending', 'expired' ],
            'author'         => $user_id,
            'posts_per_page' => -1,
            'meta_query'     => [
                'relation' => 'OR',
                [
                    'key'     => '_vb_type',
                    'value'   => 'company',
                    'compare' => '=',
                ],
                [
                    'key'     => '_vb_type',
                    'compare' => 'NOT EXISTS',
                ],
            ],
        ] );

        $is_saved   = ! empty( $_GET['saved'] );
        $deleted_n  = isset( $_GET['deleted'] ) ? absint( $_GET['deleted'] ) : 0;
        $renewed_n  = isset( $_GET['renewed'] ) ? absint( $_GET['renewed'] ) : 0;
        $renew_text = ! empty( $_GET['interval'] ) ? sanitize_text_field( rawurldecode( $_GET['interval'] ) ) : '';

        ob_start();
        ?>
        <div class="vb-dashboard-wrap">
            <!-- Header Card -->
            <div class="vb-dash-header-card">
                <div class="vb-dash-user-info">
                    <div class="vb-dash-avatar">
                        <?php echo get_avatar( $user_id, 72 ); ?>
                    </div>
                    <div class="vb-dash-titles">
                        <h2 class="vb-dash-name"><?php echo esc_html( $user->display_name ); ?></h2>
                        <?php if ( $company ) : ?>
                            <div class="vb-dash-company-badge">🏢 <?php echo esc_html( $company ); ?></div>
                        <?php endif; ?>
                        <div class="vb-dash-meta">
                            <span>✉️ <?php echo esc_html( $user->user_email ); ?></span>
                            <?php if ( $phone ) : ?>
                                <span>📞 <?php echo esc_html( $phone ); ?></span>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>

                <div class="vb-dash-stats">
                    <div class="vb-stat-badge">
                        <span class="vb-stat-num"><?php echo count( $user_ads ); ?></span>
                        <span class="vb-stat-label">📢 Объявлений</span>
                    </div>
                    <div class="vb-stat-badge">
                        <span class="vb-stat-num"><?php echo count( $user_companies ); ?></span>
                        <span class="vb-stat-label">🏢 Компаний</span>
                    </div>
                </div>
            </div>

            <!-- Dashboard Navigation Tabs -->
            <div class="vb-dash-tabs">
                <a href="<?php echo esc_url( add_query_arg( 'tab', 'profile', get_permalink() ) ); ?>" class="vb-dash-tab <?php echo $active_tab === 'profile' ? 'vb-tab-active' : ''; ?>">
                    👤 Мой профиль
                </a>
                <a href="<?php echo esc_url( add_query_arg( 'tab', 'ads', get_permalink() ) ); ?>" class="vb-dash-tab <?php echo $active_tab === 'ads' ? 'vb-tab-active' : ''; ?>">
                    📢 Мои объявления (<?php echo count( $user_ads ); ?>)
                </a>
                <a href="<?php echo esc_url( add_query_arg( 'tab', 'companies', get_permalink() ) ); ?>" class="vb-dash-tab <?php echo $active_tab === 'companies' ? 'vb-tab-active' : ''; ?>">
                    🏢 Мои компании (<?php echo count( $user_companies ); ?>)
                </a>
            </div>

            <!-- Tab Content -->
            <div class="vb-dash-content">
                <?php if ( $deleted_n > 0 ) : ?>
                    <div class="vb-alert-success vb-alert-dash">
                        🗑️ Успешно удалено: <?php echo $deleted_n; ?> элемент(ов).
                    </div>
                <?php endif; ?>
                <?php if ( $renewed_n > 0 ) : ?>
                    <div class="vb-alert-success vb-alert-dash">
                        ⏳ Успешно продлено: <?php echo $renewed_n; ?> публикаций (Срок продлен на <?php echo esc_html( $renew_text ); ?>)!
                    </div>
                <?php endif; ?>

                <?php if ( $active_tab === 'profile' ) : ?>
                    <!-- TAB 1: PROFILE EDITING -->
                    <div class="vb-tab-pane vb-pane-profile">
                        <?php if ( $is_saved ) : ?>
                            <div class="vb-alert-success">
                                ✅ Ваши данные успешно сохранены!
                            </div>
                        <?php endif; ?>

                        <form method="POST" action="" class="vb-profile-form">
                            <?php wp_nonce_field( 'vb_save_profile_action', 'vb_profile_nonce' ); ?>
                            <input type="hidden" name="vb_action" value="save_profile">

                            <div class="vb-form-grid">
                                <div class="vb-form-group">
                                    <label class="vb-label">Имя или псевдоним <span class="vb-req">*</span></label>
                                    <input type="text" name="display_name" value="<?php echo esc_attr( $user->display_name ); ?>" required class="vb-form-input">
                                    <small class="vb-hint">Отображается автором на ваших объявлениях и компании</small>
                                </div>

                                <div class="vb-form-group">
                                    <label class="vb-label">Контактный телефон</label>
                                    <input type="text" name="phone" value="<?php echo esc_attr( $phone ); ?>" placeholder="+420..." class="vb-form-input">
                                    <small class="vb-hint">Будет автоматически подставляться в ваши новые публикации</small>
                                </div>

                                <div class="vb-form-group">
                                    <label class="vb-label">Город / Регион в Чехии</label>
                                    <input type="text" name="city" value="<?php echo esc_attr( $city ); ?>" placeholder="Прага, Брно, Пльзень..." class="vb-form-input">
                                </div>

                                <div class="vb-form-group">
                                    <label class="vb-label">Название компании (если фирма или ИП)</label>
                                    <input type="text" name="company" value="<?php echo esc_attr( $company ); ?>" placeholder="Название вашей фирмы / s.r.o. / OSVČ" class="vb-form-input">
                                </div>

                                <div class="vb-form-group vb-form-full">
                                    <label class="vb-label">Email для связи</label>
                                    <input type="email" value="<?php echo esc_attr( $user->user_email ); ?>" disabled class="vb-form-input vb-input-disabled">
                                    <small class="vb-hint">Для изменения email обратитесь к администратору сайта</small>
                                </div>

                                <div class="vb-form-group vb-form-full">
                                    <label class="vb-label">О себе / О компании</label>
                                    <textarea name="description" rows="4" class="vb-form-textarea" placeholder="Краткое описание вашей деятельности..."><?php echo esc_textarea( $user->description ); ?></textarea>
                                </div>
                            </div>

                            <div class="vb-form-submit-row">
                                <button type="submit" class="vb-btn-save-profile">💾 Сохранить данные профиля</button>
                            </div>
                        </form>
                    </div>

                <?php elseif ( $active_tab === 'ads' ) : ?>
                    <!-- TAB 2: USER ADS -->
                    <div class="vb-tab-pane vb-pane-ads">
                        <div class="vb-pane-toolbar">
                            <h3>Ваши объявления</h3>
                            <a href="<?php echo esc_url( home_url( '/new/' ) ); ?>" class="vb-btn-add-new">+ Подать объявление</a>
                        </div>

                        <?php if ( empty( $user_ads ) ) : ?>
                            <div class="vb-empty-state-box">
                                <p>У вас пока нет поданных объявлений.</p>
                                <a href="<?php echo esc_url( home_url( '/new/' ) ); ?>" class="vb-btn-add-new">+ Подать первое объявление</a>
                            </div>
                        <?php else : ?>
                            <form method="POST" action="" class="vb-dash-bulk-form" onsubmit="return vbValidateBulk(this);">
                                <?php wp_nonce_field( 'vb_dash_bulk_action', 'vb_dash_nonce' ); ?>
                                <input type="hidden" name="vb_action" value="dash_bulk_action">
                                <input type="hidden" name="tab" value="ads">

                                <div class="vb-bulk-bar">
                                    <div class="vb-bulk-left">
                                        <label class="vb-bulk-select-all-label">
                                            <input type="checkbox" class="vb-select-all-checkbox" data-target="vb-item-chk-ads">
                                            <span>Выбрать все</span>
                                        </label>
                                        <div class="vb-bulk-select-wrap">
                                            <select name="bulk_op" class="vb-bulk-select" required>
                                                <option value="">Выберите действие...</option>
                                                <option value="delete">🗑️ Удалить выбранные</option>
                                                <optgroup label="⏳ Продлить публикацию:">
                                                    <option value="renew_1m">⏳ Продлить на 1 месяц</option>
                                                    <option value="renew_3m">⏳ Продлить на 3 месяца</option>
                                                    <option value="renew_6m">⏳ Продлить на 6 месяцев</option>
                                                    <option value="renew_1y">⏳ Продлить на 1 год</option>
                                                </optgroup>
                                            </select>
                                            <button type="submit" class="vb-btn-bulk-apply">Применить</button>
                                        </div>
                                    </div>
                                    <div class="vb-bulk-right">
                                        <button type="submit" class="vb-btn-bulk-danger" onclick="this.form.bulk_op.value='delete';">🗑️ Удалить выбранные</button>
                                    </div>
                                </div>

                                <div class="vb-dash-table-wrap">
                                    <table class="vb-dash-table">
                                        <thead>
                                            <tr>
                                                <th class="vb-col-chk">
                                                    <input type="checkbox" class="vb-select-all-checkbox" data-target="vb-item-chk-ads">
                                                </th>
                                                <th>Фото</th>
                                                <th>Заголовок</th>
                                                <th>Рубрика</th>
                                                <th>Дата / Срок</th>
                                                <th>Статус</th>
                                                <th>Действия</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php foreach ( $user_ads as $ad ) : 
                                                $thumb = get_the_post_thumbnail_url( $ad->ID, 'thumbnail' );
                                                if ( ! $thumb ) {
                                                    $raw_imgs = get_post_meta( $ad->ID, '_vb_images', true );
                                                    $imgs = maybe_unserialize( $raw_imgs );
                                                    if ( is_array( $imgs ) && ! empty( $imgs ) && is_numeric( $imgs[0] ) ) {
                                                        $thumb = wp_get_attachment_image_url( (int) $imgs[0], 'thumbnail' );
                                                    }
                                                }
                                                if ( ! $thumb ) {
                                                    $thumb = defined( 'VB_BOARD_URL' ) ? ( VB_BOARD_URL . 'assets/no-photo.svg' ) : '/wp-content/plugins/wp-board-directory/assets/no-photo.svg';
                                                }
                                                $cats = wp_get_post_terms( $ad->ID, 'vb_category', [ 'fields' => 'names' ] );
                                                if ( is_wp_error( $cats ) || empty( $cats ) ) {
                                                    if ( taxonomy_exists( 'acadp_categories' ) ) {
                                                        $cats = wp_get_post_terms( $ad->ID, 'acadp_categories', [ 'fields' => 'names' ] );
                                                    }
                                                }
                                                $cat_str = ( ! is_wp_error( $cats ) && ! empty( $cats ) ) ? $cats[0] : '—';
                                                $expiry = get_post_meta( $ad->ID, 'expiry_date', true ) ?: get_post_meta( $ad->ID, '_expiry_date', true );
                                                $status_label = ( $ad->post_status === 'publish' ) ? '<span class="vb-badge-pub">Опубликовано</span>' : '<span class="vb-badge-draft">' . esc_html( $ad->post_status ) . '</span>';
                                            ?>
                                                <tr>
                                                    <td class="vb-col-chk">
                                                        <input type="checkbox" name="item_ids[]" value="<?php echo esc_attr( $ad->ID ); ?>" class="vb-item-chk-ads">
                                                    </td>
                                                    <td class="vb-col-thumb">
                                                        <img src="<?php echo esc_url( $thumb ); ?>" alt="" class="vb-table-thumb">
                                                    </td>
                                                    <td class="vb-col-title">
                                                        <a href="<?php echo esc_url( get_permalink( $ad->ID ) ); ?>" class="vb-table-title-link">
                                                            <strong><?php echo esc_html( $ad->post_title ); ?></strong>
                                                        </a>
                                                    </td>
                                                    <td class="vb-col-cat"><?php echo esc_html( $cat_str ); ?></td>
                                                    <td class="vb-col-date">
                                                        <div><?php echo esc_html( get_the_date( 'd.m.Y', $ad->ID ) ); ?></div>
                                                        <?php 
                                                        $ad_never = get_post_meta( $ad->ID, 'never_expires', true ) ?: get_post_meta( $ad->ID, '_never_expires', true );
                                                        if ( $ad_never || ( $expiry && strpos( $expiry, '2099' ) !== false ) ) : ?>
                                                            <small class="vb-expiry-tag" style="background:#ecfdf5;color:#059669;border-color:#a7f3d0;font-weight:700;">вечно ♾️</small>
                                                        <?php elseif ( $expiry ) : ?>
                                                            <small class="vb-expiry-tag">до <?php echo esc_html( date( 'd.m.Y', strtotime( $expiry ) ) ); ?></small>
                                                        <?php endif; ?>
                                                    </td>
                                                    <td class="vb-col-status"><?php echo $status_label; ?></td>
                                                    <td class="vb-col-actions">
                                                        <a href="<?php echo esc_url( get_permalink( $ad->ID ) ); ?>" class="vb-btn-action vb-btn-view" target="_blank">Просмотр</a>
                                                        <a href="<?php echo esc_url( home_url( '/new/?listing_id=' . $ad->ID ) ); ?>" class="vb-btn-action vb-btn-edit">Изменить</a>
                                                        <a href="<?php echo esc_url( wp_nonce_url( add_query_arg( [ 'tab' => 'ads', 'vb_action' => 'delete_item', 'item_id' => $ad->ID ] ), 'vb_delete_item_' . $ad->ID ) ); ?>" class="vb-btn-action vb-btn-delete" onclick="return confirm('Вы уверены, что хотите удалить это объявление?');">Удалить</a>
                                                    </td>
                                                </tr>
                                            <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                </div>
                            </form>
                        <?php endif; ?>
                    </div>

                <?php elseif ( $active_tab === 'companies' ) : ?>
                    <!-- TAB 3: USER COMPANIES -->
                    <div class="vb-tab-pane vb-pane-companies">
                        <div class="vb-pane-toolbar">
                            <h3>Ваши компании в каталоге</h3>
                            <a href="<?php echo esc_url( home_url( '/add-listing/' ) ); ?>" class="vb-btn-add-new">+ Добавить компанию</a>
                        </div>

                        <?php if ( empty( $user_companies ) ) : ?>
                            <div class="vb-empty-state-box">
                                <p>У вас пока нет зарегистрированных компаний в каталоге.</p>
                                <a href="<?php echo esc_url( home_url( '/add-listing/' ) ); ?>" class="vb-btn-add-new">+ Зарегистрировать компанию</a>
                            </div>
                        <?php else : ?>
                            <form method="POST" action="" class="vb-dash-bulk-form" onsubmit="return vbValidateBulk(this);">
                                <?php wp_nonce_field( 'vb_dash_bulk_action', 'vb_dash_nonce' ); ?>
                                <input type="hidden" name="vb_action" value="dash_bulk_action">
                                <input type="hidden" name="tab" value="companies">

                                <div class="vb-bulk-bar">
                                    <div class="vb-bulk-left">
                                        <label class="vb-bulk-select-all-label">
                                            <input type="checkbox" class="vb-select-all-checkbox" data-target="vb-item-chk-companies">
                                            <span>Выбрать все</span>
                                        </label>
                                        <div class="vb-bulk-select-wrap">
                                            <select name="bulk_op" class="vb-bulk-select" required>
                                                <option value="">Выберите действие...</option>
                                                <option value="delete">🗑️ Удалить выбранные</option>
                                                <optgroup label="⏳ Продлить регистрацию:">
                                                    <option value="renew_1m">⏳ Продлить на 1 месяц</option>
                                                    <option value="renew_3m">⏳ Продлить на 3 месяца</option>
                                                    <option value="renew_6m">⏳ Продлить на 6 месяцев</option>
                                                    <option value="renew_1y">⏳ Продлить на 1 год</option>
                                                </optgroup>
                                            </select>
                                            <button type="submit" class="vb-btn-bulk-apply">Применить</button>
                                        </div>
                                    </div>
                                    <div class="vb-bulk-right">
                                        <button type="submit" class="vb-btn-bulk-danger" onclick="this.form.bulk_op.value='delete';">🗑️ Удалить выбранные</button>
                                    </div>
                                </div>

                                <div class="vb-dash-table-wrap">
                                    <table class="vb-dash-table">
                                        <thead>
                                            <tr>
                                                <th class="vb-col-chk">
                                                    <input type="checkbox" class="vb-select-all-checkbox" data-target="vb-item-chk-companies">
                                                </th>
                                                <th>Логотип</th>
                                                <th>Название</th>
                                                <th>Адрес / Телефон / Срок</th>
                                                <th>Оценки</th>
                                                <th>Статус</th>
                                                <th>Действия</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <?php foreach ( $user_companies as $cmp ) : 
                                                $logo = get_the_post_thumbnail_url( $cmp->ID, 'thumbnail' ) ?: '/wp-content/plugins/wp-board-directory/assets/no-logo.svg';
                                                $cmp_addr = get_post_meta( $cmp->ID, '_vb_address', true ) ?: get_post_meta( $cmp->ID, '_address', true );
                                                $cmp_phone = get_post_meta( $cmp->ID, '_vb_phone', true ) ?: get_post_meta( $cmp->ID, '_phone', true );
                                                $cmp_expiry = get_post_meta( $cmp->ID, 'expiry_date', true ) ?: get_post_meta( $cmp->ID, '_expiry_date', true ) ?: get_post_meta( $cmp->ID, '_vb_expiry_date', true );
                                                $stats = VB_Ratings::get_vote_stats( 'company', $cmp->ID );
                                                $cmp_status_label = ( $cmp->post_status === 'publish' ) 
                                                    ? '<span class="vb-badge-pub">Активна</span>' 
                                                    : ( ( $cmp->post_status === 'expired' ) 
                                                        ? '<span class="vb-badge-draft" style="background:#fee2e2;color:#b91c1c;">Истекла</span>' 
                                                        : '<span class="vb-badge-draft">' . esc_html( $cmp->post_status ) . '</span>' );
                                            ?>
                                                <tr>
                                                    <td class="vb-col-chk">
                                                        <input type="checkbox" name="item_ids[]" value="<?php echo esc_attr( $cmp->ID ); ?>" class="vb-item-chk-companies">
                                                    </td>
                                                    <td class="vb-col-thumb">
                                                        <img src="<?php echo esc_url( $logo ); ?>" alt="" class="vb-table-thumb">
                                                    </td>
                                                    <td class="vb-col-title">
                                                        <a href="<?php echo esc_url( get_permalink( $cmp->ID ) ); ?>" class="vb-table-title-link">
                                                            <strong><?php echo esc_html( $cmp->post_title ); ?></strong>
                                                        </a>
                                                    </td>
                                                    <td class="vb-col-info">
                                                        <div>📍 <?php echo esc_html( $cmp_addr ?: '—' ); ?></div>
                                                        <div>📞 <?php echo esc_html( $cmp_phone ?: '—' ); ?></div>
                                                        <?php 
                                                        $cmp_never = get_post_meta( $cmp->ID, 'never_expires', true ) ?: get_post_meta( $cmp->ID, '_never_expires', true );
                                                        if ( $cmp_never || ( $cmp_expiry && strpos( $cmp_expiry, '2099' ) !== false ) ) : ?>
                                                            <small class="vb-expiry-tag" style="background:#ecfdf5;color:#059669;border-color:#a7f3d0;font-weight:700;">вечно ♾️</small>
                                                        <?php elseif ( $cmp_expiry ) : ?>
                                                            <small class="vb-expiry-tag">до <?php echo esc_html( date( 'd.m.Y', strtotime( $cmp_expiry ) ) ); ?></small>
                                                        <?php endif; ?>
                                                    </td>
                                                    <td class="vb-col-ratings">
                                                        <span class="vb-rate-up">👍 <?php echo (int) $stats['likes']; ?></span>
                                                        <span class="vb-rate-down">👎 <?php echo (int) $stats['dislikes']; ?></span>
                                                    </td>
                                                    <td class="vb-col-status"><?php echo $cmp_status_label; ?></td>
                                                    <td class="vb-col-actions">
                                                        <a href="<?php echo esc_url( get_permalink( $cmp->ID ) ); ?>" class="vb-btn-action vb-btn-view" target="_blank">Просмотр</a>
                                                        <a href="<?php echo esc_url( home_url( '/add-listing/?listing_id=' . $cmp->ID ) ); ?>" class="vb-btn-action vb-btn-edit">Изменить</a>
                                                        <a href="<?php echo esc_url( wp_nonce_url( add_query_arg( [ 'tab' => 'companies', 'vb_action' => 'delete_item', 'item_id' => $cmp->ID ] ), 'vb_delete_item_' . $cmp->ID ) ); ?>" class="vb-btn-action vb-btn-delete" onclick="return confirm('Вы уверены, что хотите удалить эту компанию?');">Удалить</a>
                                                    </td>
                                                </tr>
                                            <?php endforeach; ?>
                                        </tbody>
                                    </table>
                                </div>
                            </form>
                        <?php endif; ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
}
