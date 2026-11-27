<?php
/**
 * Plugin Name: Site Traffic & Visitor Analytics (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/plugins/tree/main/wp-site-stats
 * Description: Ultra-lightweight, privacy-friendly, self-hosted web analytics dashboard. Zero cookies, zero third-party tracking, zero bloat. Dedicated admin-only statistics.
 * Version:     2026-11__1.00
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-site-stats
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-site-stats
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-i18n.php';
}

// ─────────────────────────────────────────────
// 1. ACTIVATION & DATABASE MIGRATION
// ─────────────────────────────────────────────

register_activation_hook( __FILE__, 'vladimir_ss_activate' );
function vladimir_ss_activate() {
    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';
    $charset_collate = $wpdb->get_charset_collate();

    $sql = "CREATE TABLE $table_name (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        hit_date DATE NOT NULL,
        hit_time INT UNSIGNED NOT NULL,
        page_url VARCHAR(255) NOT NULL,
        page_title VARCHAR(255) DEFAULT '',
        visitor_hash CHAR(32) NOT NULL,
        referrer VARCHAR(255) DEFAULT '',
        referrer_domain VARCHAR(100) DEFAULT '',
        device_type VARCHAR(20) NOT NULL DEFAULT 'desktop',
        browser VARCHAR(50) DEFAULT '',
        os VARCHAR(50) DEFAULT '',
        country CHAR(2) DEFAULT 'XX',
        PRIMARY KEY (id),
        KEY idx_date_page (hit_date, page_url(191)),
        KEY idx_date_visitor (hit_date, visitor_hash),
        KEY idx_hit_date (hit_date),
        KEY idx_referrer (referrer_domain)
    ) $charset_collate;";

    require_once ABSPATH . 'wp-admin/includes/upgrade.php';
    dbDelta( $sql );

    if ( ! wp_next_scheduled( 'vladimir_ss_daily_cleanup_cron' ) ) {
        wp_schedule_event( time() + 3600, 'daily', 'vladimir_ss_daily_cleanup_cron' );
    }
}

register_deactivation_hook( __FILE__, 'vladimir_ss_deactivate' );
function vladimir_ss_deactivate() {
    $timestamp = wp_next_scheduled( 'vladimir_ss_daily_cleanup_cron' );
    if ( $timestamp ) {
        wp_unschedule_event( $timestamp, 'vladimir_ss_daily_cleanup_cron' );
    }
}

// Daily retention purge (retain 90 days)
add_action( 'vladimir_ss_daily_cleanup_cron', 'vladimir_ss_purge_old_data' );
function vladimir_ss_purge_old_data() {
    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';
    $cutoff = gmdate( 'Y-m-d', strtotime( '-90 days' ) );
    $wpdb->query( $wpdb->prepare( "DELETE FROM $table_name WHERE hit_date < %s", $cutoff ) );
}

// ─────────────────────────────────────────────
// 2. FRONTEND TRACKING BEACON
// ─────────────────────────────────────────────

add_action( 'wp_footer', 'vladimir_ss_render_tracking_script', 999 );
function vladimir_ss_render_tracking_script() {
    // Exclude logged in admins from skewing traffic statistics
    if ( is_user_logged_in() && current_user_can( 'manage_options' ) ) {
        return;
    }

    $ajax_url = admin_url( 'admin-ajax.php?action=vladimir_ss_track' );
    $nonce    = wp_create_nonce( 'vladimir_ss_track_nonce' );
    ?>
    <script id="vladimir-ss-tracker">
    (function(){
        try {
            if (navigator.webdriver) return;
            var path = window.location.pathname + window.location.search;
            var ref  = document.referrer || '';
            var title = (document.title || '').substring(0, 150);
            var payload = JSON.stringify({
                action: 'vladimir_ss_track',
                nonce: '<?php echo esc_js( $nonce ); ?>',
                url: path,
                title: title,
                ref: ref,
                screen: (window.screen ? window.screen.width + 'x' + window.screen.height : '')
            });
            var endpoint = '<?php echo esc_url( $ajax_url ); ?>';
            if (navigator.sendBeacon) {
                var blob = new Blob([payload], {type: 'application/json'});
                navigator.sendBeacon(endpoint, blob);
            } else {
                var xhr = new XMLHttpRequest();
                xhr.open('POST', endpoint, true);
                xhr.setRequestHeader('Content-Type', 'application/json');
                xhr.send(payload);
            }
        } catch(e) {}
    })();
    </script>
    <?php
}

// ─────────────────────────────────────────────
// 3. TRACKING HANDLER (AJAX BEACON)
// ─────────────────────────────────────────────

add_action( 'wp_ajax_nopriv_vladimir_ss_track', 'vladimir_ss_handle_hit' );
add_action( 'wp_ajax_vladimir_ss_track', 'vladimir_ss_handle_hit' );

function vladimir_ss_handle_hit() {
    $raw = file_get_contents( 'php://input' );
    $data = json_decode( $raw, true );
    if ( ! is_array( $data ) ) {
        $data = $_POST;
    }

    $nonce = isset( $data['nonce'] ) ? sanitize_text_field( $data['nonce'] ) : '';
    if ( ! wp_verify_nonce( $nonce, 'vladimir_ss_track_nonce' ) ) {
        wp_send_json_error( 'invalid_nonce', 403 );
    }

    $ua = isset( $_SERVER['HTTP_USER_AGENT'] ) ? sanitize_text_field( $_SERVER['HTTP_USER_AGENT'] ) : '';

    // Filter out bots and crawlers
    if ( vladimir_ss_is_bot( $ua ) ) {
        wp_send_json_success( array( 'status' => 'bot_ignored' ) );
    }

    // IP Extraction (Cloudflare / Reverse Proxy aware)
    $ip = vladimir_ss_get_client_ip();

    // Rotating anonymized salt (GDPR cookieless identity)
    $salt = get_option( 'vladimir_ss_salt' );
    if ( ! $salt ) {
        $salt = wp_generate_password( 32, true, true );
        update_option( 'vladimir_ss_salt', $salt, false );
    }
    $visitor_hash = md5( $ip . $ua . gmdate('Y-m') . $salt );

    // Country extraction (Cloudflare / Server GeoIP)
    $country = 'XX';
    if ( ! empty( $_SERVER['HTTP_CF_IPCOUNTRY'] ) ) {
        $country = strtoupper( substr( sanitize_text_field( $_SERVER['HTTP_CF_IPCOUNTRY'] ), 0, 2 ) );
    } elseif ( ! empty( $_SERVER['GEOIP_COUNTRY_CODE'] ) ) {
        $country = strtoupper( substr( sanitize_text_field( $_SERVER['GEOIP_COUNTRY_CODE'] ), 0, 2 ) );
    }

    // Device, OS, Browser parsing
    $device  = vladimir_ss_detect_device( $ua );
    $browser = vladimir_ss_detect_browser( $ua );
    $os      = vladimir_ss_detect_os( $ua );

    // Page URL & Title
    $raw_url = isset( $data['url'] ) ? sanitize_text_field( $data['url'] ) : '/';
    $page_url = substr( $raw_url, 0, 255 );
    $page_title = isset( $data['title'] ) ? sanitize_text_field( $data['title'] ) : '';
    $page_title = substr( $page_title, 0, 255 );

    // Referrer & Referrer domain
    $ref = isset( $data['ref'] ) ? esc_url_raw( $data['ref'] ) : '';
    $ref_domain = 'Direct / None';
    if ( ! empty( $ref ) ) {
        $parsed_host = parse_url( $ref, PHP_URL_HOST );
        if ( $parsed_host ) {
            $parsed_host = preg_replace( '/^www\./', '', strtolower( $parsed_host ) );
            $site_host   = preg_replace( '/^www\./', '', strtolower( parse_url( home_url(), PHP_URL_HOST ) ) );
            if ( $parsed_host === $site_host ) {
                $ref = '';
                $ref_domain = 'Direct / Internal';
            } else {
                $ref_domain = substr( $parsed_host, 0, 100 );
            }
        }
    }

    $ref = substr( $ref, 0, 255 );

    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';
    $now_time   = current_time( 'timestamp' );
    $hit_date   = gmdate( 'Y-m-d', $now_time );

    $wpdb->insert(
        $table_name,
        array(
            'hit_date'        => $hit_date,
            'hit_time'        => $now_time,
            'page_url'        => $page_url,
            'page_title'      => $page_title,
            'visitor_hash'    => $visitor_hash,
            'referrer'        => $ref,
            'referrer_domain' => $ref_domain,
            'device_type'     => $device,
            'browser'         => $browser,
            'os'              => $os,
            'country'         => $country,
        ),
        array( '%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s' )
    );

    wp_send_json_success( array( 'status' => 'tracked' ) );
}

function vladimir_ss_get_client_ip() {
    $headers = array( 'HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'REMOTE_ADDR' );
    foreach ( $headers as $h ) {
        if ( ! empty( $_SERVER[$h] ) ) {
            $ip_list = explode( ',', $_SERVER[$h] );
            $ip = trim( $ip_list[0] );
            if ( filter_var( $ip, FILTER_VALIDATE_IP ) ) {
                return $ip;
            }
        }
    }
    return '127.0.0.1';
}

function vladimir_ss_is_bot( $ua ) {
    if ( empty( $ua ) ) {
        return true;
    }
    $bots = array(
        'bot', 'crawl', 'spider', 'slurp', 'mediapartners', 'feed', 'yandex',
        'seznam', 'googlebot', 'bingbot', 'baiduspider', 'facebookexternalhit',
        'twitterbot', 'rogerbot', 'semrushbot', 'ahrefsbot', 'dotbot', 'uptime',
        'curl', 'wget', 'python', 'headless', 'lighthouse'
    );
    $ua_lower = strtolower( $ua );
    foreach ( $bots as $b ) {
        if ( strpos( $ua_lower, $b ) !== false ) {
            return true;
        }
    }
    return false;
}

function vladimir_ss_detect_device( $ua ) {
    if ( preg_match( '/(ipad|tablet|(android(?!.*mobile))|(windows(?!.*phone)(.*touch))|kindle|playbook|silk|(puffin(?!.*(IP|AP|WP))))/i', $ua ) ) {
        return 'tablet';
    }
    if ( preg_match( '/(mobi|iphone|ipod|blackberry|opera mini|iemobile|mobile)/i', $ua ) ) {
        return 'mobile';
    }
    return 'desktop';
}

function vladimir_ss_detect_browser( $ua ) {
    if ( preg_match( '/Edg/i', $ua ) ) return 'Edge';
    if ( preg_match( '/OPR|Opera/i', $ua ) ) return 'Opera';
    if ( preg_match( '/SamsungBrowser/i', $ua ) ) return 'Samsung Internet';
    if ( preg_match( '/Chrome/i', $ua ) ) return 'Chrome';
    if ( preg_match( '/Firefox/i', $ua ) ) return 'Firefox';
    if ( preg_match( '/Safari/i', $ua ) ) return 'Safari';
    return 'Other';
}

function vladimir_ss_detect_os( $ua ) {
    if ( preg_match( '/windows nt 10/i', $ua ) ) return 'Windows 10/11';
    if ( preg_match( '/windows nt/i', $ua ) ) return 'Windows';
    if ( preg_match( '/iphone|ipad|ipod/i', $ua ) ) return 'iOS';
    if ( preg_match( '/android/i', $ua ) ) return 'Android';
    if ( preg_match( '/macintosh|mac os x/i', $ua ) ) return 'macOS';
    if ( preg_match( '/linux/i', $ua ) ) return 'Linux';
    return 'Other';
}

// ─────────────────────────────────────────────
// 4. ADMIN DASHBOARD & MENU
// ─────────────────────────────────────────────

add_action( 'admin_menu', 'vladimir_ss_add_admin_menu' );
function vladimir_ss_add_admin_menu() {
    add_menu_page(
        __( 'Статистика сайта', 'wp-site-stats' ),
        __( 'Статистика', 'wp-site-stats' ),
        'manage_options',
        'site-stats',
        'vladimir_ss_render_dashboard',
        'dashicons-chart-area',
        3
    );
}

function vladimir_ss_render_dashboard() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( esc_html__( 'Доступ ограничен администратором.', 'wp-site-stats' ) );
    }

    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';

    // Handle stats reset if requested
    if ( isset( $_POST['vladimir_ss_reset_action'] ) && check_admin_referer( 'vladimir_ss_reset_nonce' ) ) {
        $wpdb->query( "TRUNCATE TABLE $table_name" );
        echo '<div class="notice notice-success is-dismissible"><p>' . esc_html__( 'Статистика успешно сброшена.', 'wp-site-stats' ) . '</p></div>';
    }

    $range = isset( $_GET['range'] ) ? sanitize_text_field( $_GET['range'] ) : '7d';
    $today = gmdate( 'Y-m-d', current_time( 'timestamp' ) );

    switch ( $range ) {
        case 'today':
            $start_date = $today;
            $range_title = 'Сегодня (' . date_i18n( 'j F Y' ) . ')';
            $days_count = 1;
            break;
        case 'yesterday':
            $start_date = gmdate( 'Y-m-d', strtotime( '-1 day', current_time( 'timestamp' ) ) );
            $today = $start_date;
            $range_title = 'Вчера (' . date_i18n( 'j F Y', strtotime( '-1 day' ) ) . ')';
            $days_count = 1;
            break;
        case '30d':
            $start_date = gmdate( 'Y-m-d', strtotime( '-29 days', current_time( 'timestamp' ) ) );
            $range_title = 'Последние 30 дней';
            $days_count = 30;
            break;
        case '7d':
        default:
            $range = '7d';
            $start_date = gmdate( 'Y-m-d', strtotime( '-6 days', current_time( 'timestamp' ) ) );
            $range_title = 'Последние 7 дней';
            $days_count = 7;
            break;
    }

    // High level metrics
    $total_views = (int) $wpdb->get_var( $wpdb->prepare(
        "SELECT COUNT(*) FROM $table_name WHERE hit_date >= %s AND hit_date <= %s",
        $start_date, $today
    ) );

    $unique_visitors = (int) $wpdb->get_var( $wpdb->prepare(
        "SELECT COUNT(DISTINCT visitor_hash) FROM $table_name WHERE hit_date >= %s AND hit_date <= %s",
        $start_date, $today
    ) );

    $pages_per_visit = $unique_visitors > 0 ? round( $total_views / $unique_visitors, 2 ) : 0;

    // Daily breakdown for SVG chart
    $daily_stats = $wpdb->get_results( $wpdb->prepare(
        "SELECT hit_date, COUNT(*) as views, COUNT(DISTINCT visitor_hash) as visitors
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY hit_date
         ORDER BY hit_date ASC",
        $start_date, $today
    ), ARRAY_A );

    $chart_map = array();
    foreach ( $daily_stats as $row ) {
        $chart_map[$row['hit_date']] = array(
            'views' => (int) $row['views'],
            'visitors' => (int) $row['visitors']
        );
    }

    // Top Pages
    $top_pages = $wpdb->get_results( $wpdb->prepare(
        "SELECT page_url, page_title, COUNT(*) as views, COUNT(DISTINCT visitor_hash) as visitors
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY page_url
         ORDER BY views DESC
         LIMIT 10",
        $start_date, $today
    ), ARRAY_A );

    // Top Referrers
    $top_referrers = $wpdb->get_results( $wpdb->prepare(
        "SELECT referrer_domain, COUNT(*) as views
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s AND referrer_domain != '' AND referrer_domain != 'Direct / Internal'
         GROUP BY referrer_domain
         ORDER BY views DESC
         LIMIT 10",
        $start_date, $today
    ), ARRAY_A );

    // Top Countries
    $top_countries = $wpdb->get_results( $wpdb->prepare(
        "SELECT country, COUNT(*) as views, COUNT(DISTINCT visitor_hash) as visitors
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY country
         ORDER BY views DESC
         LIMIT 8",
        $start_date, $today
    ), ARRAY_A );

    // Devices & Browsers
    $devices = $wpdb->get_results( $wpdb->prepare(
        "SELECT device_type, COUNT(*) as count
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY device_type
         ORDER BY count DESC",
        $start_date, $today
    ), ARRAY_A );

    $browsers = $wpdb->get_results( $wpdb->prepare(
        "SELECT browser, COUNT(*) as count
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY browser
         ORDER BY count DESC
         LIMIT 5",
        $start_date, $today
    ), ARRAY_A );

    $flag_names = array(
        'CZ' => '🇨🇿 Чехия',
        'SK' => '🇸🇰 Словакия',
        'DE' => '🇩🇪 Германия',
        'UA' => '🇺🇦 Украина',
        'PL' => '🇵🇱 Польша',
        'AT' => '🇦🇹 Австрия',
        'RU' => '🇷🇺 Россия',
        'US' => '🇺🇸 США',
        'GB' => '🇬🇧 Великобритания',
        'XX' => '🌐 Локальный / Неизвестно'
    );
    ?>
    <div class="wrap vladimir-ss-wrap">
        <div class="vladimir-ss-header">
            <div class="vladimir-ss-header-title">
                <h1>📊 <?php esc_html_e( 'Статистика посещаемости (VladiMIR+AI)', 'wp-site-stats' ); ?></h1>
                <p class="description"><?php esc_html_e( 'Легковесная, конфиденциальная аналитика без cookies и сторонних серверов. Доступно только администраторам.', 'wp-site-stats' ); ?></p>
            </div>
            <div class="vladimir-ss-range-nav">
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=today' ) ); ?>" class="button <?php echo $range === 'today' ? 'button-primary' : ''; ?>">Сегодня</a>
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=yesterday' ) ); ?>" class="button <?php echo $range === 'yesterday' ? 'button-primary' : ''; ?>">Вчера</a>
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=7d' ) ); ?>" class="button <?php echo $range === '7d' ? 'button-primary' : ''; ?>">7 дней</a>
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=30d' ) ); ?>" class="button <?php echo $range === '30d' ? 'button-primary' : ''; ?>">30 дней</a>
            </div>
        </div>

        <!-- KPI SUMMARY CARDS -->
        <div class="vladimir-ss-cards">
            <div class="vladimir-ss-card">
                <div class="card-label">👥 Уникальные посетители</div>
                <div class="card-val"><?php echo number_format_i18n( $unique_visitors ); ?></div>
                <div class="card-sub"><?php echo esc_html( $range_title ); ?></div>
            </div>
            <div class="vladimir-ss-card">
                <div class="card-label">👁️ Просмотры страниц</div>
                <div class="card-val"><?php echo number_format_i18n( $total_views ); ?></div>
                <div class="card-sub"><?php echo esc_html( $range_title ); ?></div>
            </div>
            <div class="vladimir-ss-card">
                <div class="card-label">📄 Глубина (стр./посетитель)</div>
                <div class="card-val"><?php echo esc_html( $pages_per_visit ); ?></div>
                <div class="card-sub">Среднее вовлечение</div>
            </div>
            <div class="vladimir-ss-card">
                <div class="card-label">🚀 Главный источник</div>
                <div class="card-val" style="font-size: 20px;">
                    <?php echo ! empty( $top_referrers[0]['referrer_domain'] ) ? esc_html( $top_referrers[0]['referrer_domain'] ) : 'Прямые заходы'; ?>
                </div>
                <div class="card-sub"><?php echo ! empty( $top_referrers[0]['views'] ) ? esc_html( $top_referrers[0]['views'] . ' переходов' ) : '100% Direct'; ?></div>
            </div>
        </div>

        <!-- TIMELINE CHART (SVG) -->
        <div class="vladimir-ss-box">
            <h2>📈 Динамика трафика (<?php echo esc_html( $range_title ); ?>)</h2>
            <div class="vladimir-ss-chart-container">
                <?php
                // Generate chronological days list
                $chart_labels = array();
                $chart_views  = array();
                $chart_users  = array();
                $max_val = 1;

                for ( $i = $days_count - 1; $i >= 0; $i-- ) {
                    $d = gmdate( 'Y-m-d', strtotime( "-$i days", strtotime( $today ) ) );
                    $v = isset( $chart_map[$d] ) ? $chart_map[$d]['views'] : 0;
                    $u = isset( $chart_map[$d] ) ? $chart_map[$d]['visitors'] : 0;
                    $chart_labels[] = date_i18n( 'd.m', strtotime( $d ) );
                    $chart_views[]  = $v;
                    $chart_users[]  = $u;
                    if ( $v > $max_val ) $max_val = $v;
                    if ( $u > $max_val ) $max_val = $u;
                }

                $svg_w = 900;
                $svg_h = 220;
                $pad_l = 40;
                $pad_r = 20;
                $pad_t = 20;
                $pad_b = 35;
                $plot_w = $svg_w - $pad_l - $pad_r;
                $plot_h = $svg_h - $pad_t - $pad_b;
                $count = count( $chart_labels );
                $step_x = $count > 1 ? $plot_w / ( $count - 1 ) : $plot_w;

                $pts_views = array();
                $pts_users = array();
                for ( $idx = 0; $idx < $count; $idx++ ) {
                    $x = $pad_l + ( $idx * $step_x );
                    $y_v = $pad_t + $plot_h - ( ( $chart_views[$idx] / $max_val ) * $plot_h );
                    $y_u = $pad_t + $plot_h - ( ( $chart_users[$idx] / $max_val ) * $plot_h );
                    $pts_views[] = "$x,$y_v";
                    $pts_users[] = "$x,$y_u";
                }
                $polyline_views = implode( ' ', $pts_views );
                $polyline_users = implode( ' ', $pts_users );
                ?>
                <svg viewBox="0 0 <?php echo $svg_w; ?> <?php echo $svg_h; ?>" class="vladimir-ss-svg">
                    <!-- Grid Lines -->
                    <line x1="<?php echo $pad_l; ?>" y1="<?php echo $pad_t; ?>" x2="<?php echo $svg_w - $pad_r; ?>" y2="<?php echo $pad_t; ?>" stroke="#eee" stroke-dasharray="4"/>
                    <line x1="<?php echo $pad_l; ?>" y1="<?php echo $pad_t + ($plot_h/2); ?>" x2="<?php echo $svg_w - $pad_r; ?>" y2="<?php echo $pad_t + ($plot_h/2); ?>" stroke="#eee" stroke-dasharray="4"/>
                    <line x1="<?php echo $pad_l; ?>" y1="<?php echo $pad_t + $plot_h; ?>" x2="<?php echo $svg_w - $pad_r; ?>" y2="<?php echo $pad_t + $plot_h; ?>" stroke="#ccc"/>

                    <!-- Y-Axis labels -->
                    <text x="<?php echo $pad_l - 8; ?>" y="<?php echo $pad_t + 4; ?>" text-anchor="end" font-size="11" fill="#888"><?php echo $max_val; ?></text>
                    <text x="<?php echo $pad_l - 8; ?>" y="<?php echo $pad_t + ($plot_h/2) + 4; ?>" text-anchor="end" font-size="11" fill="#888"><?php echo round($max_val/2); ?></text>
                    <text x="<?php echo $pad_l - 8; ?>" y="<?php echo $pad_t + $plot_h + 4; ?>" text-anchor="end" font-size="11" fill="#888">0</text>

                    <!-- Views Polyline (Blue) -->
                    <polyline points="<?php echo $polyline_views; ?>" fill="none" stroke="#2271b1" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
                    <!-- Visitors Polyline (Green) -->
                    <polyline points="<?php echo $polyline_users; ?>" fill="none" stroke="#00a32a" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>

                    <!-- Data dots and X labels -->
                    <?php for ( $idx = 0; $idx < $count; $idx++ ):
                        $x = $pad_l + ( $idx * $step_x );
                        $y_v = $pad_t + $plot_h - ( ( $chart_views[$idx] / $max_val ) * $plot_h );
                        $y_u = $pad_t + $plot_h - ( ( $chart_users[$idx] / $max_val ) * $plot_h );
                    ?>
                        <circle cx="<?php echo $x; ?>" cy="<?php echo $y_v; ?>" r="4" fill="#2271b1"/>
                        <circle cx="<?php echo $x; ?>" cy="<?php echo $y_u; ?>" r="4" fill="#00a32a"/>
                        <text x="<?php echo $x; ?>" y="<?php echo $svg_h - 10; ?>" text-anchor="middle" font-size="11" fill="#666"><?php echo $chart_labels[$idx]; ?></text>
                    <?php endfor; ?>
                </svg>
                <div class="vladimir-ss-chart-legend">
                    <span class="legend-item"><span class="legend-color" style="background: #2271b1;"></span> Просмотры (Views)</span>
                    <span class="legend-item"><span class="legend-color" style="background: #00a32a;"></span> Посетители (Unique Visitors)</span>
                </div>
            </div>
        </div>

        <!-- DETAILS GRID -->
        <div class="vladimir-ss-grid">
            <!-- Top Pages -->
            <div class="vladimir-ss-box">
                <h2>📄 Популярные страницы</h2>
                <?php if ( empty( $top_pages ) ): ?>
                    <p class="description">Пока нет зафиксированных переходов за выбранный период.</p>
                <?php else: ?>
                    <table class="widefat striped">
                        <thead>
                            <tr>
                                <th>Страница</th>
                                <th style="width: 90px; text-align: right;">Хиты</th>
                                <th style="width: 90px; text-align: right;">Уники</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ( $top_pages as $p ): ?>
                            <tr>
                                <td>
                                    <a href="<?php echo esc_url( home_url( $p['page_url'] ) ); ?>" target="_blank" style="font-weight: 500;">
                                        <?php echo esc_html( ! empty( $p['page_title'] ) ? $p['page_title'] : $p['page_url'] ); ?>
                                    </a>
                                    <div class="page-slug" style="font-size: 11px; color: #888;"><?php echo esc_html( $p['page_url'] ); ?></div>
                                </td>
                                <td style="text-align: right; font-weight: 600; color: #2271b1;"><?php echo number_format_i18n( $p['views'] ); ?></td>
                                <td style="text-align: right; color: #00a32a;"><?php echo number_format_i18n( $p['visitors'] ); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>

            <!-- Top Referrers -->
            <div class="vladimir-ss-box">
                <h2>🔗 Источники трафика (Referrers)</h2>
                <?php if ( empty( $top_referrers ) ): ?>
                    <p class="description">Внешних рефереров пока не зафиксировано (прямой трафик / Direct).</p>
                <?php else: ?>
                    <table class="widefat striped">
                        <thead>
                            <tr>
                                <th>Источник</th>
                                <th style="width: 100px; text-align: right;">Переходов</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ( $top_referrers as $r ): ?>
                            <tr>
                                <td><strong><?php echo esc_html( $r['referrer_domain'] ); ?></strong></td>
                                <td style="text-align: right; font-weight: 600; color: #2271b1;"><?php echo number_format_i18n( $r['views'] ); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>

            <!-- Countries -->
            <div class="vladimir-ss-box">
                <h2>🌍 География посетителей</h2>
                <?php if ( empty( $top_countries ) ): ?>
                    <p class="description">Данных о странах пока нет.</p>
                <?php else: ?>
                    <table class="widefat striped">
                        <thead>
                            <tr>
                                <th>Страна</th>
                                <th style="width: 80px; text-align: right;">Просмотры</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ( $top_countries as $c ):
                                $c_name = isset( $flag_names[$c['country']] ) ? $flag_names[$c['country']] : '🏳️ ' . $c['country'];
                            ?>
                            <tr>
                                <td><strong><?php echo esc_html( $c_name ); ?></strong></td>
                                <td style="text-align: right; font-weight: 600;"><?php echo number_format_i18n( $c['views'] ); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>

            <!-- Devices & Browsers -->
            <div class="vladimir-ss-box">
                <h2>📱 Устройства и браузеры</h2>
                <div style="margin-bottom: 15px;">
                    <h4 style="margin: 0 0 8px 0;">Устройства:</h4>
                    <?php if ( empty( $devices ) ): ?>
                        <p class="description">Нет данных.</p>
                    <?php else: ?>
                        <?php foreach ( $devices as $dev ):
                            $icon = $dev['device_type'] === 'mobile' ? '📱 Mobile' : ( $dev['device_type'] === 'tablet' ? '📟 Tablet' : '💻 Desktop' );
                        ?>
                            <div style="display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #f0f0f1;">
                                <span><?php echo esc_html( $icon ); ?></span>
                                <span style="font-weight: 600;"><?php echo number_format_i18n( $dev['count'] ); ?></span>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>

                <div>
                    <h4 style="margin: 15px 0 8px 0;">Браузеры:</h4>
                    <?php if ( empty( $browsers ) ): ?>
                        <p class="description">Нет данных.</p>
                    <?php else: ?>
                        <?php foreach ( $browsers as $b ): ?>
                            <div style="display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #f0f0f1;">
                                <span>🌐 <?php echo esc_html( $b['browser'] ); ?></span>
                                <span style="font-weight: 600;"><?php echo number_format_i18n( $b['count'] ); ?></span>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>
            </div>
        </div>

        <!-- MAINTENANCE & RESET -->
        <div class="vladimir-ss-footer">
            <form method="post" onsubmit="return confirm('Вы уверены, что хотите полностью очистить всю историю статистики?');">
                <?php wp_nonce_field( 'vladimir_ss_reset_nonce' ); ?>
                <input type="hidden" name="vladimir_ss_reset_action" value="1">
                <button type="submit" class="button button-link-delete" style="color: #b32d2e; text-decoration: none;">
                    🗑️ Сбросить всю статистику
                </button>
            </form>
            <div style="font-size: 12px; color: #888;">
                Разработано: VladiMIR (GinCz) + AI | Хранение: 90 дней (автоочистка) | Cookieless GDPR
            </div>
        </div>
    </div>

    <style>
    .vladimir-ss-wrap { max-width: 1200px; margin-top: 20px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif; }
    .vladimir-ss-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; flex-wrap: wrap; gap: 15px; }
    .vladimir-ss-header h1 { margin: 0 0 5px 0; font-size: 24px; font-weight: 700; color: #1d2327; }
    .vladimir-ss-range-nav .button { padding: 4px 14px; height: 34px; font-weight: 500; }
    .vladimir-ss-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 15px; margin-bottom: 25px; }
    .vladimir-ss-card { background: #fff; border: 1px solid #c3c4c7; border-radius: 8px; padding: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
    .vladimir-ss-card .card-label { font-size: 13px; color: #646970; font-weight: 600; margin-bottom: 8px; }
    .vladimir-ss-card .card-val { font-size: 32px; font-weight: 700; color: #1d2327; line-height: 1.1; margin-bottom: 6px; }
    .vladimir-ss-card .card-sub { font-size: 12px; color: #8c8f94; }
    .vladimir-ss-box { background: #fff; border: 1px solid #c3c4c7; border-radius: 8px; padding: 20px; margin-bottom: 25px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
    .vladimir-ss-box h2 { margin: 0 0 15px 0; font-size: 16px; font-weight: 600; color: #1d2327; border-bottom: 1px solid #f0f0f1; padding-bottom: 10px; }
    .vladimir-ss-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(380px, 1fr)); gap: 20px; }
    .vladimir-ss-chart-container { width: 100%; overflow-x: auto; }
    .vladimir-ss-svg { width: 100%; height: auto; max-height: 250px; }
    .vladimir-ss-chart-legend { display: flex; justify-content: center; gap: 25px; margin-top: 10px; font-size: 13px; font-weight: 500; }
    .vladimir-ss-chart-legend .legend-item { display: inline-flex; align-items: center; gap: 6px; }
    .vladimir-ss-chart-legend .legend-color { width: 12px; height: 12px; border-radius: 3px; display: inline-block; }
    .vladimir-ss-footer { display: flex; justify-content: space-between; align-items: center; padding: 15px 0; border-top: 1px solid #dcdcde; margin-top: 10px; }
    </style>
    <?php
}
