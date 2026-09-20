<?php
/**
 * Plugin Name: WP Test Email Micro (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-test-email-micro
 * Description: Sends an on-demand HTML email from WordPress so an administrator can verify the configured mail transport.
 * Version:     2026-09__1.33
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-test-email-micro
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-test-email-micro
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

if ( is_admin() ) {
    if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
        require_once __DIR__ . '/vladimir-ai-i18n.php';
    }

    add_action( 'admin_menu', 'vladimir_test_email_add_menu' );
    add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), 'vladimir_test_email_action_links' );
}

function vladimir_test_email_add_menu() {
    add_management_page( 'WP Test Email', 'Test Email', 'manage_options', 'vladimir-test-email', 'vladimir_test_email_render_page' );
}

function vladimir_test_email_action_links( $links ) {
    $test_link = '<a href="' . esc_url( admin_url( 'tools.php?page=vladimir-test-email' ) ) . '">Test Email</a>';
    array_unshift( $links, $test_link );
    return $links;
}

function vladimir_test_email_get_logo_url() {
    $custom_logo_id = get_theme_mod( 'custom_logo' );
    if ( $custom_logo_id ) {
        $logo_data = wp_get_attachment_image_src( $custom_logo_id, 'full' );
        if ( ! empty( $logo_data[0] ) ) {
            return esc_url( $logo_data[0] );
        }
    }

    $site_icon = get_site_icon_url( 512 );
    return ! empty( $site_icon ) ? esc_url( $site_icon ) : '';
}

function vladimir_test_email_generate_content( $message_text = '' ) {
    $site_name = get_bloginfo( 'name' );
    $site_url  = home_url( '/' );
    $logo_url  = vladimir_test_email_get_logo_url();
    $logo_html = '';

    if ( '' === trim( $message_text ) ) {
        $message_text = "Hello,\n\nThis is a test email sent from the website. It confirms how a normal message with text, a logo, and a website link is displayed in your inbox.";
    }

    if ( ! empty( $logo_url ) ) {
        $logo_html = '<tr><td style="padding:0 0 24px;text-align:center;">'
            . '<img src="' . esc_url( $logo_url ) . '" alt="' . esc_attr( $site_name ) . '" width="240" style="display:inline-block;max-width:240px;max-height:90px;width:auto;height:auto;border:0;outline:none;text-decoration:none;" />'
            . '</td></tr>';
    }

    $subject     = 'Website Email Delivery Test';
    $message_html = nl2br( esc_html( $message_text ) );
    $body    = '<!doctype html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Email check</title></head>'
        . '<body style="margin:0;padding:24px;background:#f1f5f9;font-family:Arial,Helvetica,sans-serif;color:#334155;">'
        . '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"><tr><td align="center">'
        . '<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="width:100%;max-width:600px;background:#ffffff;border:1px solid #dbe3ec;border-radius:8px;">'
        . '<tr><td style="padding:32px;"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">'
        . $logo_html
        . '<tr><td style="padding:0;"><h1 style="margin:0 0 18px;font-size:22px;line-height:1.3;color:#0f172a;">Website Email Delivery Test</h1>'
        . '<p style="margin:0 0 24px;font-size:16px;line-height:1.7;color:#334155;">' . $message_html . '</p>'
        . '<table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:0 auto 20px;"><tr><td style="border-radius:6px;background:#2271b1;text-align:center;">'
        . '<a href="' . esc_url( $site_url ) . '" target="_blank" rel="noopener noreferrer" style="display:inline-block;padding:14px 28px;color:#ffffff;font-size:16px;font-weight:700;text-decoration:none;border-radius:6px;">Open Website</a>'
        . '</td></tr></table>'
        . '<p style="margin:0;text-align:center;font-size:13px;line-height:1.6;color:#64748b;"><a href="' . esc_url( $site_url ) . '" target="_blank" rel="noopener noreferrer" style="color:#2563eb;">' . esc_html( $site_url ) . '</a></p>'
        . '</td></tr></table></td></tr></table></td></tr></table></body></html>';

    return array(
        'subject'      => $subject,
        'body'         => $body,
        'message_text' => $message_text,
    );
}

function vladimir_test_email_render_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }

    $generated          = vladimir_test_email_generate_content();
    $default_from_name  = get_bloginfo( 'name' );
    $default_from_email = get_option( 'admin_email' );
    $to                 = isset( $_POST['vladimir_email_to'] ) ? sanitize_email( wp_unslash( $_POST['vladimir_email_to'] ) ) : '';
    $from_name          = isset( $_POST['vladimir_from_name'] ) ? sanitize_text_field( wp_unslash( $_POST['vladimir_from_name'] ) ) : $default_from_name;
    $from_email         = isset( $_POST['vladimir_from_email'] ) ? sanitize_email( wp_unslash( $_POST['vladimir_from_email'] ) ) : $default_from_email;
    $subject            = isset( $_POST['vladimir_email_subject'] ) ? sanitize_text_field( wp_unslash( $_POST['vladimir_email_subject'] ) ) : $generated['subject'];
    $message_text       = isset( $_POST['vladimir_email_message'] ) ? sanitize_textarea_field( wp_unslash( $_POST['vladimir_email_message'] ) ) : $generated['message_text'];
    $result_msg         = '';
    $result_ok          = false;

    if ( isset( $_POST['vladimir_send_test'] ) && check_admin_referer( 'vladimir_test_email_action', 'vladimir_nonce' ) ) {
        if ( empty( $to ) || ! is_email( $to ) ) {
            $result_msg = 'Enter a valid recipient email address.';
        } elseif ( empty( $from_email ) || ! is_email( $from_email ) ) {
            $result_msg = 'Enter a valid sender email address.';
        } else {
            $headers = array(
                'Content-Type: text/html; charset=UTF-8',
                'From: ' . $from_name . ' <' . $from_email . '>',
            );
            $mail_error = '';

            add_action( 'wp_mail_failed', function( $wp_error ) use ( &$mail_error ) {
                if ( is_wp_error( $wp_error ) ) {
                    $mail_error = $wp_error->get_error_message();
                }
            } );

            $sent_content = vladimir_test_email_generate_content( $message_text );
            $sent         = wp_mail( $to, $subject, $sent_content['body'], $headers );

            if ( $sent ) {
                $result_ok  = true;
                $result_msg = 'The test email was handed to the configured WordPress mail transport.';
            } else {
                $result_msg = 'WordPress could not hand the message to its mail transport.' . ( $mail_error ? ' Details: ' . $mail_error : '' );
            }
        }
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1>WP Test Email</h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:18px;">Send a clean HTML email with your website link and current logo.</p>

        <div style="background:#f0f6fc;border-left:4px solid #2271b1;padding:18px 20px;border-radius:6px;margin-bottom:24px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <h2 style="margin:0 0 8px;font-size:17px;">Check email deliverability</h2>
            <p style="margin:0 0 14px;color:#475569;">Open Mail Tester in a new tab, copy the temporary email address, paste it into Recipient Email, and send the message.</p>
            <a href="https://mail-tester.com/" target="_blank" rel="noopener noreferrer" class="button button-primary button-hero" style="display:inline-flex;align-items:center;justify-content:center;min-width:230px;">Open Mail Tester &nearr;</a>
        </div>

        <?php if ( ! empty( $result_msg ) ) : ?>
            <div class="notice <?php echo $result_ok ? 'notice-success' : 'notice-error'; ?> is-dismissible" style="margin-left:0;margin-bottom:20px;">
                <p><strong><?php echo esc_html( $result_msg ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="" style="background:#fff;padding:26px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_test_email_action', 'vladimir_nonce' ); ?>
            <table class="form-table" role="presentation">
                <tr><th scope="row"><label for="vladimir_email_to"><strong>Recipient Email *</strong></label></th><td><input type="email" name="vladimir_email_to" id="vladimir_email_to" value="<?php echo esc_attr( $to ); ?>" class="regular-text" required style="width:100%;"><p class="description">Use an inbox you control.</p></td></tr>
                <tr><th scope="row"><label for="vladimir_from_name"><strong>From Name</strong></label></th><td><input type="text" name="vladimir_from_name" id="vladimir_from_name" value="<?php echo esc_attr( $from_name ); ?>" class="regular-text" style="width:100%;"></td></tr>
                <tr><th scope="row"><label for="vladimir_from_email"><strong>From Email</strong></label></th><td><input type="email" name="vladimir_from_email" id="vladimir_from_email" value="<?php echo esc_attr( $from_email ); ?>" class="regular-text" style="width:100%;"></td></tr>
                <tr><th scope="row"><label for="vladimir_email_subject"><strong>Subject</strong></label></th><td><input type="text" name="vladimir_email_subject" id="vladimir_email_subject" value="<?php echo esc_attr( $subject ); ?>" class="regular-text" style="width:100%;"></td></tr>
                <tr><th scope="row"><label for="vladimir_email_message"><strong>Message Text</strong></label></th><td><textarea name="vladimir_email_message" id="vladimir_email_message" rows="7" class="large-text"><?php echo esc_textarea( $message_text ); ?></textarea><p class="description">Plain English text only. The current site logo, website button, and URL are inserted automatically.</p></td></tr>
            </table>
            <?php $logo_preview = vladimir_test_email_get_logo_url(); ?>
            <?php if ( ! empty( $logo_preview ) ) : ?>
                <div style="margin:18px 0;padding:18px;text-align:center;background:#f8fafc;border:1px solid #dbe3ec;border-radius:6px;">
                    <p style="margin:0 0 12px;font-weight:600;">Logo included in the email</p>
                    <img src="<?php echo esc_url( $logo_preview ); ?>" alt="<?php echo esc_attr( get_bloginfo( 'name' ) ); ?>" style="max-width:240px;max-height:90px;width:auto;height:auto;">
                </div>
            <?php endif; ?>
            <p><input type="submit" name="vladimir_send_test" class="button button-primary button-hero" value="Send Test Email"></p>
        </form>
    </div>
    <?php
}
