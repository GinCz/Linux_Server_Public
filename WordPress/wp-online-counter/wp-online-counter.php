<?php
/**
 * Plugin Name: WP Online Active Users (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-online-counter
 * Description: Real-time counter of online visitors, administrators, editors, and shop managers in the admin bar, with an online status indicator in the user list before performing site updates.
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
// 1. DEFAULT SETTINGS & CONSTANTS
// ─────────────────────────────────────────────

define( 'WP_OC_META_KEY',  '_vladimir_last_active' );
define( 'WP_OC_GUEST_PFX', '_vladimir_guest_' );
define( 'WP_OC_ROLES',     array( 'administrator', 'editor', 'shop_manager' ) );

function vladimir_online_counter_get_settings() {
     = array(
        'timeout_minutes'  => 5,
        'track_guests'     => 1,
        'show_admin_bar'   => 1,
        'show_user_column' => 1,
        'bot_filter'       => 1,
    );
     = get_option( '_vladimir_online_counter_settings', array() );
    return wp_parse_args( is_array(  ) ?  : array(),  );
}

function vladimir_oc_timeout_seconds() {
     = vladimir_online_counter_get_settings();
    return max( 1, (int) ['timeout_minutes'] ) * MINUTE_IN_SECONDS;
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function(  ) {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

     = ( 'ru' ===  ) ? 'Настройки' : ( ( 'cs' ===  ) ? 'Nastavení' : 'Settings' );
         = ( 'ru' ===  ) ? 'Документация ↗' : ( ( 'cs' ===  ) ? 'Dokumentace ↗' : 'Documentation ↗' );

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-online-counter-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-online-counter" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Online Counter (VladiMIR+AI)',
        'Онлайн счётчик',
        'manage_options',
        'vladimir-online-counter-settings',
        'vladimir_online_counter_render_settings_page'
    );
} );

function vladimir_online_counter_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_online_counter_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

        = wp_oc_count_total();
       = wp_oc_count_role( 'administrator' );
      = wp_oc_count_role( 'editor' );
     = wp_oc_count_role( 'shop_manager' );
       = wp_oc_count_guests();

    if ( 'ru' ===  ) {
               = 'WP Онлайн Активные Пользователи: Настройки';
                = 'Отслеживание активных посетителей, администраторов и менеджеров в реальном времени.';
               = 'Настройки успешно сохранены!';
             = 'Период активности (таймаут онлайн)';
           = 'Пользователь считается «онлайн», если проявлял активность в течение указанного времени.';
              = 'Отслеживать неавторизованных гостей';
         = 'Считает анонимных посетителей сайта через легковесные transients (без записи в историю).';
                 = 'Отображать счётчик в Admin Bar (верхняя панель)';
            = 'Выводит детальную статистику онлайн прямо в шапке панели WordPress.';
              = 'Показывать колонку «Онлайн» в списке пользователей';
            = 'Зелёный индикатор в users.php показывает, кто из сотрудников сейчас работает в админке.';
                = 'Фильтровать известных поисковых ботов';
           = 'Исключает сканеры Google, Yandex, Bing из числа онлайн-гостей.';
          = 'Текущий онлайн сайта в реальном времени:';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'WP Online Aktivní Uživatelé: Nastavení';
                = 'Sledování aktivních návštěvníků, správců a editorů na webu v reálném čase.';
               = 'Nastavení bylo úspěšně uloženo!';
             = 'Doba neaktivity (timeout online)';
           = 'Uživatel je považován za online, pokud byl aktivní v tomto časovém okně.';
              = 'Sledovat nepřihlášené návštěvníky';
         = 'Počítá hosty webu pomocí dočasných transients bez zatížení databáze.';
                 = 'Zobrazovat počítadlo v horní liště (Admin Bar)';
            = 'Zobrazuje souhrn online uživatelů přímo v záhlaví administrace.';
              = 'Zobrazit sloupec „Online“ v přehledu uživatelů';
            = 'Zelený indikátor v users.php ukazuje, kdo je právě přihlášen.';
                = 'Filtrovat roboty vyhledávačů';
           = 'Vyloučí roboty Google, Seznam apod. z počtu online hostů.';
          = 'Aktuální stav v reálném čase:';
            = 'Uložit nastavení';
    } else {
               = 'WP Online Active Users: Settings';
                = 'Real-time monitoring of online visitors, administrators, and shop managers.';
               = 'Settings successfully saved!';
             = 'Inactivity Window (Online Timeout)';
           = 'A user is considered online if active within this window.';
              = 'Track Guest Visitors';
         = 'Counts anonymous visitors using lightweight transients without table overhead.';
                 = 'Show Counter in Admin Bar';
            = 'Displays real-time breakdown directly in top WordPress toolbar.';
              = 'Show "Online" Status Column in Users List';
            = 'Provides green dot indicator on users.php before initiating updates.';
                = 'Filter Known Search Engine Crawlers';
           = 'Excludes Google, Yandex, Bing bots from guest count.';
          = 'Current Real-Time Activity:';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🟢 <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <!-- Live Status Card -->
        <div style="background:#f8fafc;border:1px solid #cbd5e1;border-radius:8px;padding:15px 20px;margin-bottom:20px;display:flex;flex-wrap:wrap;gap:25px;align-items:center;">
            <div><strong style="color:#0f172a;font-size:15px;"><?php echo esc_html(  ); ?></strong></div>
            <div style="font-size:14px;">👥 Всего: <strong style="color:#2563eb;font-size:16px;"><?php echo (int) ; ?></strong></div>
            <div style="font-size:14px;">🔴 Admins: <strong><?php echo (int) ; ?></strong></div>
            <div style="font-size:14px;">📋 Editors: <strong><?php echo (int) ; ?></strong></div>
            <div style="font-size:14px;">🛒 Shop Mgr: <strong><?php echo (int) ; ?></strong></div>
            <div style="font-size:14px;">🌐 Гости: <strong><?php echo (int) ; ?></strong></div>
        </div>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_online_counter_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_online_counter_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="timeout_minutes"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <select name="timeout_minutes" id="timeout_minutes">
                            <option value="3" <?php selected( ['timeout_minutes'], 3 ); ?>>3 минуты</option>
                            <option value="5" <?php selected( ['timeout_minutes'], 5 ); ?>>5 минут (рекомендуется)</option>
                            <option value="10" <?php selected( ['timeout_minutes'], 10 ); ?>>10 минут</option>
                            <option value="15" <?php selected( ['timeout_minutes'], 15 ); ?>>15 минут</option>
                            <option value="30" <?php selected( ['timeout_minutes'], 30 ); ?>>30 минут</option>
                        </select>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="track_guests" value="1" <?php checked( ['track_guests'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="show_admin_bar" value="1" <?php checked( ['show_admin_bar'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="show_user_column" value="1" <?php checked( ['show_user_column'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="bot_filter" value="1" <?php checked( ['bot_filter'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-online-counter" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_online_counter_settings', function() {
    check_admin_referer( 'vladimir_save_online_counter_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'timeout_minutes'  => max( 1, min( 120, (int) ( ['timeout_minutes'] ?? 5 ) ) ),
        'track_guests'     => isset( ['track_guests'] ) ? 1 : 0,
        'show_admin_bar'   => isset( ['show_admin_bar'] ) ? 1 : 0,
        'show_user_column' => isset( ['show_user_column'] ) ? 1 : 0,
        'bot_filter'       => isset( ['bot_filter'] ) ? 1 : 0,
    );

    update_option( '_vladimir_online_counter_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-online-counter-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. ACTIVITY TRACKING
// ─────────────────────────────────────────────

add_action( 'init', function() {
    if ( ! is_user_logged_in() ) {
        return;
    }
     = get_current_user_id();
         = time();
        = (int) get_user_meta( , WP_OC_META_KEY, true );

    if (  -  > 60 ) {
        update_user_meta( , WP_OC_META_KEY,  );
    }
} );

add_action( 'init', function() {
     = vladimir_online_counter_get_settings();
    if ( empty( ['track_guests'] ) || is_user_logged_in() || is_admin() ) {
        return;
    }

     = isset( ['REMOTE_ADDR'] ) ? sanitize_text_field( wp_unslash( ['REMOTE_ADDR'] ) ) : '';
     = isset( ['HTTP_USER_AGENT'] ) ? sanitize_text_field( wp_unslash( ['HTTP_USER_AGENT'] ) ) : '';

    if ( ! empty( ['bot_filter'] ) && preg_match( '/(bot|crawl|spider|slurp|facebookexternalhit|bingbot|googlebot|yandex)/i',  ) ) {
        return;
    }

        = md5(  . '|' .  );
     = vladimir_oc_timeout_seconds();
    set_transient( WP_OC_GUEST_PFX . , time(),  );
} );

// ─────────────────────────────────────────────
// 5. COUNTERS & QUERIES
// ─────────────────────────────────────────────

function wp_oc_get_online_users(  = null ) {
      =  ? (array)  : WP_OC_ROLES;
     = time() - vladimir_oc_timeout_seconds();

    return get_users( array(
        'role__in'     => ,
        'meta_key'     => WP_OC_META_KEY,
        'meta_value'   => ,
        'meta_compare' => '>=',
        'meta_type'    => 'NUMERIC',
        'fields'       => 'all',
    ) );
}

function wp_oc_count_role(  ) {
    return count( wp_oc_get_online_users(  ) );
}

function wp_oc_count_guests() {
    global ;
     = time() - vladimir_oc_timeout_seconds();
    return (int) ->get_var( ->prepare(
        "SELECT COUNT(*) FROM {->options}
         WHERE option_name LIKE %s
           AND CAST(option_value AS UNSIGNED) >= %d",
        '_transient_' . WP_OC_GUEST_PFX . '%',
        
    ) );
}

function wp_oc_count_total() {
     = count( wp_oc_get_online_users() );
        = wp_oc_count_guests();
    return  + ;
}

// ─────────────────────────────────────────────
// 6. ADMIN BAR DISPLAY
// ─────────────────────────────────────────────

add_action( 'admin_bar_menu', function( WP_Admin_Bar  ) {
     = vladimir_online_counter_get_settings();
    if ( empty( ['show_admin_bar'] ) ) {
        return;
    }

    if ( ! current_user_can( 'manage_options' ) && ! current_user_can( 'edit_posts' ) ) {
        return;
    }

     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

        = wp_oc_count_total();
       = wp_oc_count_role( 'administrator' );
      = wp_oc_count_role( 'editor' );
     = wp_oc_count_role( 'shop_manager' );

     = sprintf(
        '&#128101; %d &nbsp;|&nbsp; &#128308; Adm: %d &nbsp;|&nbsp; &#128203; Ed: %d &nbsp;|&nbsp; &#128722; Mgr: %d',
        ,
        ,
        ,
        
    );

    if ( 'ru' ===  ) {
         = 'Онлайн за последние ' . (int) ['timeout_minutes'] . ' мин. (Нажмите для перехода к списку)';
           = "👥 Всего онлайн: {}";
             = "🔴 Администраторы: {}";
              = "📋 Редакторы: {}";
             = "🛒 Менеджеры магазина: {}";
    } elseif ( 'cs' ===  ) {
         = 'Online za posledních ' . (int) ['timeout_minutes'] . ' min.';
           = "👥 Celkem online: {}";
             = "🔴 Administrátoři: {}";
              = "📋 Editoři: {}";
             = "🛒 Správci obchodu: {}";
    } else {
         = 'Online in the last ' . (int) ['timeout_minutes'] . ' min.';
           = "👥 Total Online: {}";
             = "🔴 Administrators: {}";
              = "📋 Editors: {}";
             = "🛒 Shop Managers: {}";
    }

     = admin_url( 'users.php' );

    ->add_node( array(
        'id'    => 'wp-online-counter',
        'title' => ,
        'href'  => ,
        'meta'  => array( 'title' =>  ),
    ) );

     = array(
        array( 'wp-oc-total', ,  ),
        array( 'wp-oc-adm',   ,   admin_url( 'users.php?role=administrator' ) ),
        array( 'wp-oc-ed',    ,    admin_url( 'users.php?role=editor' ) ),
        array( 'wp-oc-mgr',   ,   admin_url( 'users.php?role=shop_manager' ) ),
    );

    foreach (  as  ) {
        ->add_node( array(
            'id'     => [0],
            'parent' => 'wp-online-counter',
            'title'  => [1],
            'href'   => [2],
        ) );
    }
}, 100 );

add_action( 'admin_head', function() {
    if ( is_admin_bar_showing() ) {
        echo '<style>#wpadminbar #wp-admin-bar-wp-online-counter > .ab-item { font-weight: 600; letter-spacing: 0.02em; }</style>';
    }
} );

// ─────────────────────────────────────────────
// 7. USER LIST COLUMN
// ─────────────────────────────────────────────

add_filter( 'manage_users_columns', function( array  ) {
     = vladimir_online_counter_get_settings();
    if ( empty( ['show_user_column'] ) ) {
        return ;
    }

     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );
      = ( 'ru' ===  ) ? '🟢 Онлайн' : ( ( 'cs' ===  ) ? '🟢 Online' : '🟢 Online' );

    ['wp_oc_status'] = ;
    return ;
} );

add_filter( 'manage_users_custom_column', function( , ,  ) {
    if ( 'wp_oc_status' !==  ) {
        return ;
    }

       = (int) get_user_meta( , WP_OC_META_KEY, true );
     = time() - vladimir_oc_timeout_seconds();

    if (  >=  ) {
        return '<span style="color:#16a34a;font-weight:700;">● Online</span>';
    } elseif (  > 0 ) {
        return '<span style="color:#94a3b8;font-size:12px;">' . human_time_diff(  ) . ' назад</span>';
    }

    return '<span style="color:#cbd5e1;">—</span>';
}, 10, 3 );

// ─────────────────────────────────────────────
// 8. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'WP Онлайн Активные Пользователи (VladiMIR+AI)';
            [  ]['Description'] = 'Счётчик онлайн-посетителей, администраторов, редакторов и менеджеров в admin bar, со статусом в списке пользователей и панелью настроек на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'WP Online Aktivní Uživatelé (VladiMIR+AI)';
            [  ]['Description'] = 'Počítadlo návštěvníků a správců v horní liště administrace s přehlednou stránkou nastavení na jednom místě.';
        }
    }
    return ;
} );

