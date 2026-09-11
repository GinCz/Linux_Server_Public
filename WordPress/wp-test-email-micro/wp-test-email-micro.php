<?php
/**
 * Plugin Name: WP Test Email Micro (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-test-email-micro
 * Description: Sends one deliberate test email from Tools without database tables, mail interception, logging, or background work.
 * Version:     2026.09.10
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function wtem_add_tools_page() {
    add_management_page(
        'Test Email',
        'Test Email',
        'manage_options',
        'wp-test-email-micro',
        'wtem_render_tools_page'
    );
}
add_action( 'admin_menu', 'wtem_add_tools_page' );

function wtem_render_tools_page() {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    if ( ! current_user_can( 'manage_options' ) ) {
        $err = ( 'ru' === $lang ) ? 'У вас нет прав для отправки тестовых писем.' : ( ( 'cs' === $lang ) ? 'Nemáte oprávnění k odesílání testovacích e-mailů.' : 'You are not allowed to send a test email.' );
        wp_die( esc_html( $err ) );
    }

    $default_subject = ( 'ru' === $lang ) ? 'Тестовое письмо WordPress' : ( ( 'cs' === $lang ) ? 'Testovací e-mail z WordPressu' : 'WordPress test email' );
    $recipient = isset( $_POST['wtem_recipient'] ) ? sanitize_email( wp_unslash( $_POST['wtem_recipient'] ) ) : '';
    $subject   = isset( $_POST['wtem_subject'] ) ? sanitize_text_field( wp_unslash( $_POST['wtem_subject'] ) ) : $default_subject;
    $notice    = '';
    $is_error  = false;

    if ( isset( $_POST['wtem_send'] ) ) {
        check_admin_referer( 'wtem_send_email', 'wtem_nonce' );

        if ( ! is_email( $recipient ) ) {
            $notice   = ( 'ru' === $lang ) ? 'Введите корректный email получателя.' : ( ( 'cs' === $lang ) ? 'Zadejte platnou e-mailovou adresu příjemce.' : 'Enter a valid recipient email address.' );
            $is_error = true;
        } else {
            $site_name = wp_specialchars_decode( get_bloginfo( 'name' ), ENT_QUOTES );
            if ( 'ru' === $lang ) {
                $body = sprintf( "Это тестовое письмо, отправленное с сайта %s.\nПочтовый транспорт (SMTP / mail) работает корректно!", $site_name );
            } elseif ( 'cs' === $lang ) {
                $body = sprintf( "Toto je testovací e-mail odeslaný z webu %s.\nPoštovní systém (SMTP / mail) funguje správně!", $site_name );
            } else {
                $body = sprintf( "This is a test email sent from %s.\nMail transport is working properly!", $site_name );
            }

            if ( wp_mail( $recipient, $subject, $body, array( 'Content-Type: text/plain; charset=UTF-8' ) ) ) {
                if ( 'ru' === $lang ) {
                    $notice = sprintf( 'Тестовое письмо успешно отправлено на адрес %s.', $recipient );
                } elseif ( 'cs' === $lang ) {
                    $notice = sprintf( 'Testovací e-mail byl úspěšně odeslán na adresu %s.', $recipient );
                } else {
                    $notice = sprintf( 'Test email accepted for delivery to %s.', $recipient );
                }
            } else {
                $notice   = ( 'ru' === $lang ) ? 'WordPress не смог передать письмо настроенному почтовому транспорту.' : ( ( 'cs' === $lang ) ? 'WordPress nemohl předat e-mail nakonfigurovanému poštovnímu serveru.' : 'WordPress could not hand the test email to the configured mail transport.' );
                $is_error = true;
            }
        }
    }

    if ( 'ru' === $lang ) {
        $t_title       = 'Тест отправки почты (Test Email)';
        $t_desc        = 'Утилита отправляет одиночное тестовое письмо. Без записи в БД, без перехвата почты и без сторонних логов.';
        $t_lbl_rcpt    = 'Получатель (Email)';
        $t_lbl_subj    = 'Тема письма';
        $t_btn_send    = 'Отправить тестовое письмо';
    } elseif ( 'cs' === $lang ) {
        $t_title       = 'Test odesílání e-mailu (Test Email)';
        $t_desc        = 'Tento nástroj odešle jeden testovací e-mail. Nevytváří tabulky v DB, nezaznamenává historii pošty a nezatěžuje server.';
        $t_lbl_rcpt    = 'Příjemce (E-mail)';
        $t_lbl_subj    = 'Předmět';
        $t_btn_send    = 'Odeslat testovací e-mail';
    } else {
        $t_title       = 'Test Email';
        $t_desc        = 'This tool sends one deliberate test message. It does not create database tables or record outgoing mail.';
        $t_lbl_rcpt    = 'Recipient';
        $t_lbl_subj    = 'Subject';
        $t_btn_send    = 'Send Test Email';
    }
    ?>
    <div class="wrap">
        <h1><?php echo esc_html( $t_title ); ?></h1>
        <p><?php echo esc_html( $t_desc ); ?></p>
        <?php if ( '' !== $notice ) : ?>
            <div class="notice <?php echo $is_error ? 'notice-error' : 'notice-success'; ?>"><p><?php echo esc_html( $notice ); ?></p></div>
        <?php endif; ?>
        <form method="post">
            <?php wp_nonce_field( 'wtem_send_email', 'wtem_nonce' ); ?>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="wtem_recipient"><?php echo esc_html( $t_lbl_rcpt ); ?></label></th>
                    <td><input name="wtem_recipient" id="wtem_recipient" type="email" class="regular-text" value="<?php echo esc_attr( $recipient ); ?>" required></td>
                </tr>
                <tr>
                    <th scope="row"><label for="wtem_subject"><?php echo esc_html( $t_lbl_subj ); ?></label></th>
                    <td><input name="wtem_subject" id="wtem_subject" type="text" class="regular-text" value="<?php echo esc_attr( $subject ); ?>" required></td>
                </tr>
            </table>
            <?php submit_button( $t_btn_send, 'primary', 'wtem_send' ); ?>
        </form>
    </div>
    <?php
}

// Multilingual plugin metadata (EN / CS / RU)
add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP Тест Почты Micro (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Сверхлегкий инструмент в разделе «Инструменты» для разовой проверки отправки email с сайта. Без создания таблиц в базе данных, перехвата писем и фоновых задач.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP Test E-mailu Micro (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Ultralehký nástroj v sekci Nástroje pro rychlé ověření odesílání e-mailů z WordPressu. Bez vytváření tabulek v DB, sledování pošty a zbytečných procesů na pozadí.';
        }
    }
    return $plugins;
} );

