<?php
/**
 * Plugin Name: WP Test Email Micro (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-test-email-micro
 * Description: Sends one deliberate test email from Tools without database tables, mail interception, logging, or background work.
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

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function(  ) {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

     = ( 'ru' ===  ) ? 'Настройки' : ( ( 'cs' ===  ) ? 'Nastavení' : 'Settings' );
         = ( 'ru' ===  ) ? 'Документация ↗' : ( ( 'cs' ===  ) ? 'Dokumentace ↗' : 'Documentation ↗' );

     = '<a href="' . esc_url( admin_url( 'tools.php?page=wp-test-email-micro' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-test-email-micro" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 2. ADMIN MENU REGISTRATION (Tools & Settings)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_management_page(
        'Test Email',
        'Test Email',
        'manage_options',
        'wp-test-email-micro',
        'wtem_render_page'
    );
    add_options_page(
        'Test Email (VladiMIR+AI)',
        'Тест почты (Email)',
        'manage_options',
        'vladimir-test-email-settings',
        'wtem_render_page'
    );
} );

// ─────────────────────────────────────────────
// 3. SETTINGS & TESTING PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

function wtem_render_page() {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = ( 'ru' ===  ) ? 'Тестовое письмо WordPress' : ( ( 'cs' ===  ) ? 'Testovací e-mail z WordPressu' : 'WordPress test email' );
         = get_option( 'admin_email' );
           = isset( ['wtem_recipient'] ) ? sanitize_email( wp_unslash( ['wtem_recipient'] ) ) : ;
             = isset( ['wtem_subject'] ) ? sanitize_text_field( wp_unslash( ['wtem_subject'] ) ) : ;
           = isset( ['wtem_from_name'] ) ? sanitize_text_field( wp_unslash( ['wtem_from_name'] ) ) : get_bloginfo( 'name' );
              = '';
            = false;

    if ( isset( ['wtem_send'] ) ) {
        check_admin_referer( 'wtem_send_email', 'wtem_nonce' );

        if ( ! is_email(  ) ) {
               = ( 'ru' ===  ) ? 'Введите корректный email получателя.' : ( ( 'cs' ===  ) ? 'Zadejte platnou e-mailovou adresu příjemce.' : 'Enter a valid recipient email address.' );
             = true;
        } else {
             = wp_specialchars_decode( get_bloginfo( 'name' ), ENT_QUOTES );
            if ( 'ru' ===  ) {
                 = sprintf( "Это тестовое письмо, отправленное с сайта %s.\nПочтовый транспорт (SMTP / mail) работает корректно!\nВремя отправки: %s", , current_time( 'mysql' ) );
            } elseif ( 'cs' ===  ) {
                 = sprintf( "Toto je testovací e-mail odeslaný z webu %s.\nPoštovní systém (SMTP / mail) funguje správně!\nČas odeslání: %s", , current_time( 'mysql' ) );
            } else {
                 = sprintf( "This is a test email sent from %s.\nMail transport is working properly!\nTimestamp: %s", , current_time( 'mysql' ) );
            }

             = array( 'Content-Type: text/plain; charset=UTF-8' );
            if ( ! empty(  ) ) {
                [] = 'From: ' .  . ' <' .  . '>';
            }

            if ( wp_mail( , , ,  ) ) {
                if ( 'ru' ===  ) {
                     = sprintf( '✅ Тестовое письмо успешно передано почтовому транспорту для отправки на %s!',  );
                } elseif ( 'cs' ===  ) {
                     = sprintf( '✅ Testovací e-mail byl úspěšně předán k odeslání na %s!',  );
                } else {
                     = sprintf( '✅ Test email accepted for delivery to %s!',  );
                }
            } else {
                   = ( 'ru' ===  ) ? '❌ Ошибка: WordPress не смог передать письмо настроенному почтовому серверу.' : ( ( 'cs' ===  ) ? '❌ Chyba: WordPress nemohl předat e-mail nakonfigurovanému poštovnímu serveru.' : '❌ Error: WordPress could not hand the test email to the configured mail transport.' );
                 = true;
            }
        }
    }

    if ( 'ru' ===  ) {
               = 'Тест отправки почты (Test Email): Настройки и Диагностика';
                = 'Мгновенная проверка работы почтового транспорта сайта без записи в базу данных и без перехвата писем.';
            = 'Получатель (Email)';
            = 'Тема тестового письма';
            = 'Имя отправителя (From Name)';
            = 'Отправить тестовое письмо';
          = 'Диагностика почтовой среды WordPress:';
    } elseif ( 'cs' ===  ) {
               = 'Test odesílání e-mailu (Test Email): Nastavení';
                = 'Okamžitý test funkčnosti poštovního subsystému bez zatížení databáze a logů.';
            = 'Příjemce (E-mail)';
            = 'Předmět';
            = 'Jméno odesílatele';
            = 'Odeslat testovací e-mail';
          = 'Diagnostika poštovního systému:';
    } else {
               = 'Test Email: Settings & Live Delivery Diagnostic';
                = 'Instant diagnostic verification of WordPress mail transport without database overhead.';
            = 'Recipient Email';
            = 'Subject';
            = 'Sender Name (From Name)';
            = 'Send Test Email';
          = 'WordPress Mail Transport Diagnostic:';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>✉️ <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if ( '' !==  ) : ?>
            <div class="notice <?php echo  ? 'notice-error' : 'notice-success'; ?> is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <!-- Diagnostic box -->
        <div style="background:#f8fafc;border:1px solid #cbd5e1;border-radius:8px;padding:15px 20px;margin-bottom:20px;">
            <strong style="color:#0f172a;"><?php echo esc_html(  ); ?></strong>
            <ul style="margin:8px 0 0 18px;color:#475569;font-size:13px;line-height:1.6;">
                <li>Адрес администратора по умолчанию: <code><?php echo esc_html(  ); ?></code></li>
                <li>Текущее время сервера: <code><?php echo esc_html( current_time( 'mysql' ) ); ?></code></li>
                <li>Обработчик почты: <code>wp_mail() via PHPMailer</code></li>
            </ul>
        </div>

        <form method="post" action="" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'wtem_send_email', 'wtem_nonce' ); ?>

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="wtem_recipient"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="email" name="wtem_recipient" id="wtem_recipient" value="<?php echo esc_attr(  ); ?>" class="regular-text" required>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="wtem_subject"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="text" name="wtem_subject" id="wtem_subject" value="<?php echo esc_attr(  ); ?>" class="regular-text" required>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="wtem_from_name"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="text" name="wtem_from_name" id="wtem_from_name" value="<?php echo esc_attr(  ); ?>" class="regular-text">
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'wtem_send', false ); ?>
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
// 4. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'WP Тест отправки почты (VladiMIR+AI)';
            [  ]['Description'] = 'Моментальная тестовая отправка одного письма для проверки SMTP и почтового транспорта без записи в БД и логов. Включает панель настроек на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'WP Test odesílání e-mailu (VladiMIR+AI)';
            [  ]['Description'] = 'Rychlý test funkčnosti poštovního serveru (SMTP) bez ukládání do DB a zatížení logů s přehlednou stránkou nastavení.';
        }
    }
    return ;
} );

