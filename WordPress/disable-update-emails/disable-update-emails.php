<?php
/**
 * Plugin Name: Disable Update Notification Emails (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/disable-update-emails
 * Description: Stops unwanted core, plugin, and theme automatic update notification emails sent to the site administrator. Zero overhead.
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

function vladimir_due_get_settings() {
    $defaults = array(
        'disable_core_auto'   => 1,
        'disable_core_notify' => 1,
        'disable_plugin_auto' => 1,
        'disable_theme_auto'  => 1,
    );
    $saved = get_option( '_vladimir_due_settings', array() );
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-due-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/disable-update-emails" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Disable Update Notification Emails (VladiMIR+AI)',
        'Disable Update Emails',
        'manage_options',
        'vladimir-due-settings',
        'vladimir_due_render_settings_page'
    );
} );

function vladimir_due_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_due_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Disable Update Emails: Отключение писем об обновлениях';
        $txt_subtitle = 'Предотвращает отправку сервисных писем WordPress администратору при автообновлениях движка, плагинов и тем.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_c_auto   = 'Отключить письма об автообновлении ядра WordPress (auto_core_update)';
        $txt_c_not    = 'Отключить письма с предложениями обновить ядро WordPress';
        $txt_p_auto   = 'Отключить письма об автообновлении плагинов (auto_plugin_update)';
        $txt_t_auto   = 'Отключить письма об автообновлении тем оформления (auto_theme_update)';
        $txt_save     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Disable Update Emails: Vypnutí e-mailů o aktualizacích';
        $txt_subtitle = 'Zastaví odesílání e-mailových upozornění o automatických aktualizacích jádra, pluginů a šablon.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_c_auto   = 'Vypnout e-maily o automatické aktualizaci jádra WP';
        $txt_c_not    = 'Vypnout oznámení o dostupnosti nové verze WP';
        $txt_p_auto   = 'Vypnout e-maily o aktualizaci pluginů';
        $txt_t_auto   = 'Vypnout e-maily o aktualizaci šablon';
        $txt_save     = 'Uložit nastavení';
    } else {
        $txt_title    = 'Disable Update Emails: Notification Suppression Settings';
        $txt_subtitle = 'Prevents WordPress from sending automated update notification emails to the administrator.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_c_auto   = 'Disable Core Auto-Update Emails';
        $txt_c_not    = 'Disable Core Update Available Notifications';
        $txt_p_auto   = 'Disable Plugin Auto-Update Emails';
        $txt_t_auto   = 'Disable Theme Auto-Update Emails';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🔇 <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_due_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_due_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Уведомления</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="disable_core_auto" value="1" <?php checked( $settings['disable_core_auto'], 1 ); ?>>
                                <?php echo esc_html( $txt_c_auto ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="disable_core_notify" value="1" <?php checked( $settings['disable_core_notify'], 1 ); ?>>
                                <?php echo esc_html( $txt_c_not ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="disable_plugin_auto" value="1" <?php checked( $settings['disable_plugin_auto'], 1 ); ?>>
                                <?php echo esc_html( $txt_p_auto ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="disable_theme_auto" value="1" <?php checked( $settings['disable_theme_auto'], 1 ); ?>>
                                <?php echo esc_html( $txt_t_auto ); ?>
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
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/disable-update-emails" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_due_settings', function() {
    check_admin_referer( 'vladimir_save_due_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'disable_core_auto'   => isset( $_POST['disable_core_auto'] ) ? 1 : 0,
        'disable_core_notify' => isset( $_POST['disable_core_notify'] ) ? 1 : 0,
        'disable_plugin_auto' => isset( $_POST['disable_plugin_auto'] ) ? 1 : 0,
        'disable_theme_auto'  => isset( $_POST['disable_theme_auto'] ) ? 1 : 0,
    );

    update_option( '_vladimir_due_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-due-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. SUPPRESSION HOOKS
// ─────────────────────────────────────────────

$due_cfg = vladimir_due_get_settings();

if ( ! empty( $due_cfg['disable_core_auto'] ) ) {
    add_filter( 'auto_core_update_send_email', '__return_false' );
}

if ( ! empty( $due_cfg['disable_core_notify'] ) ) {
    add_filter( 'send_core_update_notification_email', '__return_false' );
}

if ( ! empty( $due_cfg['disable_plugin_auto'] ) ) {
    add_filter( 'auto_plugin_update_send_email', '__return_false' );
}

if ( ! empty( $due_cfg['disable_theme_auto'] ) ) {
    add_filter( 'auto_theme_update_send_email', '__return_false' );
}

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Disable Update Notification Emails (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Блокирует отправку назойливых сервисных писем об автообновлении движка, плагинов и тем на почту администратора.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Disable Update Notification Emails (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Zastaví e-maily o automatických aktualizacích jádra, pluginů a šablon administrátorovi.';
        }
    }
    return $plugins;
} );
