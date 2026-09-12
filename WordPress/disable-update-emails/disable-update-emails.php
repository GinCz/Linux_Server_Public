<?php
/**
 * Plugin Name: Disable Auto-Update Notification E-mails (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/disable-update-emails
 * Description: Disables annoying automatic core, plugin, and theme update notification emails sent to site administrators and users. Zero database queries and zero configuration required.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: disable-update-emails
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_disable_emails_get_settings() {
     = array(
        'disable_core_emails'        => 1,
        'disable_core_notifications' => 1,
        'disable_plugin_emails'      => 1,
        'disable_theme_emails'       => 1,
    );
     = get_option( '_vladimir_disable_emails_settings', array() );
    return wp_parse_args( is_array(  ) ?  : array(),  );
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function(  ) {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

     = ( 'ru' ===  ) ? 'Настройки' : ( ( 'cs' ===  ) ? 'Nastavení' : 'Settings' );
         = ( 'ru' ===  ) ? 'Документация ↗' : ( ( 'cs' ===  ) ? 'Dokumentace ↗' : 'Documentation ↗' );

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-disable-emails-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/disable-update-emails" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Disable Update Emails (VladiMIR+AI)',
        'Отключение писем обновлений',
        'manage_options',
        'vladimir-disable-emails-settings',
        'vladimir_disable_emails_render_settings_page'
    );
} );

function vladimir_disable_emails_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_disable_emails_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'Отключение писем об обновлениях: Настройки';
                = 'Блокировка спам-уведомлений на почту об автоматических обновлениях WordPress, тем и плагинов.';
               = 'Настройки успешно сохранены!';
                = 'Письма об автообновлениях ядра WordPress';
           = 'Отключает отправку писем при фоновом обновлении версии ядра.';
               = 'Уведомления о доступных обновлениях ядра';
          = 'Отключает письма администраторам о появлении новых версий WP.';
             = 'Письма об автообновлениях плагинов';
           = 'Блокирует письма при автоматическом обновлении установленных плагинов.';
              = 'Письма об автообновлениях тем оформления';
            = 'Блокирует письма при фоновом обновлении тем сайта.';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'Vypnutí e-mailů o auto-aktualizacích: Nastavení';
                = 'Vypnutí e-mailových oznámení o aktualizacích jádra, pluginů a šablon WordPressu.';
               = 'Nastavení bylo úspěšně uloženo!';
                = 'E-maily o automatických aktualizacích jádra';
           = 'Zabrání odesílání e-mailů po aktualizaci jádra.';
               = 'Oznámení o dostupnosti nové verze jádra';
          = 'Vypne e-maily správcům o nových verzích WP.';
             = 'E-maily o auto-aktualizacích pluginů';
           = 'Blokuje e-maily po aktualizaci doplňků.';
              = 'E-maily o auto-aktualizacích šablon';
            = 'Blokuje e-maily po aktualizaci šablon vzhledu.';
            = 'Uložit nastavení';
    } else {
               = 'Disable Auto-Update Notification E-mails: Settings';
                = 'Block automatic update email notifications for WordPress core, plugins, and themes.';
               = 'Settings successfully saved!';
                = 'Automatic Core Update Emails';
           = 'Suppresses email notifications when WordPress core auto-updates in background.';
               = 'Core Update Available Notifications';
          = 'Disables emails notifying site admin of new core releases.';
             = 'Automatic Plugin Update Emails';
           = 'Suppresses email alerts when plugins are updated automatically.';
              = 'Automatic Theme Update Emails';
            = 'Suppresses email alerts when themes are updated automatically.';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🔕 <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_disable_emails_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_disable_emails_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_core_emails" value="1" <?php checked( ['disable_core_emails'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_core_notifications" value="1" <?php checked( ['disable_core_notifications'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_plugin_emails" value="1" <?php checked( ['disable_plugin_emails'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_theme_emails" value="1" <?php checked( ['disable_theme_emails'], 1 ); ?>>
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
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/disable-update-emails" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_disable_emails_settings', function() {
    check_admin_referer( 'vladimir_save_disable_emails_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'disable_core_emails'        => isset( ['disable_core_emails'] ) ? 1 : 0,
        'disable_core_notifications' => isset( ['disable_core_notifications'] ) ? 1 : 0,
        'disable_plugin_emails'      => isset( ['disable_plugin_emails'] ) ? 1 : 0,
        'disable_theme_emails'       => isset( ['disable_theme_emails'] ) ? 1 : 0,
    );

    update_option( '_vladimir_disable_emails_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-disable-emails-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. SUPPRESSION HOOKS
// ─────────────────────────────────────────────

 = vladimir_disable_emails_get_settings();

if ( ! empty( ['disable_core_emails'] ) ) {
    add_filter( 'auto_core_update_send_email', '__return_false' );
}

if ( ! empty( ['disable_core_notifications'] ) ) {
    add_filter( 'send_core_update_notification_email', '__return_false' );
}

if ( ! empty( ['disable_plugin_emails'] ) ) {
    add_filter( 'auto_plugin_update_send_email', '__return_false' );
}

if ( ! empty( ['disable_theme_emails'] ) ) {
    add_filter( 'auto_theme_update_send_email', '__return_false' );
}

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'Отключение писем об автообновлениях (VladiMIR+AI)';
            [  ]['Description'] = 'Отключает назойливые уведомления на почту об автоматических обновлениях ядра WordPress, плагинов и тем. Включает удобную страницу настроек на одном экране.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'Vypnutí e-mailů o auto-aktualizacích (VladiMIR+AI)';
            [  ]['Description'] = 'Vypíná e-mailová oznámení o automatických aktualizacích jádra, pluginů a šablon WordPressu s přehledným nastavením na jedné stránce.';
        }
    }
    return ;
} );

