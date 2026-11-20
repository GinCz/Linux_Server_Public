<?php
/**
 * Custom Post Types & Taxonomies Registration
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class VB_CPT {

    public static function init() {
        add_action( 'init', [ __CLASS__, 'register_post_types' ], 0 );
        add_action( 'init', [ __CLASS__, 'register_taxonomies' ], 0 );

        // Admin Table Columns & Filters
        add_filter( 'manage_vb_listing_posts_columns', [ __CLASS__, 'set_custom_columns' ] );
        add_action( 'manage_vb_listing_posts_custom_column', [ __CLASS__, 'render_custom_columns' ], 10, 2 );
        add_filter( 'manage_edit-vb_listing_sortable_columns', [ __CLASS__, 'set_sortable_columns' ] );
        add_action( 'restrict_manage_posts', [ __CLASS__, 'render_admin_filters' ] );
        add_action( 'admin_head', [ __CLASS__, 'admin_column_styles' ] );

        // Pre get posts for frontend city filter and admin sorting/filtering
        add_action( 'pre_get_posts', [ __CLASS__, 'handle_pre_get_posts' ] );

        // Redirect frontend standard ?s= query to unified /poisk-obyavlenij/
        add_action( 'template_redirect', [ __CLASS__, 'handle_search_redirect' ] );

        // Enhanced search across custom fields (email, phone, address)
        add_filter( 'posts_search', [ __CLASS__, 'enhance_admin_search' ], 10, 2 );

        // Admin Submenu Reordering & Highlighting
        add_action( 'admin_menu', [ __CLASS__, 'customize_admin_submenus' ], 99 );
        add_filter( 'parent_file', [ __CLASS__, 'fix_admin_parent_file' ] );
        add_filter( 'submenu_file', [ __CLASS__, 'fix_admin_submenu_file' ], 10, 2 );
        add_filter( 'views_edit-vb_listing', [ __CLASS__, 'filter_admin_views' ] );

        // Listing Parameters Meta Box
        add_action( 'add_meta_boxes', [ __CLASS__, 'add_listing_meta_boxes' ] );
        add_action( 'save_post_vb_listing', [ __CLASS__, 'save_listing_meta_boxes' ], 10, 2 );

        // Title Placeholder & Max Length Restriction (100 Chars)
        add_filter( 'enter_title_here', [ __CLASS__, 'custom_title_placeholder' ], 10, 2 );
        add_filter( 'wp_insert_post_data', [ __CLASS__, 'enforce_max_title_length' ], 10, 2 );
        add_action( 'admin_footer-post.php', [ __CLASS__, 'render_admin_title_limit_script' ] );
        add_action( 'admin_footer-post-new.php', [ __CLASS__, 'render_admin_title_limit_script' ] );

        // Custom clean permalinks for Ads vs Companies
        add_filter( 'post_type_link', [ __CLASS__, 'custom_post_type_link' ], 10, 2 );
        add_action( 'init', [ __CLASS__, 'add_custom_rewrite_rules' ], 1 );
        add_action( 'init', [ __CLASS__, 'handle_legacy_redirects' ], 1 );

        // Automatic Category & Location Slugs Migration on Update
        add_action( 'init', [ __CLASS__, 'migrate_terms_to_english' ], 20 );
    }

    /**
     * Detect country currency code and symbol based on domain host
     */
    public static function get_currency_info() {
        static $info = null;
        if ( null !== $info ) {
            return $info;
        }

        $host = isset( $_SERVER['HTTP_HOST'] ) ? strtolower( (string) $_SERVER['HTTP_HOST'] ) : '';
        if ( empty( $host ) ) {
            $host = strtolower( (string) wp_parse_url( home_url(), PHP_URL_HOST ) );
        }

        $map = [
            'cz'  => [ 'currency' => 'CZK', 'symbol' => 'Kč' ],
            'de'  => [ 'currency' => 'EUR', 'symbol' => '€' ],
            'pl'  => [ 'currency' => 'PLN', 'symbol' => 'zł' ],
            'fr'  => [ 'currency' => 'EUR', 'symbol' => '€' ],
            'esp' => [ 'currency' => 'EUR', 'symbol' => '€' ],
            'it'  => [ 'currency' => 'EUR', 'symbol' => '€' ],
            'gr'  => [ 'currency' => 'EUR', 'symbol' => '€' ],
            'hun' => [ 'currency' => 'HUF', 'symbol' => 'Ft' ],
            'mld' => [ 'currency' => 'MDL', 'symbol' => 'L' ],
            'ua'  => [ 'currency' => 'UAH', 'symbol' => 'грн' ],
            'isl' => [ 'currency' => 'ILS', 'symbol' => '₪' ],
        ];

        foreach ( $map as $slug => $data ) {
            if ( false !== strpos( $host, 'doska-' . $slug . '.' ) ) {
                $info = $data;
                return $info;
            }
        }

        $info = [ 'currency' => 'EUR', 'symbol' => '€' ];
        return $info;
    }

    public static function get_currency_symbol() {
        $info = self::get_currency_info();
        return $info['symbol'];
    }

    public static function register_post_types() {
        $labels = [
            'name'                  => 'Доска и Каталог',
            'singular_name'         => 'Объявление / Фирма',
            'menu_name'             => 'Доска и Фирмы',
            'name_admin_bar'        => 'Объявление / Фирма',
            'add_new'               => 'Добавить',
            'add_new_item'          => 'Добавить новое объявление / фирму',
            'new_item'              => 'Новая запись',
            'edit_item'             => 'Редактировать запись',
            'view_item'             => 'Посмотреть запись',
            'all_items'             => 'Все объявления и фирмы',
            'search_items'          => 'Искать записи',
            'not_found'             => 'Не найдено',
            'not_found_in_trash'    => 'В корзине не найдено',
        ];

        $args = [
            'labels'             => $labels,
            'public'             => true,
            'publicly_queryable' => true,
            'show_ui'            => true,
            'show_in_menu'       => true,
            'query_var'          => true,
            'rewrite'            => [ 'slug' => 'ad', 'with_front' => false ],
            'capability_type'    => 'post',
            'has_archive'        => 'ads',
            'hierarchical'       => false,
            'menu_position'      => 5,
            'menu_icon'          => 'dashicons-grid-view',
            'supports'           => [ 'title', 'editor', 'author', 'thumbnail', 'comments' ],
            'show_in_rest'       => true,
        ];

        register_post_type( 'vb_listing', $args );
    }

    public static function register_taxonomies() {
        // 1. Categories
        $cat_labels = [
            'name'              => 'Рубрики и категории',
            'singular_name'     => 'Категория',
            'search_items'      => 'Искать категории',
            'all_items'         => 'Все категории',
            'parent_item'       => 'Родительская категория',
            'parent_item_colon' => 'Родительская категория:',
            'edit_item'         => 'Редактировать категорию',
            'update_item'       => 'Обновить категорию',
            'add_new_item'      => 'Добавить новую категорию',
            'new_item_name'     => 'Название новой категории',
            'menu_name'         => 'Рубрики',
        ];

        register_taxonomy( 'vb_category', [ 'vb_listing' ], [
            'hierarchical'          => true,
            'labels'                => $cat_labels,
            'show_ui'               => true,
            'show_admin_column'     => true,
            'query_var'             => true,
            'rewrite'               => [ 'slug' => 'category', 'with_front' => false, 'hierarchical' => true ],
            'show_in_rest'          => true,
            'update_count_callback' => '_update_post_term_count',
        ] );

        // 2. Locations
        $loc_labels = [
            'name'              => 'Города и регионы',
            'singular_name'     => 'Город / Регион',
            'search_items'      => 'Искать локации',
            'all_items'         => 'Все локации',
            'parent_item'       => 'Родительский регион',
            'parent_item_colon' => 'Родительский регион:',
            'edit_item'         => 'Редактировать локацию',
            'update_item'       => 'Обновить локацию',
            'add_new_item'      => 'Добавить локацию',
            'new_item_name'     => 'Название новой локации',
            'menu_name'         => 'Города / Локации',
        ];

        register_taxonomy( 'vb_location', [ 'vb_listing' ], [
            'hierarchical'      => true,
            'labels'            => $loc_labels,
            'show_ui'           => true,
            'show_admin_column' => true,
            'query_var'         => true,
            'rewrite'           => [ 'slug' => 'location', 'with_front' => false, 'hierarchical' => true ],
            'show_in_rest'      => true,
        ] );
    }

    /**
     * Define custom admin columns for vb_listing
     */
    public static function set_custom_columns( $columns ) {
        $new_columns = [];
        $new_columns['cb']       = $columns['cb'];
        $new_columns['vb_thumb'] = 'Фото';
        $new_columns['title']    = 'Заголовок';
        $new_columns['vb_type']  = 'Тип';
        $new_columns['taxonomy-vb_category'] = 'Рубрика';
        $new_columns['taxonomy-vb_location'] = 'Город';
        $new_columns['vb_phone'] = 'Телефон';
        $new_columns['vb_email'] = 'Email';
        $new_columns['vb_price'] = 'Цена';
        $new_columns['vb_expiry']= 'Срок';
        $new_columns['date']     = $columns['date'];

        return $new_columns;
    }

    /**
     * Render custom column content
     */
    public static function render_custom_columns( $column, $post_id ) {
        switch ( $column ) {
            case 'vb_thumb':
                $thumb = get_the_post_thumbnail_url( $post_id, 'thumbnail' );
                if ( ! $thumb ) {
                    $raw_imgs = get_post_meta( $post_id, '_vb_images', true );
                    $imgs = maybe_unserialize( $raw_imgs );
                    if ( is_array( $imgs ) && ! empty( $imgs ) && is_numeric( $imgs[0] ) ) {
                        $thumb = wp_get_attachment_image_url( (int) $imgs[0], 'thumbnail' );
                    }
                }
                if ( ! $thumb ) {
                    $thumb = defined( 'VB_BOARD_URL' ) ? ( VB_BOARD_URL . 'assets/no-photo.svg' ) : '/wp-content/plugins/wp-board-directory/assets/no-photo.svg';
                }
                echo '<a href="' . esc_url( get_edit_post_link( $post_id ) ) . '">';
                echo '<img src="' . esc_url( $thumb ) . '" class="vb-admin-col-thumb" alt="" />';
                echo '</a>';
                break;

            case 'vb_type':
                $type = get_post_meta( $post_id, '_vb_type', true );
                if ( 'company' === $type ) {
                    echo '<span class="vb-badge-company">🏢 Фирма</span>';
                } else {
                    echo '<span class="vb-badge-ad">📢 Объявление</span>';
                }
                break;

            case 'vb_phone':
                $phone = get_post_meta( $post_id, '_vb_phone', true ) ?: get_post_meta( $post_id, '_phone', true ) ?: get_post_meta( $post_id, 'phone', true );
                if ( $phone ) {
                    echo '<a href="tel:' . esc_attr( preg_replace( '/[^\d+]/', '', $phone ) ) . '" style="text-decoration:none; font-weight:600; color:#0284c7;">📞 ' . esc_html( $phone ) . '</a>';
                } else {
                    echo '<span style="color:#94a3b8;">—</span>';
                }
                break;

            case 'vb_email':
                $email = get_post_meta( $post_id, '_vb_email', true ) ?: get_post_meta( $post_id, '_email', true ) ?: get_post_meta( $post_id, 'email', true );
                if ( ! $email ) {
                    $author_id = get_post_field( 'post_author', $post_id );
                    $author = get_userdata( $author_id );
                    $email = $author ? $author->user_email : '';
                }
                if ( $email ) {
                    echo '<a href="mailto:' . esc_attr( $email ) . '" style="text-decoration:none; color:#475569;">✉️ ' . esc_html( $email ) . '</a>';
                } else {
                    echo '<span style="color:#94a3b8;">—</span>';
                }
                break;

            case 'vb_price':
                $price = get_post_meta( $post_id, '_vb_price', true ) ?: get_post_meta( $post_id, 'price', true );
                if ( $price > 0 ) {
                    echo '<strong>' . number_format( (float) $price, 0, '.', ' ' ) . ' ' . esc_html( self::get_currency_symbol() ) . '</strong>';
                } else {
                    echo '<span style="color:#64748b;">—</span>';
                }
                break;

            case 'vb_expiry':
                $post = get_post( $post_id );
                $author_id = (int) ( $post ? $post->post_author : 0 );
                $email = get_post_meta( $post_id, '_vb_email', true ) ?: get_post_meta( $post_id, 'email', true );
                $is_vladimir = ( 1 === $author_id || strtolower( trim( $email ) ) === 'gin@volny.cz' || strtolower( trim( $email ) ) === 'gin.vladimir@gmail.com' );
                $never_expires = get_post_meta( $post_id, 'never_expires', true ) ?: get_post_meta( $post_id, '_never_expires', true ) ?: get_post_meta( $post_id, '_vb_never_expires', true );
                $expiry = get_post_meta( $post_id, 'expiry_date', true ) ?: get_post_meta( $post_id, '_expiry_date', true ) ?: get_post_meta( $post_id, '_vb_expiry_date', true );

                if ( $is_vladimir || $never_expires || ( $expiry && strpos( $expiry, '2099' ) !== false ) ) {
                    echo '<span style="color:#059669; font-size:12px; font-weight:700;">Вечно ♾️</span>';
                } elseif ( $expiry ) {
                    $exp_ts = strtotime( $expiry );
                    $is_expired = $exp_ts && $exp_ts < time();
                    $color = $is_expired ? '#dc2626' : '#059669';
                    echo '<span style="color:' . $color . '; font-size:12px; font-weight:600;">' . esc_html( date( 'd.m.Y', $exp_ts ) ) . '</span>';
                } else {
                    echo '<span style="color:#94a3b8;">—</span>';
                }
                break;
        }
    }

    /**
     * Make custom columns sortable
     */
    public static function set_sortable_columns( $columns ) {
        $columns['vb_phone'] = 'vb_phone';
        $columns['vb_email'] = 'vb_email';
        $columns['vb_price'] = 'vb_price';
        $columns['vb_type']  = 'vb_type';
        return $columns;
    }

    /**
     * Render category, location, and type filters on admin list table
     */
    public static function render_admin_filters( $post_type ) {
        if ( 'vb_listing' !== $post_type ) {
            return;
        }

        // 1. Filter by Type (Clean English parameter: type=ads|companies|all)
        $raw_type = sanitize_key( $_GET['type'] ?? $_GET['vb_type_filter'] ?? 'ads' );
        $selected_type = in_array( $raw_type, [ 'companies', 'company' ], true ) ? 'companies' : ( 'all' === $raw_type ? 'all' : 'ads' );
        ?>
        <select name="type" id="filter-by-vb-type">
            <option value="ads" <?php selected( $selected_type, 'ads' ); ?>>📢 Только объявления</option>
            <option value="companies" <?php selected( $selected_type, 'companies' ); ?>>🏢 Только компании</option>
            <option value="all" <?php selected( $selected_type, 'all' ); ?>>📋 Все вместе (объявления и фирмы)</option>
        </select>
        <?php

        // 2. Filter by Category (Clean English parameter: category)
        $selected_cat = sanitize_text_field( $_GET['category'] ?? $_GET['vb_category_filter'] ?? '' );
        wp_dropdown_categories( [
            'show_option_all' => '— Все рубрики —',
            'taxonomy'        => 'vb_category',
            'name'            => 'category',
            'orderby'         => 'name',
            'selected'        => $selected_cat,
            'hierarchical'    => true,
            'depth'           => 3,
            'show_count'      => true,
            'hide_empty'      => false,
            'value_field'     => 'slug',
        ] );

        // 3. Filter by Location (Clean English parameter: location)
        $selected_loc = sanitize_text_field( $_GET['location'] ?? $_GET['vb_location_filter'] ?? '' );
        wp_dropdown_categories( [
            'show_option_all' => '— Все города и регионы —',
            'taxonomy'        => 'vb_location',
            'name'            => 'location',
            'orderby'         => 'name',
            'selected'        => $selected_loc,
            'hierarchical'    => true,
            'depth'           => 3,
            'show_count'      => true,
            'hide_empty'      => false,
            'value_field'     => 'slug',
        ] );
    }

    /**
     * Pre get posts: handle admin filtering & sorting, and frontend category city filter
     */
    public static function handle_pre_get_posts( $query ) {
        // ADMIN QUERY
        if ( is_admin() && $query->is_main_query() && 'vb_listing' === $query->get( 'post_type' ) ) {
            // Sort by Phone
            if ( 'vb_phone' === $query->get( 'orderby' ) ) {
                $query->set( 'meta_key', '_vb_phone' );
                $query->set( 'orderby', 'meta_value' );
            }
            // Sort by Email
            if ( 'vb_email' === $query->get( 'orderby' ) ) {
                $query->set( 'meta_key', '_vb_email' );
                $query->set( 'orderby', 'meta_value' );
            }
            // Sort by Price
            if ( 'vb_price' === $query->get( 'orderby' ) ) {
                $query->set( 'meta_key', '_vb_price' );
                $query->set( 'orderby', 'meta_value_num' );
            }
            // Sort by Type
            if ( 'vb_type' === $query->get( 'orderby' ) ) {
                $query->set( 'meta_key', '_vb_type' );
                $query->set( 'orderby', 'meta_value' );
            }

            // Filter by Category
            $cat_slug = sanitize_text_field( $_GET['category'] ?? $_GET['vb_category_filter'] ?? '' );
            if ( ! empty( $cat_slug ) ) {
                $tax_query = (array) $query->get( 'tax_query' );
                $tax_query[] = [
                    'taxonomy' => 'vb_category',
                    'field'    => 'slug',
                    'terms'    => $cat_slug,
                ];
                $query->set( 'tax_query', $tax_query );
            }

            // Filter by Location
            $loc_slug = sanitize_text_field( $_GET['location'] ?? $_GET['vb_location_filter'] ?? '' );
            if ( ! empty( $loc_slug ) ) {
                $tax_query = (array) $query->get( 'tax_query' );
                $tax_query[] = [
                    'taxonomy' => 'vb_location',
                    'field'    => 'slug',
                    'terms'    => $loc_slug,
                ];
                $query->set( 'tax_query', $tax_query );
            }

            // Filter by Type (default to ads if no filter specified)
            $raw_type = sanitize_key( $_GET['type'] ?? $_GET['vb_type_filter'] ?? 'ads' );
            if ( in_array( $raw_type, [ 'companies', 'company' ], true ) ) {
                $type_val = 'company';
            } elseif ( 'all' === $raw_type ) {
                $type_val = 'all';
            } else {
                $type_val = 'classified';
            }

            if ( 'all' !== $type_val ) {
                $meta_query = (array) $query->get( 'meta_query' );
                if ( 'classified' === $type_val ) {
                    $meta_query[] = [
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
                    ];
                } else {
                    $meta_query[] = [
                        'key'     => '_vb_type',
                        'value'   => $type_val,
                        'compare' => '=',
                    ];
                }
                $query->set( 'meta_query', $meta_query );
            }
        }

        // FRONTEND QUERY: Standard Search (include vb_listing and vb_company)
        if ( ! is_admin() && $query->is_main_query() && $query->is_search() ) {
            $post_types = (array) $query->get( 'post_type' );
            if ( empty( $post_types ) || $post_types === [ 'post' ] || in_array( 'post', $post_types, true ) ) {
                $query->set( 'post_type', [ 'vb_listing', 'vb_company', 'post' ] );
            }
        }

        // FRONTEND QUERY: Category Archive City & Keyword Filter
        if ( ! is_admin() && $query->is_main_query() && ( is_tax( 'vb_category' ) || is_post_type_archive( 'vb_listing' ) ) ) {
            $city_slug = sanitize_text_field( $_GET['city'] ?? $_GET['location'] ?? $_GET['mesto'] ?? '' );
            if ( ! empty( $city_slug ) ) {
                $tax_query = (array) $query->get( 'tax_query' );
                $tax_query[] = [
                    'taxonomy' => 'vb_location',
                    'field'    => 'slug',
                    'terms'    => $city_slug,
                ];
                $query->set( 'tax_query', $tax_query );
            }

            // Keyword search in category
            $kw = sanitize_text_field( $_GET['s_q'] ?? '' );
            if ( ! empty( $kw ) ) {
                $query->set( 's', $kw );
            }

            // Sort order
            $order_by = sanitize_key( $_GET['sort'] ?? '' );
            if ( 'price_asc' === $order_by ) {
                $query->set( 'meta_key', '_vb_price' );
                $query->set( 'orderby', 'meta_value_num' );
                $query->set( 'order', 'ASC' );
            } elseif ( 'price_desc' === $order_by ) {
                $query->set( 'meta_key', '_vb_price' );
                $query->set( 'orderby', 'meta_value_num' );
                $query->set( 'order', 'DESC' );
            } elseif ( 'oldest' === $order_by ) {
                $query->set( 'orderby', 'date' );
                $query->set( 'order', 'ASC' );
            }
        }
    }

    /**
     * Redirect standard frontend ?s= search queries to dedicated /poisk-obyavlenij/
     */
    public static function handle_search_redirect() {
        if ( ! is_admin() && is_search() && ! empty( get_search_query() ) ) {
            $req_uri = $_SERVER['REQUEST_URI'] ?? '';
            if ( strpos( $req_uri, 'poisk-obyavlenij' ) === false ) {
                $search_q = get_search_query();
                wp_safe_redirect( home_url( '/poisk-obyavlenij/?q=' . urlencode( $search_q ) ) );
                exit;
            }
        }
    }

    /**
     * Enhanced search across custom fields (_vb_email, _vb_phone, _vb_address) and author email
     */
    public static function enhance_admin_search( $search, $query ) {
        global $wpdb;

        $post_type = $query->get( 'post_type' );
        $is_vb = false;
        if ( is_string( $post_type ) && ( 'vb_listing' === $post_type || 'vb_company' === $post_type ) ) {
            $is_vb = true;
        } elseif ( is_array( $post_type ) && ( in_array( 'vb_listing', $post_type, true ) || in_array( 'vb_company', $post_type, true ) ) ) {
            $is_vb = true;
        }

        if ( $is_vb && $query->is_search() ) {
            $search_term = trim( (string) $query->get( 's' ) );
            if ( ! empty( $search_term ) ) {
                $term_like = '%' . $wpdb->esc_like( $search_term ) . '%';

                // Find matching post IDs from postmeta
                $meta_ids = $wpdb->get_col( $wpdb->prepare(
                    "SELECT DISTINCT post_id FROM {$wpdb->postmeta} WHERE meta_key IN ('_vb_email', '_vb_phone', '_vb_address', 'email', 'phone', '_email', '_phone', '_vb_whatsapp', '_vb_telegram', '_vb_website') AND meta_value LIKE %s",
                    $term_like
                ) );

                // Find matching post IDs from author users
                $user_ids = $wpdb->get_col( $wpdb->prepare(
                    "SELECT p.ID FROM {$wpdb->posts} p JOIN {$wpdb->users} u ON p.post_author = u.ID WHERE p.post_type IN ('vb_listing', 'vb_company') AND (u.user_email LIKE %s OR u.display_name LIKE %s OR u.user_login LIKE %s)",
                    $term_like,
                    $term_like,
                    $term_like
                ) );

                $matched_ids = array_unique( array_merge( (array) $meta_ids, (array) $user_ids ) );
                if ( ! empty( $matched_ids ) ) {
                    $id_list = implode( ',', array_map( 'absint', $matched_ids ) );
                    $search = " AND (({$wpdb->posts}.post_title LIKE '{$term_like}') OR ({$wpdb->posts}.post_content LIKE '{$term_like}') OR ({$wpdb->posts}.ID IN ({$id_list}))) ";
                }
            }
        }

        return $search;
    }

    /**
     * Custom styling for admin columns, dynamic title and filter script
     */
    public static function admin_column_styles() {
        global $post_type;
        if ( 'vb_listing' !== $post_type ) {
            return;
        }
        ?>
        <style>
            .column-vb_thumb { width: 65px; text-align: center; }
            .vb-admin-col-thumb { width: 52px; height: 42px; object-fit: cover; border-radius: 6px; border: 1px solid #cbd5e1; vertical-align: middle; }
            .column-vb_type { width: 110px; }
            .vb-badge-company { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }
            .vb-badge-ad { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
            .column-vb_phone { width: 130px; }
            .column-vb_email { width: 150px; }
            .column-vb_price { width: 95px; }
            .column-vb_expiry { width: 85px; }
        </style>
        <script>
        document.addEventListener('DOMContentLoaded', function() {
            var urlParams = new URLSearchParams(window.location.search);
            var rawType = urlParams.get('type') || urlParams.get('vb_type_filter') || 'ads';
            var isCompany = (rawType === 'companies' || rawType === 'company');
            var isAll = (rawType === 'all');

            var heading = document.querySelector('.wrap > h1.wp-heading-inline');
            var addNewBtn = document.querySelector('.wrap > a.page-title-action');

            if (heading) {
                if (isCompany) {
                    heading.innerHTML = '🏢 Каталог компаний';
                    if (addNewBtn) {
                        addNewBtn.innerText = 'Добавить компанию';
                        addNewBtn.href = 'post-new.php?post_type=vb_listing&type=company';
                    }
                } else if (!isAll) {
                    heading.innerHTML = '📢 Все объявления';
                    if (addNewBtn) {
                        addNewBtn.innerText = 'Добавить объявление';
                        addNewBtn.href = 'post-new.php?post_type=vb_listing&type=ad';
                    }
                } else {
                    heading.innerHTML = '📋 Все объявления и фирмы';
                }
            }

            var form = document.getElementById('posts-filter');
            if (!form) return;
            form.addEventListener('submit', function() {
                // Disable useless/default GET parameters so they do not clutter the URL
                var checks = [
                    { name: 'filter_action', condition: function() { return true; } },
                    { name: 'action', condition: function(v) { return v === '-1' || !v; } },
                    { name: 'action2', condition: function(v) { return v === '-1' || !v; } },
                    { name: 'm', condition: function(v) { return v === '0' || !v; } },
                    { name: 's', condition: function(v) { return !v.trim(); } },
                    { name: 'category', condition: function(v) { return v === '0' || !v; } },
                    { name: 'vb_category_filter', condition: function(v) { return v === '0' || !v; } },
                    { name: 'location', condition: function(v) { return v === '0' || !v; } },
                    { name: 'vb_location_filter', condition: function(v) { return v === '0' || !v; } },
                    { name: 'post_status', condition: function(v) { return v === 'all'; } },
                    { name: 'paged', condition: function(v) { return v === '1'; } }
                ];
                checks.forEach(function(item) {
                    var els = form.querySelectorAll('[name="' + item.name + '"]');
                    els.forEach(function(el) {
                        if (item.condition(el.value)) {
                            el.disabled = true;
                        }
                    });
                });
            });
        });
        </script>
        <?php
    }

    /**
     * Customize and reorder Admin Submenu items under 'Доска и Фирмы' (Clean short English links)
     */
    public static function customize_admin_submenus() {
        global $submenu;
        $parent = 'edit.php?post_type=vb_listing';
        if ( ! isset( $submenu[ $parent ] ) ) {
            return;
        }

        $new_submenu = [
            [
                '📢 Все объявления',
                'edit_posts',
                'edit.php?post_type=vb_listing&type=ads',
                'Все объявления',
            ],
            [
                '🏢 Все компании',
                'edit_posts',
                'edit.php?post_type=vb_listing&type=companies',
                'Каталог компаний',
            ],
            [
                '➕ Добавить объявление',
                'edit_posts',
                'post-new.php?post_type=vb_listing&type=ad',
                'Добавить объявление',
            ],
            [
                '➕ Добавить компанию',
                'edit_posts',
                'post-new.php?post_type=vb_listing&type=company',
                'Добавить компанию',
            ],
            [
                '📁 Рубрики',
                'manage_categories',
                'edit-tags.php?taxonomy=vb_category&post_type=vb_listing',
                'Рубрики',
            ],
            [
                '📍 Города / Локации',
                'manage_categories',
                'edit-tags.php?taxonomy=vb_location&post_type=vb_listing',
                'Города / Локации',
            ],
            [
                '🧹 Очистка картинок',
                'manage_options',
                'vb-media-cleaner',
                'Очистка картинок',
            ],
            [
                '📦 Миграция (1-Click)',
                'manage_options',
                'vb-migration',
                'Миграция (1-Click)',
            ],
        ];

        $submenu[ $parent ] = $new_submenu;
    }

    /**
     * Ensure correct parent menu highlighting in WordPress Admin
     */
    public static function fix_admin_parent_file( $parent_file ) {
        global $current_screen;
        if ( isset( $current_screen->post_type ) && 'vb_listing' === $current_screen->post_type ) {
            return 'edit.php?post_type=vb_listing';
        }
        return $parent_file;
    }

    /**
     * Ensure correct submenu highlighting in WordPress Admin
     */
    public static function fix_admin_submenu_file( $submenu_file, $parent_file ) {
        if ( 'edit.php?post_type=vb_listing' === $parent_file ) {
            global $pagenow;
            $raw_type = sanitize_key( $_GET['type'] ?? $_GET['vb_type_filter'] ?? $_GET['vb_type'] ?? '' );
            $is_company = in_array( $raw_type, [ 'company', 'companies' ], true );

            if ( 'edit.php' === $pagenow ) {
                return $is_company ? 'edit.php?post_type=vb_listing&type=companies' : 'edit.php?post_type=vb_listing&type=ads';
            } elseif ( 'post-new.php' === $pagenow ) {
                return $is_company ? 'post-new.php?post_type=vb_listing&type=company' : 'post-new.php?post_type=vb_listing&type=ad';
            } elseif ( 'post.php' === $pagenow && isset( $_GET['post'] ) ) {
                $post_id = absint( $_GET['post'] );
                $type = get_post_meta( $post_id, '_vb_type', true );
                return ( 'company' === $type ) ? 'edit.php?post_type=vb_listing&type=companies' : 'edit.php?post_type=vb_listing&type=ads';
            }
        }
        return $submenu_file;
    }

    /**
     * Retain active type filter across post status links (Все, Опубликованные, Корзина)
     */
    public static function filter_admin_views( $views ) {
        $raw_type = sanitize_key( $_GET['type'] ?? $_GET['vb_type_filter'] ?? 'ads' );
        if ( 'all' === $raw_type ) {
            return $views;
        }
        $type_param = in_array( $raw_type, [ 'companies', 'company' ], true ) ? 'companies' : 'ads';
        foreach ( $views as $key => $view_html ) {
            $views[ $key ] = preg_replace( '/href=([\'"])(.*?)([\'"])/', 'href=$1$2&amp;type=' . $type_param . '$3', $view_html );
        }
        return $views;
    }

    /**
     * Context-aware title placeholder for Classified Ads vs Companies
     */
    public static function custom_title_placeholder( $placeholder, $post ) {
        if ( $post && 'vb_listing' === $post->post_type ) {
            $type = get_post_meta( $post->ID, '_vb_type', true ) ?: ( $_GET['vb_type'] ?? 'classified' );
            if ( 'company' === $type ) {
                return 'Введите название компании (например: ООО «Металлист»)...';
            } else {
                return 'Введите заголовок объявления...';
            }
        }
        return $placeholder;
    }

    /**
     * Register Meta Box for listing / company parameters
     */
    public static function add_listing_meta_boxes() {
        // Remove clutter: WordPress native Custom Fields and Excerpt boxes
        remove_meta_box( 'postcustom', 'vb_listing', 'normal' );
        remove_meta_box( 'postexcerpt', 'vb_listing', 'normal' );

        add_meta_box(
            'vb_listing_meta',
            '⚙️ Параметры записи (Доска & Каталог)',
            [ __CLASS__, 'render_listing_meta_box' ],
            'vb_listing',
            'normal',
            'high'
        );
    }

    /**
     * Render Meta Box content
     */
    public static function render_listing_meta_box( $post ) {
        wp_nonce_field( 'vb_listing_meta_save', 'vb_listing_meta_nonce' );

        $current_type = get_post_meta( $post->ID, '_vb_type', true ) ?: ( $_GET['vb_type'] ?? 'classified' );
        $phone        = get_post_meta( $post->ID, '_vb_phone', true ) ?: get_post_meta( $post->ID, '_phone', true ) ?: get_post_meta( $post->ID, 'phone', true );
        $email        = get_post_meta( $post->ID, '_vb_email', true ) ?: get_post_meta( $post->ID, '_email', true ) ?: get_post_meta( $post->ID, 'email', true );
        $price        = get_post_meta( $post->ID, '_vb_price', true ) ?: get_post_meta( $post->ID, 'price', true );
        $whatsapp     = get_post_meta( $post->ID, '_vb_whatsapp', true );
        $telegram     = get_post_meta( $post->ID, '_vb_telegram', true );
        $address      = get_post_meta( $post->ID, '_vb_address', true );
        $website      = get_post_meta( $post->ID, '_vb_website', true ) ?: get_post_meta( $post->ID, '_website', true );
        $expiry       = get_post_meta( $post->ID, 'expiry_date', true ) ?: get_post_meta( $post->ID, '_expiry_date', true ) ?: get_post_meta( $post->ID, '_vb_expiry_date', true );
        $post_obj     = get_post( $post->ID );
        $author_id    = (int) ( $post_obj ? $post_obj->post_author : 0 );
        $is_vladimir  = ( 1 === $author_id || strtolower( trim( $email ) ) === 'gin@volny.cz' || strtolower( trim( $email ) ) === 'gin.vladimir@gmail.com' );
        $never_expires = get_post_meta( $post->ID, 'never_expires', true ) ?: get_post_meta( $post->ID, '_never_expires', true ) ?: get_post_meta( $post->ID, '_vb_never_expires', true );
        if ( $is_vladimir || ( $expiry && strpos( $expiry, '2099' ) !== false ) ) {
            $never_expires = 1;
        }

        if ( ! $expiry ) {
            $expiry = date( 'Y-m-d', strtotime( '+6 months' ) );
        } else {
            $expiry = date( 'Y-m-d', strtotime( $expiry ) );
        }
        ?>
        <style>
            .vb-meta-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 15px; margin-top: 10px; }
            .vb-meta-field { display: flex; flex-direction: column; }
            .vb-meta-field label { font-weight: 600; margin-bottom: 5px; color: #1e293b; font-size: 13px; }
            .vb-meta-field input[type="text"], .vb-meta-field input[type="email"], .vb-meta-field input[type="number"], .vb-meta-field input[type="url"], .vb-meta-field input[type="date"] {
                padding: 8px 12px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px;
            }
            .vb-type-toggle { display: flex; gap: 12px; margin-bottom: 12px; padding: 12px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; }
            .vb-type-card { flex: 1; display: flex; align-items: center; gap: 8px; padding: 10px 14px; background: #fff; border: 2px solid #cbd5e1; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 600; }
            .vb-type-card input { margin: 0; }
            .vb-type-card.active-type { border-color: #6366f1; background: #eef2ff; color: #4338ca; }
        </style>

        <div class="vb-type-toggle">
            <label class="vb-type-card <?php echo 'classified' === $current_type ? 'active-type' : ''; ?>">
                <input type="radio" name="vb_type" value="classified" <?php checked( $current_type, 'classified' ); ?> onchange="vbUpdateTypeUI(this.value)">
                <span>📢 Объявление (частное)</span>
            </label>
            <label class="vb-type-card <?php echo 'company' === $current_type ? 'active-type' : ''; ?>">
                <input type="radio" name="vb_type" value="company" <?php checked( $current_type, 'company' ); ?> onchange="vbUpdateTypeUI(this.value)">
                <span>🏢 Компания / Фирма</span>
            </label>
        </div>

        <div class="vb-meta-grid">
            <div class="vb-meta-field" id="vb-field-price">
                <label for="vb_price">💰 Цена (<?php echo esc_html( self::get_currency_symbol() ); ?> / валюта):</label>
                <input type="number" step="any" id="vb_price" name="vb_price" value="<?php echo esc_attr( $price ); ?>" placeholder="0 (или оставьте пустым)">
            </div>

            <div class="vb-meta-field">
                <label for="vb_phone">📞 Телефон:</label>
                <input type="text" id="vb_phone" name="vb_phone" value="<?php echo esc_attr( $phone ); ?>" placeholder="+420 777 123 456">
            </div>

            <div class="vb-meta-field">
                <label for="vb_email">✉️ Контактный Email:</label>
                <input type="email" id="vb_email" name="vb_email" value="<?php echo esc_attr( $email ); ?>" placeholder="info@example.com">
            </div>

            <div class="vb-meta-field" id="vb-field-website">
                <label for="vb_website">🌐 Веб-сайт (для компаний):</label>
                <input type="url" id="vb_website" name="vb_website" value="<?php echo esc_url( $website ); ?>" placeholder="https://company.cz">
            </div>

            <div class="vb-meta-field">
                <label for="vb_address">📍 Адрес / Физическая локация:</label>
                <input type="text" id="vb_address" name="vb_address" value="<?php echo esc_attr( $address ); ?>" placeholder="Praha 1, Václavské náměstí 1">
            </div>

            <div class="vb-meta-field">
                <label for="vb_whatsapp">💬 WhatsApp (номер):</label>
                <input type="text" id="vb_whatsapp" name="vb_whatsapp" value="<?php echo esc_attr( $whatsapp ); ?>" placeholder="+420777123456">
            </div>

            <div class="vb-meta-field">
                <label for="vb_telegram">✈️ Telegram (@username или номер):</label>
                <input type="text" id="vb_telegram" name="vb_telegram" value="<?php echo esc_attr( $telegram ); ?>" placeholder="@username">
            </div>

            <div class="vb-meta-field">
                <label for="vb_expiry_date">📅 Дата окончания публикации:</label>
                <input type="date" id="vb_expiry_date" name="vb_expiry_date" value="<?php echo esc_attr( $expiry ); ?>">
                <label style="margin-top:8px; font-size:13px; font-weight:600; color:#059669; display:flex; align-items:center; gap:6px; cursor:pointer;">
                    <input type="checkbox" name="vb_never_expires" value="1" <?php checked( (bool) $never_expires, true ); ?>>
                    Отображать вечно (без ограничения срока) ♾️
                </label>
            </div>
        </div>

        <script>
        function vbUpdateTypeUI(val) {
            document.querySelectorAll('.vb-type-card').forEach(function(card) {
                card.classList.remove('active-type');
            });
            var checked = document.querySelector('input[name="vb_type"]:checked');
            if (checked && checked.parentElement) {
                checked.parentElement.classList.add('active-type');
            }
        }
        </script>
        <?php
    }

    /**
     * Save listing / company Meta Box data
     */
    public static function save_listing_meta_boxes( $post_id, $post ) {
        if ( ! isset( $_POST['vb_listing_meta_nonce'] ) || ! wp_verify_nonce( $_POST['vb_listing_meta_nonce'], 'vb_listing_meta_save' ) ) {
            return;
        }
        if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
            return;
        }
        if ( ! current_user_can( 'edit_post', $post_id ) ) {
            return;
        }

        $type = sanitize_key( $_POST['vb_type'] ?? 'classified' );
        update_post_meta( $post_id, '_vb_type', $type );

        if ( isset( $_POST['vb_phone'] ) ) {
            $phone = sanitize_text_field( $_POST['vb_phone'] );
            update_post_meta( $post_id, '_vb_phone', $phone );
            update_post_meta( $post_id, '_phone', $phone );
            update_post_meta( $post_id, 'phone', $phone );
        }

        if ( isset( $_POST['vb_email'] ) ) {
            $email = sanitize_email( $_POST['vb_email'] );
            update_post_meta( $post_id, '_vb_email', $email );
            update_post_meta( $post_id, '_email', $email );
            update_post_meta( $post_id, 'email', $email );
        }

        if ( isset( $_POST['vb_whatsapp'] ) ) {
            update_post_meta( $post_id, '_vb_whatsapp', sanitize_text_field( $_POST['vb_whatsapp'] ) );
        }

        if ( isset( $_POST['vb_telegram'] ) ) {
            update_post_meta( $post_id, '_vb_telegram', sanitize_text_field( $_POST['vb_telegram'] ) );
        }

        if ( isset( $_POST['vb_price'] ) ) {
            $price = floatval( $_POST['vb_price'] );
            update_post_meta( $post_id, '_vb_price', $price );
            update_post_meta( $post_id, 'price', $price );
        }

        if ( isset( $_POST['vb_address'] ) ) {
            update_post_meta( $post_id, '_vb_address', sanitize_text_field( $_POST['vb_address'] ) );
        }

        if ( isset( $_POST['vb_website'] ) ) {
            $website = esc_url_raw( $_POST['vb_website'] );
            update_post_meta( $post_id, '_vb_website', $website );
            update_post_meta( $post_id, '_website', $website );
        }

        $post = get_post( $post_id );
        $author_id = (int) ( $post ? $post->post_author : 0 );
        $email = sanitize_email( $_POST['vb_email'] ?? '' );
        $is_vladimir = ( 1 === $author_id || strtolower( trim( $email ) ) === 'gin@volny.cz' || strtolower( trim( $email ) ) === 'gin.vladimir@gmail.com' );
        $never_expires = ! empty( $_POST['vb_never_expires'] ) || $is_vladimir;

        if ( $never_expires ) {
            $exp_str = '2099-12-31 23:59:59';
            update_post_meta( $post_id, 'never_expires', 1 );
            update_post_meta( $post_id, '_never_expires', 1 );
            update_post_meta( $post_id, '_vb_never_expires', 1 );
            update_post_meta( $post_id, 'expiry_date', $exp_str );
            update_post_meta( $post_id, '_expiry_date', $exp_str );
            update_post_meta( $post_id, '_vb_expiry_date', $exp_str );
        } elseif ( ! empty( $_POST['vb_expiry_date'] ) ) {
            $exp_str = date( 'Y-m-d 23:59:59', strtotime( $_POST['vb_expiry_date'] ) );
            update_post_meta( $post_id, 'expiry_date', $exp_str );
            update_post_meta( $post_id, '_expiry_date', $exp_str );
            update_post_meta( $post_id, '_vb_expiry_date', $exp_str );
            delete_post_meta( $post_id, 'never_expires' );
            delete_post_meta( $post_id, '_never_expires' );
            delete_post_meta( $post_id, '_vb_never_expires' );
        }
    }

    /**
     * Clean SEO Permalinks: /company/<slug>/ for companies and /ad/<slug>/ for classified ads
     */
    public static function custom_post_type_link( $post_link, $post ) {
        if ( $post && 'vb_listing' === $post->post_type ) {
            $type = get_post_meta( $post->ID, '_vb_type', true );
            if ( 'company' === $type ) {
                return home_url( '/company/' . $post->post_name . '/' );
            } else {
                return home_url( '/ad/' . $post->post_name . '/' );
            }
        }
        return $post_link;
    }

    /**
     * Custom Rewrite Rules for /company/<slug>/ and /ad/<slug>/
     */
    public static function add_custom_rewrite_rules() {
        add_rewrite_rule( '^company/([^/]+)/?$', 'index.php?vb_listing=$matches[1]', 'top' );
        add_rewrite_rule( '^ad/([^/]+)/?$', 'index.php?vb_listing=$matches[1]', 'top' );
    }

    /**
     * Backward compatibility 301 redirects for legacy Czech/Russian URLs
     */
    public static function handle_legacy_redirects() {
        if ( is_admin() || wp_doing_ajax() || wp_doing_cron() || ( defined( 'WP_CLI' ) && WP_CLI ) ) {
            return;
        }

        $uri  = $_SERVER['REQUEST_URI'] ?? '';
        $path = parse_url( $uri, PHP_URL_PATH ) ?: '';

        if ( preg_match( '#^/inzerat/([^/]+)/?#', $path, $m ) ) {
            $slug = sanitize_title( $m[1] );
            $post = get_page_by_path( $slug, OBJECT, 'vb_listing' );
            if ( $post ) {
                $type   = get_post_meta( $post->ID, '_vb_type', true );
                $prefix = ( 'company' === $type ) ? '/company/' : '/ad/';
                wp_safe_redirect( home_url( $prefix . $post->post_name . '/' ), 301 );
                exit;
            }
        } elseif ( preg_match( '#^/inzeraty/?#', $path ) ) {
            wp_safe_redirect( home_url( '/ads/' ), 301 );
            exit;
        } elseif ( preg_match( '#^/kategorie/([^/]+)/?#', $path, $m ) ) {
            $cat_slug = sanitize_title( $m[1] );
            $map = [
                'rabota-i-biznes'     => 'business',
                'biznes-uslugi'       => 'services',
                'avto'                => 'auto',
                'nedvizhimost'        => 'realty',
                'elektronika'         => 'electronics',
                'kompyutery-soft'     => 'computers',
                'uslugi'              => 'services',
                'stroitelstvo-remont' => 'construction',
                'otdyh-turizm'        => 'tourism',
                'moda-i-stil'         => 'fashion',
                'krasota-zdorove'     => 'beauty-health',
                'obuchenie-kursy'     => 'education',
                'dom-i-sad'           => 'home-garden',
                'detskij-mir'         => 'kids',
                'zhivotnye'           => 'pets',
                'dosug-razvlecheniya' => 'leisure',
                'raznoe'              => 'other',
                'znakomstva'          => 'dating',
                'remont-stroitelstvo' => 'construction',
                'ezoterika'           => 'esoterics',
            ];
            $new_slug = $map[ $cat_slug ] ?? $cat_slug;
            wp_safe_redirect( home_url( '/category/' . $new_slug . '/' ), 301 );
            exit;
        } elseif ( preg_match( '#^/mesto/([^/]+)/?#', $path, $m ) ) {
            $loc_slug = sanitize_title( $m[1] );
            $loc_map = [
                'chehiya'         => 'czechia',
                'germaniya'       => 'germany',
                'ispaniya'        => 'spain',
                'franciya'        => 'france',
                'greciya'         => 'greece',
                'vengriya'        => 'hungary',
                'izrail'          => 'israel',
                'italiya'         => 'italy',
                'moldova'         => 'moldova',
                'polsha'          => 'poland',
                'ukraina'         => 'ukraine',
                'praga'           => 'prague',
                'berlin'          => 'berlin',
                'madrid'          => 'madrid',
                'parizh'          => 'paris',
                'afiny'           => 'athens',
                'budapesht'       => 'budapest',
                'ierusalim'       => 'jerusalem',
                'rim'             => 'rome',
                'kishinev'        => 'chisinau',
                'varshava'        => 'warsaw',
                'kiev'            => 'kyiv',
                'internet-onlajn' => 'internet-online',
            ];
            $new_slug = $loc_map[ $loc_slug ] ?? $loc_slug;
            wp_safe_redirect( home_url( '/location/' . $new_slug . '/' ), 301 );
            exit;
        }
    }

    /**
     * Automatic migration of Category & Location slugs to short, clean English
     */
    public static function migrate_terms_to_english() {
        if ( get_option( 'vb_english_slugs_v113' ) === 'yes' ) {
            return;
        }

        $cat_map = [
            'rabota-i-biznes'          => 'business',
            'biznes-uslugi'            => 'services',
            'biznes-proekty'           => 'projects',
            'vakansii-trebuyutsya'     => 'jobs',
            'ishhu-rabotu'             => 'resumes',
            'kursy-obrazovanie'        => 'education',
            'perevody-tekstov'         => 'translations',
            'perevody-kredity-ipoteki' => 'finance',
            'reklama-sajty-seo'        => 'marketing',
            'yuridicheskie-uslugi'     => 'legal',

            'avto'                     => 'auto',
            'legkovye-avto'            => 'cars',
            'gruzovye-avto'            => 'trucks',
            'mototransport'            => 'moto',
            'velotransport'            => 'bikes',
            'avtoperevozki'            => 'transport',
            'avtoremont-i-obsluzhivanie' => 'repair',
            'arenda-avto'              => 'rental',
            'aksessuary-dlya-avto'     => 'accessories',
            'gps-navigatory'           => 'gps',

            'nedvizhimost'             => 'realty',
            'kvartiry'                 => 'apartments',
            'doma-dachi'               => 'houses',
            'zemlya-i-uchastki'        => 'land',
            'novostrojki'              => 'new-buildings',
            'arenda-kvartir'           => 'rent-apartments',
            'arenda-domov'             => 'rent-houses',
            'oteli-restorany'          => 'hotels',
            'uslugi-maklerov'          => 'agents',
            'stroitelstvo'             => 'construction',

            'dlya-doma'                => 'home',
            'mebel'                    => 'furniture',
            'remont-mebeli'            => 'furniture-repair',
            'bytovaya-tehnika'         => 'appliances',
            'odezhda-obuv'             => 'clothing',
            'dlya-detej'               => 'kids',
            'zdorove-lechenie'         => 'health',
            'produkty-i-napitki'       => 'food-drinks',
            'televidenie-iptv'         => 'iptv',

            'elektronika'              => 'electronics',
            'kompyutery-soft'          => 'computers',
            'kompyutery-soft-igry'     => 'pc-games',
            'ofisnaya-tehnika'         => 'office-tech',
            'audio-video-dvd'          => 'audio-video',
            'foto-i-optika'            => 'photo-optics',
            'el-instrument'            => 'tools',
            'remont-elektroniki'       => 'electronics-repair',

            'sredstva-svyazi'          => 'phones',
            'mobilnye-telefony'        => 'mobile-phones',
            'remont-tel'               => 'phone-repair',
            'tarify-sim-karty'         => 'sim-cards',
            'telefony-i-faksy'         => 'landline',
            'ip-telefoniya'            => 'voip',
            'radiosvyaz'               => 'radio',

            'razvlecheniya'            => 'entertainment',
            'otdyh-i-puteshestviya'    => 'travel',
            'sport-turizm'             => 'sport',
            'ohota-rybalka'            => 'hunting-fishing',
            'kuda-pojti'               => 'events',
            'znakomstva'               => 'dating',
            'muzyka-filmy'             => 'movies-music',
            'anekdoty'                 => 'humor',

            'hozyajstvo'               => 'household',
            'oborudovanie'             => 'equipment',
            'stroitelstvo-i-remont'    => 'home-repair',
            'syre-i-materialy'         => 'materials',
            'selskoe-hozyajstvo'       => 'agriculture',
            'hozyajstvennye-raboty'    => 'maintenance',
            'zhivotnye'                => 'pets',

            'raznoe'                   => 'other',
            'ezoterika'                => 'esoterics',
            'otdam-besplatno'          => 'free',
            'poiski-nahodki-podarki'   => 'lost-found',
            'peredachki'               => 'parcels',
            'trebuetsya-pomoshh'       => 'help-needed',
        ];

        foreach ( $cat_map as $old_slug => $new_slug ) {
            $term = get_term_by( 'slug', $old_slug, 'vb_category' );
            if ( $term ) {
                wp_update_term( $term->term_id, 'vb_category', [ 'slug' => $new_slug ] );
                clean_term_cache( $term->term_id, 'vb_category' );
            }
        }

        $loc_map = [
            'chehiya'                                      => 'czechia',
            'germaniya'                                    => 'germany',
            'polsha'                                       => 'poland',
            'franciya'                                     => 'france',
            'ispaniya'                                     => 'spain',
            'italiya'                                      => 'italy',
            'greciya'                                      => 'greece',
            'vengriya'                                     => 'hungary',
            'moldova'                                      => 'moldova',
            'ukraina'                                      => 'ukraine',
            'islandiya'                                    => 'iceland',
            'rossiya'                                      => 'russia',
            'praga'                                        => 'prague',
            'czentralno-cheshskij-kraj-stredocesky-kraj'   => 'central-bohemia',
            'yuzhno-moravskij-kraj-jihomoravsky-kraj-brno' => 'south-moravia',
            'moskva'                                       => 'moscow',
            'kiev'                                         => 'kyiv',
        ];

        foreach ( $loc_map as $old_slug => $new_slug ) {
            $term = get_term_by( 'slug', $old_slug, 'vb_location' );
            if ( $term ) {
                wp_update_term( $term->term_id, 'vb_location', [ 'slug' => $new_slug ] );
                clean_term_cache( $term->term_id, 'vb_location' );
            }
        }

        flush_rewrite_rules( false );
        update_option( 'vb_english_slugs_v113', 'yes' );
    }

    /**
     * Enforce maximum 100 characters for listing and company titles on DB level.
     */
    public static function enforce_max_title_length( $data, $postarr ) {
        if ( isset( $data['post_type'] ) && in_array( $data['post_type'], [ 'vb_listing', 'vb_company' ], true ) ) {
            if ( ! empty( $data['post_title'] ) && mb_strlen( $data['post_title'], 'UTF-8' ) > 100 ) {
                $data['post_title'] = mb_substr( $data['post_title'], 0, 100, 'UTF-8' );
            }
        }
        return $data;
    }

    /**
     * Admin Title character limit and live counter for vb_listing and vb_company.
     */
    public static function render_admin_title_limit_script() {
        $screen = get_current_screen();
        if ( ! $screen || ! in_array( $screen->post_type, [ 'vb_listing', 'vb_company' ], true ) ) {
            return;
        }
        ?>
        <script>
        document.addEventListener('DOMContentLoaded', function() {
            var titleInput = document.getElementById('title');
            if (!titleInput) return;

            titleInput.setAttribute('maxlength', '100');

            var counter = document.createElement('div');
            counter.id = 'vb-title-limit-counter';
            counter.style.cssText = 'font-size: 12px; color: #64748b; text-align: right; margin-top: 5px; font-weight: 500;';
            titleInput.parentNode.appendChild(counter);

            function updateCounter() {
                var len = titleInput.value.length;
                counter.textContent = len + ' / 100 символов (максимальная длина)';
                if (len >= 95) {
                    counter.style.color = '#ef4444';
                } else if (len >= 80) {
                    counter.style.color = '#f59e0b';
                } else {
                    counter.style.color = '#64748b';
                }
            }

            titleInput.addEventListener('input', updateCounter);
            updateCounter();
        });
        </script>
        <?php
    }
}
