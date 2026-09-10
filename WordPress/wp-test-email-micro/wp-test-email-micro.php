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
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( esc_html__( 'You are not allowed to send a test email.', 'wp-test-email-micro' ) );
    }

    $recipient = isset( $_POST['wtem_recipient'] ) ? sanitize_email( wp_unslash( $_POST['wtem_recipient'] ) ) : '';
    $subject   = isset( $_POST['wtem_subject'] ) ? sanitize_text_field( wp_unslash( $_POST['wtem_subject'] ) ) : 'WordPress test email';
    $notice    = '';
    $is_error  = false;

    if ( isset( $_POST['wtem_send'] ) ) {
        check_admin_referer( 'wtem_send_email', 'wtem_nonce' );

        if ( ! is_email( $recipient ) ) {
            $notice   = __( 'Enter a valid recipient email address.', 'wp-test-email-micro' );
            $is_error = true;
        } else {
            $body = sprintf(
                /* translators: %s: website name. */
                __( 'This is a test email sent from %s.', 'wp-test-email-micro' ),
                wp_specialchars_decode( get_bloginfo( 'name' ), ENT_QUOTES )
            );

            if ( wp_mail( $recipient, $subject, $body, array( 'Content-Type: text/plain; charset=UTF-8' ) ) ) {
                $notice = sprintf(
                    /* translators: %s: recipient email address. */
                    __( 'Test email accepted for delivery to %s.', 'wp-test-email-micro' ),
                    $recipient
                );
            } else {
                $notice   = __( 'WordPress could not hand the test email to the configured mail transport.', 'wp-test-email-micro' );
                $is_error = true;
            }
        }
    }
    ?>
    <div class="wrap">
        <h1><?php esc_html_e( 'Test Email', 'wp-test-email-micro' ); ?></h1>
        <p><?php esc_html_e( 'This tool sends one deliberate test message. It does not create database tables or record outgoing mail.', 'wp-test-email-micro' ); ?></p>
        <?php if ( '' !== $notice ) : ?>
            <div class="notice <?php echo $is_error ? 'notice-error' : 'notice-success'; ?>"><p><?php echo esc_html( $notice ); ?></p></div>
        <?php endif; ?>
        <form method="post">
            <?php wp_nonce_field( 'wtem_send_email', 'wtem_nonce' ); ?>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="wtem_recipient"><?php esc_html_e( 'Recipient', 'wp-test-email-micro' ); ?></label></th>
                    <td><input name="wtem_recipient" id="wtem_recipient" type="email" class="regular-text" value="<?php echo esc_attr( $recipient ); ?>" required></td>
                </tr>
                <tr>
                    <th scope="row"><label for="wtem_subject"><?php esc_html_e( 'Subject', 'wp-test-email-micro' ); ?></label></th>
                    <td><input name="wtem_subject" id="wtem_subject" type="text" class="regular-text" value="<?php echo esc_attr( $subject ); ?>" required></td>
                </tr>
            </table>
            <?php submit_button( __( 'Send Test Email', 'wp-test-email-micro' ), 'primary', 'wtem_send' ); ?>
        </form>
    </div>
    <?php
}
