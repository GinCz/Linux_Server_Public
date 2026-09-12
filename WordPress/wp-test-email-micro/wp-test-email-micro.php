<?php
/**
 * Plugin Name: WP Test Email Micro (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-test-email-micro
 * Description: Instant diagnostic email test tool for WordPress. Send test emails via wp_mail() on demand to verify SMTP/PHP mail delivery. Zero persistent background processes, zero database pollution.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: wp-test-email-micro
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function( $links ) {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $settings_label = ( 'ru' === $lang ) ? 'Настройки' : ( ( 'cs' === $lang ) ? 'Nastavení' : 'Settings' );
    $docs_label     = ( 'ru' === $lang ) ? 'Документация ↗' : ( ( 'cs' === $lang ) ? 'Dokumentace ↗' : 'Documentation ↗' );

    $settings_link = '<a href="' . esc_url( admin_url( 'tools.php?page=vladimir-test-email' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-test-email-micro" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 2. ADMIN MENU & DASHBOARD
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_management_page(
        'WP Test Email (VladiMIR+AI)',
        'Test Email',
        'manage_options',
        'vladimir-test-email',
        'vladimir_test_email_render_page'
    );
} );

function vladimir_test_email_render_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $default_to = get_option( 'admin_email' );
    $to         = isset( $_POST['vladimir_email_to'] ) ? sanitize_email( $_POST['vladimir_email_to'] ) : $default_to;
    $subject    = isset( $_POST['vladimir_email_subject'] ) ? sanitize_text_field( $_POST['vladimir_email_subject'] ) : '';
    $message    = isset( $_POST['vladimir_email_message'] ) ? sanitize_textarea_field( $_POST['vladimir_email_message'] ) : '';
    $from_name  = isset( $_POST['vladimir_from_name'] ) ? sanitize_text_field( $_POST['vladimir_from_name'] ) : get_bloginfo( 'name' );
    $from_email = isset( $_POST['vladimir_from_email'] ) ? sanitize_email( $_POST['vladimir_from_email'] ) : $default_to;

    $result_msg = '';
    $result_ok  = false;

    if ( isset( $_POST['vladimir_send_test'] ) && check_admin_referer( 'vladimir_test_email_action', 'vladimir_nonce' ) ) {
        if ( ! is_email( $to ) ) {
            $result_msg = ( 'ru' === $lang ) ? 'Ошибка: Указан некорректный email получателя!' : 'Error: Invalid recipient email address!';
        } else {
            $sent_subject = $subject ?: ( '[' . get_bloginfo( 'name' ) . '] Тестовое письмо / Diagnostic Test Email' );
            $sent_body    = $message ?: "Привет!\n\nЭто тестовое письмо от плагина WP Test Email Micro (VladiMIR+AI).\nСайт: " . home_url() . "\nВремя отправки: " . current_time( 'mysql' ) . "\n\nПочтовый транспорт WordPress wp_mail() работает корректно!";

            $headers = array(
                'Content-Type: text/plain; charset=UTF-8',
                'From: ' . $from_name . ' <' . $from_email . '>',
            );

            // Capture PHPMailer error if any
            $mail_error = '';
            add_action( 'wp_mail_failed', function( $wp_error ) use ( &$mail_error ) {
                if ( is_wp_error( $wp_error ) ) {
                    $mail_error = $wp_error->get_error_message();
                }
            } );

            $sent = wp_mail( $to, $sent_subject, $sent_body, $headers );

            if ( $sent ) {
                $result_ok  = true;
                $result_msg = ( 'ru' === $lang ) ? "✅ Письмо успешно отправлено на {$to}!" : "✅ Test email successfully dispatched to {$to}!";
            } else {
                $result_msg = ( 'ru' === $lang ) ? "❌ Ошибка отправки письма на {$to}. " . ( $mail_error ? "Детали: {$mail_error}" : 'Проверьте настройки SMTP сервера на хостинге.' ) : "❌ Failed to send email to {$to}. " . ( $mail_error ?: 'Check your SMTP settings.' );
            }
        }
    }

    if ( 'ru' === $lang ) {
        $txt_title    = 'WP Test Email: Диагностика отправки почты';
        $txt_subtitle = 'Мгновенная проверка функции wp_mail() и доставки писем через SMTP / PHP-mail.';
        $txt_to       = 'Получатель (Email)';
        $txt_sub      = 'Тема письма (необязательно)';
        $txt_name     = 'Имя отправителя (From Name)';
        $txt_from     = 'Email отправителя (From Email)';
        $txt_body     = 'Текст письма';
        $txt_btn      = 'Отправить тестовое письмо';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'WP Test Email: Test odesílání e-mailů';
        $txt_subtitle = 'Okamžité otestování funkce wp_mail() a doručování zpráv.';
        $txt_to       = 'Příjemce (Email)';
        $txt_sub      = 'Předmět zprávy';
        $txt_name     = 'Jméno odesílatele';
        $txt_from     = 'E-mail odesílatele';
        $txt_body     = 'Text zprávy';
        $txt_btn      = 'Odeslat testovací e-mail';
    } else {
        $txt_title    = 'WP Test Email: Diagnostic Mail Dispatch';
        $txt_subtitle = 'On-demand verification of wp_mail() delivery through local PHP mail or SMTP.';
        $txt_to       = 'Recipient Email';
        $txt_sub      = 'Subject Line';
        $txt_name     = 'From Name';
        $txt_from     = 'From Email';
        $txt_body     = 'Message Body';
        $txt_btn      = 'Send Test Email';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>✉️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( ! empty( $result_msg ) ) : ?>
            <div class="notice <?php echo $result_ok ? 'notice-success' : 'notice-error'; ?> is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $result_msg ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_test_email_action', 'vladimir_nonce' ); ?>

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="vladimir_email_to"><strong><?php echo esc_html( $txt_to ); ?> *</strong></label></th>
                    <td>
                        <input type="email" name="vladimir_email_to" id="vladimir_email_to" value="<?php echo esc_attr( $to ); ?>" class="regular-text" required style="width:100%;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_from_name"><strong><?php echo esc_html( $txt_name ); ?></strong></label></th>
                    <td>
                        <input type="text" name="vladimir_from_name" id="vladimir_from_name" value="<?php echo esc_attr( $from_name ); ?>" class="regular-text" style="width:100%;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_from_email"><strong><?php echo esc_html( $txt_from ); ?></strong></label></th>
                    <td>
                        <input type="email" name="vladimir_from_email" id="vladimir_from_email" value="<?php echo esc_attr( $from_email ); ?>" class="regular-text" style="width:100%;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_email_subject"><strong><?php echo esc_html( $txt_sub ); ?></strong></label></th>
                    <td>
                        <input type="text" name="vladimir_email_subject" id="vladimir_email_subject" value="<?php echo esc_attr( $subject ); ?>" class="regular-text" placeholder="Диагностическое письмо VladiMIR+AI" style="width:100%;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_email_message"><strong><?php echo esc_html( $txt_body ); ?></strong></label></th>
                    <td>
                        <textarea name="vladimir_email_message" id="vladimir_email_message" rows="4" class="large-text" placeholder="Оставьте пустым для автогенерации диагностического текста..."><?php echo esc_textarea( $message ); ?></textarea>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <input type="submit" name="vladimir_send_test" class="button button-primary" value="<?php echo esc_attr( $txt_btn ); ?>">
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-test-email-micro" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

// ─────────────────────────────────────────────
// 3. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP Test Email Micro (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Мгновенная диагностическая отправка тестовых писем через wp_mail() для проверки SMTP и доставки писем.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP Test Email Micro (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Diagnostický nástroj pro rychlé testování odesílání e-mailů přes wp_mail().';
        }
    }
    return $plugins;
} );
