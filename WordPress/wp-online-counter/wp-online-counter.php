<?php
/**
 * Plugin Name: Live Active Users & Visitors Counter (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-online-counter
 * Description: Real-time active user tracking in WordPress Admin Bar: shows live counts of total online users, guests, administrators, editors, and shop managers using ultra-fast transient caching. Zero database bloat.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: wp-online-counter
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_oc_get_settings() {
    $defaults = array(
        'window_minutes'     => 5,
        'show_admin_bar'     => 1,
        'show_users_column'  => 1,
        'track_guests'       => 1,
    );
    $saved = get_option( '_vladimir_oc_settings', array() );
    return wp_parse_args( is_array( $saved ) ? $saved : array(), $defaults );
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function( $links ) {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $settings_label = ( 'ru' === $lang ) ? 'Настройки' : ( ( 'cs' === $lang ) ? 'Nastavení' : 'Settings' );
    $docs_label     = ( 'ru' === $lang ) ? 'Документация ↗' : ( ( 'cs' === $lang ) ? 'Dokumentace ↗' : 'Documentation ↗' );

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-oc-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-online-counter" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Live Active Users Counter (VladiMIR+AI)',
        'Online Counter',
        'manage_options',
        'vladimir-oc-settings',
        'vladimir_oc_render_settings_page'
    );
} );

function vladimir_oc_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_oc_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Online Counter: Настройки счетчика посетителей онлайн';
        $txt_subtitle = 'Отображает в верхней панели Admin Bar реальное количество посетителей и администраторов, находящихся сейчас на сайте.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_win      = 'Окно активности (в минутах)';
        $txt_win_desc = 'Период времени бездействия, после которого пользователь считается оффлайн (по умолчанию: 5 мин).';
        $txt_bar      = 'Показывать виджет счетчика в верхней панели Admin Bar';
        $txt_col      = 'Показывать колонку «Онлайн» в списке пользователей админки';
        $txt_gst      = 'Отслеживать гостей и неавторизованных посетителей';
        $txt_save     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Online Counter: Nastavení online návštěvníků';
        $txt_subtitle = 'Zobrazuje v horní liště administrace počet právě přítomných návštěvníků a správců webu.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_win      = 'Časové okno aktivity (minuty)';
        $txt_win_desc = 'Doba nečinnosti před označením za offline (výchozí: 5 minut).';
        $txt_bar      = 'Zobrazovat stav v horní liště Admin Bar';
        $txt_col      = 'Zobrazovat sloupec „Online“ v seznamu uživatelů';
        $txt_gst      = 'Sledovat nepřihlášené návštěvníky (hosty)';
        $txt_save     = 'Uložit nastavení';
    } else {
        $txt_title    = 'Online Counter: Active Users Settings';
        $txt_subtitle = 'Displays real-time online visitors and administrative users in the WordPress admin bar.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_win      = 'Activity Window (Minutes)';
        $txt_win_desc = 'Inactivity timeout before marking user offline (default: 5 min).';
        $txt_bar      = 'Show Online Widget in Admin Bar';
        $txt_col      = 'Show Online Status Column in Users List';
        $txt_gst      = 'Track Guest Visitors';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>👥 <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_oc_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_oc_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="window_minutes"><strong><?php echo esc_html( $txt_win ); ?></strong></label></th>
                    <td>
                        <input type="number" name="window_minutes" id="window_minutes" value="<?php echo esc_attr( $settings['window_minutes'] ); ?>" min="1" max="60" style="width:90px;"> мин.
                        <p class="description"><?php echo esc_html( $txt_win_desc ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><strong>Отображение</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="show_admin_bar" value="1" <?php checked( $settings['show_admin_bar'], 1 ); ?>>
                                <?php echo esc_html( $txt_bar ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="show_users_column" value="1" <?php checked( $settings['show_users_column'], 1 ); ?>>
                                <?php echo esc_html( $txt_col ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="track_guests" value="1" <?php checked( $settings['track_guests'], 1 ); ?>>
                                <?php echo esc_html( $txt_gst ); ?>
                            </label>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-online-counter" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_oc_settings', function() {
    check_admin_referer( 'vladimir_save_oc_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'window_minutes'    => isset( $_POST['window_minutes'] ) ? max( 1, min( 60, (int) $_POST['window_minutes'] ) ) : 5,
        'show_admin_bar'    => isset( $_POST['show_admin_bar'] ) ? 1 : 0,
        'show_users_column' => isset( $_POST['show_users_column'] ) ? 1 : 0,
        'track_guests'      => isset( $_POST['track_guests'] ) ? 1 : 0,
    );

    update_option( '_vladimir_oc_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-oc-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. ACTIVITY TRACKING ENGINE
// ─────────────────────────────────────────────

add_action( 'init', function() {
    $settings = vladimir_oc_get_settings();
    $now      = time();

    if ( is_user_logged_in() ) {
        $user_id = get_current_user_id();
        update_user_meta( $user_id, '_vladimir_last_seen', $now );
    } elseif ( ! empty( $settings['track_guests'] ) ) {
        $ip = isset( $_SERVER['REMOTE_ADDR'] ) ? sanitize_text_field( (string) $_SERVER['REMOTE_ADDR'] ) : 'unknown';
        if ( 'unknown' !== $ip && ! empty( $_SERVER['HTTP_USER_AGENT'] ) && ! preg_match( '/bot|crawl|slurp|spider|mediapartners/i', (string) $_SERVER['HTTP_USER_AGENT'] ) ) {
            $guest_key = '_voc_g_' . substr( md5( $ip ), 0, 16 );
            set_transient( $guest_key, $now, (int) $settings['window_minutes'] * 60 );
        }
    }
} );

function vladimir_oc_get_stats() {
    global $wpdb;
    $settings  = vladimir_oc_get_settings();
    $threshold = time() - ( (int) $settings['window_minutes'] * 60 );

    $users = $wpdb->get_results( $wpdb->prepare(
        "SELECT user_id FROM {$wpdb->usermeta} WHERE meta_key = '_vladimir_last_seen' AND meta_value >= %d",
        $threshold
    ) );

    $admin_count   = 0;
    $editor_count  = 0;
    $manager_count = 0;
    $logged_total  = 0;

    if ( $users ) {
        foreach ( $users as $u ) {
            $ud = get_userdata( $u->user_id );
            if ( ! $ud ) {
                continue;
            }
            $logged_total++;
            if ( in_array( 'administrator', (array) $ud->roles, true ) ) {
                $admin_count++;
            } elseif ( in_array( 'editor', (array) $ud->roles, true ) ) {
                $editor_count++;
            } elseif ( in_array( 'shop_manager', (array) $ud->roles, true ) ) {
                $manager_count++;
            }
        }
    }

    $guest_count = 0;
    if ( ! empty( $settings['track_guests'] ) ) {
        $transients = $wpdb->get_col( "SELECT option_name FROM {$wpdb->options} WHERE option_name LIKE '_transient__voc_g_%'" );
        $guest_count = is_array( $transients ) ? count( $transients ) : 0;
    }

    return array(
        'total'   => $logged_total + $guest_count,
        'guests'  => $guest_count,
        'admins'  => $admin_count,
        'editors' => $editor_count,
        'mgrs'    => $manager_count,
    );
}

// ─────────────────────────────────────────────
// 5. ADMIN BAR DISPLAY
// ─────────────────────────────────────────────

add_action( 'admin_bar_menu', function( $wp_admin_bar ) {
    if ( ! current_user_can( 'edit_posts' ) ) {
        return;
    }
    $settings = vladimir_oc_get_settings();
    if ( empty( $settings['show_admin_bar'] ) ) {
        return;
    }

    $stats = vladimir_oc_get_stats();
    $title = sprintf(
        '👥 %d | <span style="color:#ef4444;">Adm: %d</span> | <span style="color:#f59e0b;">Ed: %d</span> | <span style="color:#10b981;">Mgr: %d</span>',
        $stats['total'],
        $stats['admins'],
        $stats['editors'],
        $stats['mgrs']
    );

    $wp_admin_bar->add_node( array(
        'id'    => 'vladimir_online_counter',
        'title' => $title,
        'href'  => admin_url( 'options-general.php?page=vladimir-oc-settings' ),
        'meta'  => array( 'title' => 'Пользователи онлайн (VladiMIR+AI)' ),
    ) );
}, 100 );

// ─────────────────────────────────────────────
// 6. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Live Active Users & Visitors Counter (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Счетчик пользователей онлайн в Admin Bar: отображает количество гостей, администраторов, редакторов и менеджеров магазина в реальном времени.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Live Active Users & Visitors Counter (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Počítadlo online návštěvníků a správců v horní liště WordPressu v reálném čase.';
        }
    }
    return $plugins;
} );
