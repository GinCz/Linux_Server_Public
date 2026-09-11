<?php
/**
 * Plugin Name: WP Online Active Users (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-online-counter
 * Description: Real-time counter of online visitors, administrators, editors, and shop managers in the admin bar, with an online status indicator in the user list before performing site updates.
 * Version:     2026.09.12
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. CONSTANTS
// ─────────────────────────────────────────────
define( 'WP_OC_TIMEOUT',    5 * MINUTE_IN_SECONDS ); // 5 minutes threshold
define( 'WP_OC_META_KEY',   '_vladimir_last_active' );
define( 'WP_OC_GUEST_PFX',  '_vladimir_guest_' );
define( 'WP_OC_ROLES',      [ 'administrator', 'editor', 'shop_manager' ] );

// ─────────────────────────────────────────────
// 2. ACTIVITY TRACKING
// ─────────────────────────────────────────────

// Track logged-in users (throttle DB updates to once per 60s)
add_action( 'init', 'wp_oc_track_user' );
function wp_oc_track_user(): void {
    if ( ! is_user_logged_in() ) {
        return;
    }
    $user_id = get_current_user_id();
    $now     = time();
    $last    = (int) get_user_meta( $user_id, WP_OC_META_KEY, true );

    if ( $now - $last > 60 ) {
        update_user_meta( $user_id, WP_OC_META_KEY, $now );
    }
}

// Track guest visitors via short-lived transients
add_action( 'init', 'wp_oc_track_guest' );
function wp_oc_track_guest(): void {
    if ( is_user_logged_in() || is_admin() ) {
        return;
    }
    $ip = isset( $_SERVER['REMOTE_ADDR'] ) ? sanitize_text_field( wp_unslash( $_SERVER['REMOTE_ADDR'] ) ) : '';
    $ua = isset( $_SERVER['HTTP_USER_AGENT'] ) ? sanitize_text_field( wp_unslash( $_SERVER['HTTP_USER_AGENT'] ) ) : '';
    
    // Ignore common bots to keep count clean
    if ( preg_match( '/(bot|crawl|spider|slurp|facebookexternalhit|bingbot|googlebot)/i', $ua ) ) {
        return;
    }

    $hash = md5( $ip . '|' . $ua );
    set_transient( WP_OC_GUEST_PFX . $hash, time(), WP_OC_TIMEOUT );
}

// ─────────────────────────────────────────────
// 3. COUNTERS & HELPERS
// ─────────────────────────────────────────────

function wp_oc_get_online_users( $role = null ): array {
    $roles  = $role ? (array) $role : WP_OC_ROLES;
    $cutoff = time() - WP_OC_TIMEOUT;

    return get_users( [
        'role__in'     => $roles,
        'meta_key'     => WP_OC_META_KEY,
        'meta_value'   => $cutoff,
        'meta_compare' => '>=',
        'meta_type'    => 'NUMERIC',
        'fields'       => 'all',
    ] );
}

function wp_oc_count_role( string $role ): int {
    return count( wp_oc_get_online_users( $role ) );
}

function wp_oc_count_guests(): int {
    global $wpdb;
    $cutoff = time() - WP_OC_TIMEOUT;
    return (int) $wpdb->get_var( $wpdb->prepare(
        "SELECT COUNT(*) FROM {$wpdb->options}
         WHERE option_name LIKE %s
           AND CAST(option_value AS UNSIGNED) >= %d",
        '_transient_' . WP_OC_GUEST_PFX . '%',
        $cutoff
    ) );
}

function wp_oc_count_total(): int {
    $logged_in = count( wp_oc_get_online_users() );
    $guests    = wp_oc_count_guests();
    return $logged_in + $guests;
}

// ─────────────────────────────────────────────
// 4. ADMIN BAR DISPLAY
// ─────────────────────────────────────────────

add_action( 'admin_bar_menu', 'wp_oc_admin_bar', 100 );
function wp_oc_admin_bar( WP_Admin_Bar $bar ): void {
    if ( ! current_user_can( 'manage_options' ) && ! current_user_can( 'edit_posts' ) ) {
        return;
    }

    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $total    = wp_oc_count_total();
    $admins   = wp_oc_count_role( 'administrator' );
    $editors  = wp_oc_count_role( 'editor' );
    $managers = wp_oc_count_role( 'shop_manager' );

    // Admin bar top label
    $bar_title = sprintf(
        '&#128101; %d &nbsp;|&nbsp; &#128308; Adm: %d &nbsp;|&nbsp; &#128203; Ed: %d &nbsp;|&nbsp; &#128722; Mgr: %d',
        $total,
        $admins,
        $editors,
        $managers
    );

    // Multilingual submenu titles
    if ( 'ru' === $lang ) {
        $hover_title = 'Онлайн за последние 5 минут (Нажмите для перехода к пользователям)';
        $txt_total   = "👥 Всего онлайн: {$total}";
        $txt_adm     = "🔴 Администраторы: {$admins}";
        $txt_ed      = "📋 Редакторы: {$editors}";
        $txt_mgr     = "🛒 Менеджеры магазина: {$managers}";
    } elseif ( 'cs' === $lang ) {
        $hover_title = 'Online za posledních 5 minut (Klikněte pro zobrazení uživatelů)';
        $txt_total   = "👥 Celkem online: {$total}";
        $txt_adm     = "🔴 Administrátoři: {$admins}";
        $txt_ed      = "📋 Editoři: {$editors}";
        $txt_mgr     = "🛒 Správci obchodu: {$managers}";
    } else {
        $hover_title = 'Online in the last 5 minutes (Click to view user list)';
        $txt_total   = "👥 Total Online: {$total}";
        $txt_adm     = "🔴 Administrators: {$admins}";
        $txt_ed      = "📋 Editors: {$editors}";
        $txt_mgr     = "🛒 Shop Managers: {$managers}";
    }

    $main_url = admin_url( 'users.php' );

    $bar->add_node( [
        'id'    => 'wp-online-counter',
        'title' => $bar_title,
        'href'  => $main_url,
        'meta'  => [ 'title' => $hover_title ],
    ] );

    $nodes = [
        [ 'wp-oc-total', $txt_total, $main_url ],
        [ 'wp-oc-adm',   $txt_adm,   admin_url( 'users.php?role=administrator' ) ],
        [ 'wp-oc-ed',    $txt_ed,    admin_url( 'users.php?role=editor' ) ],
        [ 'wp-oc-mgr',   $txt_mgr,   admin_url( 'users.php?role=shop_manager' ) ],
    ];

    foreach ( $nodes as [ $id, $title, $href ] ) {
        $bar->add_node( [
            'id'     => $id,
            'parent' => 'wp-online-counter',
            'title'  => $title,
            'href'   => $href,
        ] );
    }
}

// Styling for admin bar item
add_action( 'admin_head', 'wp_oc_admin_styles' );
add_action( 'wp_head',    'wp_oc_admin_styles' );
function wp_oc_admin_styles(): void {
    if ( ! is_admin_bar_showing() ) {
        return;
    }
    echo '<style>#wpadminbar #wp-admin-bar-wp-online-counter > .ab-item { font-weight: 600; letter-spacing: 0.02em; }</style>';
}

// ─────────────────────────────────────────────
// 5. USER LIST COLUMN & SORTING
// ─────────────────────────────────────────────

add_filter( 'manage_users_columns',          'wp_oc_user_columns' );
add_filter( 'manage_users_custom_column',    'wp_oc_column_content', 10, 3 );
add_filter( 'manage_users_sortable_columns', 'wp_oc_sortable_column' );

function wp_oc_user_columns( array $cols ): array {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );
    
    $label = '🟢 Online';
    if ( 'ru' === $lang ) {
        $label = '🟢 Онлайн';
    } elseif ( 'cs' === $lang ) {
        $label = '🟢 Online stav';
    }

    $new = [];
    foreach ( $cols as $k => $v ) {
        $new[ $k ] = $v;
        if ( $k === 'role' ) {
            $new['wp_oc_status'] = $label;
        }
    }
    return $new ?: array_merge( $cols, [ 'wp_oc_status' => $label ] );
}

function wp_oc_column_content( $out, string $col, int $uid ): string {
    if ( $col !== 'wp_oc_status' ) {
        return $out;
    }

    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $last   = (int) get_user_meta( $uid, WP_OC_META_KEY, true );
    $cutoff = time() - WP_OC_TIMEOUT;

    if ( $last >= $cutoff ) {
        $diff = human_time_diff( $last );
        $title = ( 'ru' === $lang ) ? "Активен {$diff} назад" : ( ( 'cs' === $lang ) ? "Aktivní před {$diff}" : "Active {$diff} ago" );
        $txt   = ( 'ru' === $lang ) ? "● Онлайн" : "● Online";
        return "<span style='color:#00b050;font-weight:700;' title='{$title}'>{$txt}</span>";
    }

    if ( $last > 0 ) {
        $diff = human_time_diff( $last );
        $title = ( 'ru' === $lang ) ? "Был(а) на сайте {$diff} назад" : ( ( 'cs' === $lang ) ? "Byl online před {$diff}" : "Last seen {$diff} ago" );
        $txt   = ( 'ru' === $lang ) ? "{$diff} назад" : ( ( 'cs' === $lang ) ? "před {$diff}" : "{$diff} ago" );
        return "<span style='color:#888;' title='{$title}'>● {$txt}</span>";
    }

    return "<span style='color:#ccc;'>—</span>";
}

function wp_oc_sortable_column( array $cols ): array {
    $cols['wp_oc_status'] = 'wp_oc_status';
    return $cols;
}

add_action( 'pre_get_users', 'wp_oc_sort_users' );
function wp_oc_sort_users( WP_User_Query $q ): void {
    if ( ! is_admin() ) {
        return;
    }
    if ( $q->get( 'orderby' ) === 'wp_oc_status' ) {
        $q->set( 'meta_key', WP_OC_META_KEY );
        $q->set( 'orderby',  'meta_value_num' );
    }
}

// ─────────────────────────────────────────────
// 6. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Активные пользователи онлайн (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Отображает количество онлайн-посетителей, администраторов, редакторов и менеджеров магазина в верхней панели управления, а также статус «Онлайн» в списке пользователей перед проведением обновлений.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Aktivní uživatelé online (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Zobrazuje počet online návštěvníků, administrátorů, editorů a správců obchodu v horní liště a přidává indikátor online stavu do seznamu uživatelů před prováděním aktualizací webu.';
        }
    }
    return $plugins;
} );

// ─────────────────────────────────────────────
// 7. CRON CLEANUP (Daily maintenance)
// ─────────────────────────────────────────────

register_activation_hook( __FILE__, function() {
    if ( ! wp_next_scheduled( 'wp_oc_daily_cleanup' ) ) {
        wp_schedule_event( time(), 'daily', 'wp_oc_daily_cleanup' );
    }
} );

register_deactivation_hook( __FILE__, function() {
    wp_clear_scheduled_hook( 'wp_oc_daily_cleanup' );
} );

add_action( 'wp_oc_daily_cleanup', 'wp_oc_run_cleanup' );
function wp_oc_run_cleanup(): void {
    global $wpdb;
    // Clean user meta older than 30 days
    $cutoff = time() - 30 * DAY_IN_SECONDS;
    $wpdb->query( $wpdb->prepare(
        "DELETE FROM {$wpdb->usermeta} WHERE meta_key = %s AND CAST(meta_value AS UNSIGNED) < %d",
        WP_OC_META_KEY,
        $cutoff
    ) );
    // Clean expired guest transients
    $wpdb->query(
        "DELETE FROM {$wpdb->options}
         WHERE option_name LIKE '_transient_" . WP_OC_GUEST_PFX . "%'
            OR option_name LIKE '_transient_timeout_" . WP_OC_GUEST_PFX . "%'"
    );
}