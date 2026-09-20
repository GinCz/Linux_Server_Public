<?php
/**
 * Plugin Name: WP Test Email Micro (VladiMIR+AIâś…)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-test-email-micro
 * Description: Instant diagnostic email test tool for WordPress. Send test emails via wp_mail() on demand to verify SMTP/PHP mail delivery. Zero persistent background processes, zero database pollution.
 * Version:     2026-09__1.28
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

// Shared auto-update client (public GitHub repository).
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
    $lang = ( function_exists( 'vladimir_ai_i18n_lang' ) ) ? vladimir_ai_i18n_lang() : get_locale();
    $page_title = ( 'ru_RU' === $lang || strpos( $lang, 'ru' ) === 0 ) ? 'Đ”Đ¸Đ°ĐłĐ˝ĐľŃŃ‚Đ¸ĐşĐ° ĐżĐľŃ‡Ń‚Ń‹ (WP Test Email)' : ( ( 'cs_CZ' === $lang || strpos( $lang, 'cs' ) === 0 ) ? 'Test e-mailu (WP Test Email)' : 'Test Email Diagnostic' );

    add_management_page(
        $page_title,
        'Test Email',
        'manage_options',
        'vladimir-test-email',
        'vladimir_test_email_render_page'
    );
}

function vladimir_test_email_action_links( $links ) {
    $lang = ( function_exists( 'vladimir_ai_i18n_lang' ) ) ? vladimir_ai_i18n_lang() : get_locale();
    $label = ( 'ru_RU' === $lang || strpos( $lang, 'ru' ) === 0 ) ? 'Đ˘ĐµŃŃ‚ ĐżĐľŃ‡Ń‚Ń‹' : ( ( 'cs_CZ' === $lang || strpos( $lang, 'cs' ) === 0 ) ? 'Test' : 'Test Email' );
    $test_link = '<a href="' . esc_url( admin_url( 'tools.php?page=vladimir-test-email' ) ) . '">' . esc_html( $label ) . '</a>';
    array_unshift( $links, $test_link );
    return $links;
}

/**
 * Đ“ĐµĐ˝ĐµŃ€Đ°Ń‚ĐľŃ€ Ń€ĐµĐ°Đ»Đ¸ŃŃ‚Đ¸Ń‡Đ˝ĐľĐłĐľ Đ¸ ŃĐ˝Đ¸ĐşĐ°Đ»ŃŚĐ˝ĐľĐłĐľ ĐşĐľĐ˝Ń‚ĐµĐ˝Ń‚Đ° ĐżĐ¸ŃŃŚĐĽĐ° Đ´Đ»ŃŹ ŃŃĐżĐµŃĐ˝ĐľĐłĐľ ĐżŃ€ĐľŃ…ĐľĐ¶Đ´ĐµĐ˝Đ¸ŃŹ SPF/DKIM ŃĐżĐ°ĐĽ-Ń‚ĐµŃŃ‚ĐľĐ˛
 */
function vladimir_test_email_generate_content( $lang ) {
    $site_name = get_bloginfo( 'name' );
    $site_url  = home_url();
    $admin_email = get_option( 'admin_email' );
    $date_str  = current_time( 'Y-m-d H:i:s' );
    $rnd_id    = substr( md5( uniqid( (string) mt_rand(), true ) ), 0, 8 );

    $sample_title = '';
    $sample_text  = '';
    $sample_url   = '';

    $posts = get_posts( array(
        'post_type'      => array( 'product', 'post', 'page' ),
        'post_status'    => 'publish',
        'posts_per_page' => 5,
        'orderby'        => 'rand'
    ) );

    if ( ! empty( $posts ) ) {
        $p = $posts[0];
        $sample_title = get_the_title( $p );
        $sample_url   = get_permalink( $p );
        $raw_content  = ! empty( $p->post_excerpt ) ? $p->post_excerpt : $p->post_content;
        $sample_text  = wp_trim_words( wp_strip_all_tags( strip_shortcodes( $raw_content ) ), 40, '...' );
    }

    if ( 'ru' === $lang ) {
        $subject = "{$site_name} â€” ĐźŃ€ĐľĐ˛ĐµŃ€ĐşĐ° Đ´ĐľŃŃ‚Đ°Đ˛ĐşĐ¸ ĐżĐľŃ‡Ń‚Ń‹ Đ¸ Đ˝Đ°ŃŃ‚Ń€ĐľĐµĐş SPF/DKIM [#{$rnd_id}]";
        if ( ! empty( $sample_title ) && ! empty( $sample_text ) ) {
            $body = "Đ—Đ´Ń€Đ°Đ˛ŃŃ‚Đ˛ŃĐąŃ‚Đµ!

"
                  . "Đ­Ń‚Đľ Đ´Đ¸Đ°ĐłĐ˝ĐľŃŃ‚Đ¸Ń‡ĐµŃĐşĐľĐµ Ń‚ĐµŃŃ‚ĐľĐ˛ĐľĐµ ŃĐľĐľĐ±Ń‰ĐµĐ˝Đ¸Đµ Ń ŃĐ°ĐąŃ‚Đ° "{$site_name}" ({$site_url}).

"
                  . "ĐĐşŃ‚ŃĐ°Đ»ŃŚĐ˝Đ°ŃŹ ĐżĐľĐ·Đ¸Ń†Đ¸ŃŹ ĐşĐ°Ń‚Đ°Đ»ĐľĐłĐ° / ĐżŃĐ±Đ»Đ¸ĐşĐ°Ń†Đ¸ŃŹ:
"
                  . "â€˘ ĐťĐ°Đ¸ĐĽĐµĐ˝ĐľĐ˛Đ°Đ˝Đ¸Đµ: {$sample_title}
"
                  . "â€˘ ĐžĐżĐ¸ŃĐ°Đ˝Đ¸Đµ: {$sample_text}
"
                  . "â€˘ ĐźĐľĐ´Ń€ĐľĐ±Đ˝ĐµĐµ Đ˝Đ° ŃĐ°ĐąŃ‚Đµ: {$sample_url}

"
                  . "--------------------------------------------------
"
                  . "Đ˘ĐµŃ…Đ˝Đ¸Ń‡ĐµŃĐşĐ¸Đµ ĐżĐ°Ń€Đ°ĐĽĐµŃ‚Ń€Ń‹ ĐľŃ‚ĐżŃ€Đ°Đ˛ĐşĐ¸:
"
                  . "â€˘ ĐŃŃ‚ĐľŃ‡Đ˝Đ¸Đş: wp_mail() / PHP / SMTP
"
                  . "â€˘ Đ’Ń€ĐµĐĽŃŹ ĐľŃ‚ĐżŃ€Đ°Đ˛ĐşĐ¸: {$date_str}
"
                  . "â€˘ Email Đ°Đ´ĐĽĐ¸Đ˝Đ¸ŃŃ‚Ń€Đ°Ń‚ĐľŃ€Đ°: {$admin_email}
"
                  . "â€˘ Đ˘ĐµŃŃ‚ĐľĐ˛Ń‹Đą Đ¸Đ´ĐµĐ˝Ń‚Đ¸Ń„Đ¸ĐşĐ°Ń‚ĐľŃ€: DKIM-SPF-OK-{$rnd_id}

"
                  . "Đ•ŃĐ»Đ¸ Đ´Đ°Đ˝Đ˝ĐľĐµ ĐżĐ¸ŃŃŚĐĽĐľ ĐżĐľĐ»ŃŃ‡ĐµĐ˝Đľ Đ˛ ŃĐµŃ€Đ˛Đ¸ŃĐµ Mail-Tester, Đ˝Đ°ŃŃ‚Ń€ĐľĐąĐşĐ¸ ĐżĐľŃ‡Ń‚ĐľĐ˛ĐľĐłĐľ ŃĐ»ŃŽĐ·Đ° ĐşĐľŃ€Ń€ĐµĐşŃ‚Đ˝Ń‹.
"
                  . "Đˇ ŃĐ˛Đ°Đ¶ĐµĐ˝Đ¸ĐµĐĽ, ĐşĐľĐĽĐ°Đ˝Đ´Đ° {$site_name}.";
        } else {
            $body = "Đ—Đ´Ń€Đ°Đ˛ŃŃ‚Đ˛ŃĐąŃ‚Đµ!

"
                  . "Đ­Ń‚Đľ ĐżŃ€ĐľĐ˛ĐµŃ€ĐľŃ‡Đ˝ĐľĐµ Đ´Đ¸Đ°ĐłĐ˝ĐľŃŃ‚Đ¸Ń‡ĐµŃĐşĐľĐµ ĐżĐ¸ŃŃŚĐĽĐľ ĐľŃ‚ Đ˛ĐµĐ±-Ń€ĐµŃŃŃ€ŃĐ° "{$site_name}" ({$site_url}).

"
                  . "ĐˇĐľĐľĐ±Ń‰ĐµĐ˝Đ¸Đµ ŃŃ„ĐľŃ€ĐĽĐ¸Ń€ĐľĐ˛Đ°Đ˝Đľ Đ´Đ»ŃŹ Ń‚ĐµŃŃ‚Đ¸Ń€ĐľĐ˛Đ°Đ˝Đ¸ŃŹ Đ´ĐľŃŃ‚Đ°Đ˛Đ»ŃŹĐµĐĽĐľŃŃ‚Đ¸, Đ˛Đ°Đ»Đ¸Đ´Đ˝ĐľŃŃ‚Đ¸ Ń†Đ¸Ń„Ń€ĐľĐ˛Ń‹Ń… ĐżĐľĐ´ĐżĐ¸ŃĐµĐą DKIM, ŃĐľĐľŃ‚Đ˛ĐµŃ‚ŃŃ‚Đ˛Đ¸ŃŹ SPF-Đ·Đ°ĐżĐ¸ŃĐ¸ Đ¸ ĐşĐľŃ€Ń€ĐµĐşŃ‚Đ˝ĐľŃŃ‚Đ¸ DMARC ĐżĐľĐ»Đ¸Ń‚Đ¸ĐşĐ¸ ŃĐµŃ€Đ˛ĐµŃ€Đ°.

"
                  . "--------------------------------------------------
"
                  . "ĐźĐ°Ń€Đ°ĐĽĐµŃ‚Ń€Ń‹ ĐľĐşŃ€ŃĐ¶ĐµĐ˝Đ¸ŃŹ:
"
                  . "â€˘ Đ’Ń€ĐµĐĽŃŹ ŃĐµŃ€Đ˛ĐµŃ€Đ°: {$date_str}
"
                  . "â€˘ ĐĐ´ĐĽĐ¸Đ˝Đ¸ŃŃ‚Ń€Đ°Ń‚ĐľŃ€: {$admin_email}
"
                  . "â€˘ ĐšĐľĐ˝Ń‚Ń€ĐľĐ»ŃŚĐ˝Ń‹Đą ĐşĐľĐ´: TEST-MSG-{$rnd_id}

"
                  . "Đˇ ŃĐ˛Đ°Đ¶ĐµĐ˝Đ¸ĐµĐĽ,
ĐˇĐ»ŃĐ¶Đ±Đ° Ń‚ĐµŃ…Đ˝Đ¸Ń‡ĐµŃĐşĐľĐą ĐżĐľĐ´Đ´ĐµŃ€Đ¶ĐşĐ¸ {$site_name}.";
        }
    } elseif ( 'cs' === $lang ) {
        $subject = "{$site_name} â€” Test doruÄŤitelnosti e-mailu a SPF/DKIM [#{$rnd_id}]";
        $body = "DobrĂ˝ den,

"
              . "toto je diagnostickĂˇ testovacĂ­ zprĂˇva z webu "{$site_name}" ({$site_url}).

"
              . ( ! empty( $sample_title ) ? "AktuĂˇlnĂ­ poloĹľka: {$sample_title}
Odkaz: {$sample_url}

" : "" )
              . "--------------------------------------------------
"
              . "TechnickĂ© podrobnosti:
"
              . "â€˘ ÄŚas odeslĂˇnĂ­: {$date_str}
"
              . "â€˘ SprĂˇvce: {$admin_email}
"
              . "â€˘ Test ID: DKIM-SPF-{$rnd_id}

"
              . "S pozdravem,
TĂ˝m {$site_name}";
    } else {
        $subject = "{$site_name} â€” Email Deliverability & SPF/DKIM Diagnostic [#{$rnd_id}]";
        $body = "Hello,

"
              . "This is an automated diagnostic message dispatched from "{$site_name}" ({$site_url}).

"
              . ( ! empty( $sample_title ) ? "Featured publication: {$sample_title}
Link: {$sample_url}

" : "" )
              . "--------------------------------------------------
"
              . "Technical details:
"
              . "â€˘ Dispatch timestamp: {$date_str}
"
              . "â€˘ Admin contact: {$admin_email}
"
              . "â€˘ Checksum ID: SPF-DKIM-{$rnd_id}

"
              . "Best regards,
{$site_name} Support Team";
    }

    return array( 'subject' => $subject, 'body' => $body );
}

function vladimir_test_email_render_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }

    $locale = ( function_exists( 'vladimir_ai_i18n_lang' ) ) ? vladimir_ai_i18n_lang() : get_locale();
    $lang   = ( strpos( $locale, 'ru' ) === 0 ) ? 'ru' : ( ( strpos( $locale, 'cs' ) === 0 ) ? 'cs' : 'en' );

    $default_from_name  = get_bloginfo( 'name' );
    $default_from_email = get_option( 'admin_email' );
    $gen_content        = vladimir_test_email_generate_content( $lang );

    $to         = isset( $_POST['vladimir_email_to'] ) ? sanitize_email( wp_unslash( $_POST['vladimir_email_to'] ) ) : '';
    $from_name  = isset( $_POST['vladimir_from_name'] ) ? sanitize_text_field( wp_unslash( $_POST['vladimir_from_name'] ) ) : $default_from_name;
    $from_email = isset( $_POST['vladimir_from_email'] ) ? sanitize_email( wp_unslash( $_POST['vladimir_from_email'] ) ) : $default_from_email;
    $subject    = isset( $_POST['vladimir_email_subject'] ) ? sanitize_text_field( wp_unslash( $_POST['vladimir_email_subject'] ) ) : $gen_content['subject'];
    $message    = isset( $_POST['vladimir_email_message'] ) ? sanitize_textarea_field( wp_unslash( $_POST['vladimir_email_message'] ) ) : $gen_content['body'];

    $result_msg = '';
    $result_ok  = false;

    if ( isset( $_POST['vladimir_send_test'] ) && check_admin_referer( 'vladimir_test_email_action', 'vladimir_nonce' ) ) {
        if ( empty( $to ) || ! is_email( $to ) ) {
            $result_msg = ( 'ru' === $lang ) ? 'ĐžŃĐ¸Đ±ĐşĐ°: ĐźĐľĐ»Đµ Â«ĐźĐľĐ»ŃŃ‡Đ°Ń‚ĐµĐ»ŃŚÂ» Đ˝Đµ ĐĽĐľĐ¶ĐµŃ‚ Đ±Ń‹Ń‚ŃŚ ĐżŃŃŃ‚Ń‹ĐĽ! ĐŁĐşĐ°Đ¶Đ¸Ń‚Đµ ĐşĐľŃ€Ń€ĐµĐşŃ‚Đ˝Ń‹Đą email Đ°Đ´Ń€ĐµŃ.' : 'Error: Recipient email cannot be empty! Please provide a valid email address.';
        } else {
            $sent_subject = $subject ?: ( '[' . get_bloginfo( 'name' ) . '] Diagnostic Test Email' );
            $sent_body    = $message;

            $headers = array( 'Content-Type: text/plain; charset=UTF-8' );

            if ( is_email( $from_email ) ) {
                $headers[] = 'From: ' . $from_name . ' <' . $from_email . '>';
            }

            $mail_error = '';
            add_action( 'wp_mail_failed', function( $wp_error ) use ( &$mail_error ) {
                if ( is_wp_error( $wp_error ) ) {
                    $mail_error = $wp_error->get_error_message();
                }
            } );

            $sent = wp_mail( $to, $sent_subject, $sent_body, $headers );

            if ( $sent ) {
                $result_ok  = true;
                $result_msg = ( 'ru' === $lang ) ? "âś… ĐźĐ¸ŃŃŚĐĽĐľ ŃŃĐżĐµŃĐ˝Đľ ĐľŃ‚ĐżŃ€Đ°Đ˛Đ»ĐµĐ˝Đľ Đ˝Đ° {$to}!" : "âś… Test email successfully dispatched to {$to}!";
            } else {
                $result_msg = ( 'ru' === $lang ) ? "âťŚ ĐžŃĐ¸Đ±ĐşĐ° ĐľŃ‚ĐżŃ€Đ°Đ˛ĐşĐ¸ ĐżĐ¸ŃŃŚĐĽĐ° Đ˝Đ° {$to}. " . ( $mail_error ? "Đ”ĐµŃ‚Đ°Đ»Đ¸: {$mail_error}" : 'ĐźŃ€ĐľĐ˛ĐµŃ€ŃŚŃ‚Đµ Đ˝Đ°ŃŃ‚Ń€ĐľĐąĐşĐ¸ ĐżĐľŃ‡Ń‚ĐľĐ˛ĐľĐłĐľ ŃĐµŃ€Đ˛ĐµŃ€Đ°.' ) : "âťŚ Failed to send email to {$to}. " . ( $mail_error ?: 'Check your SMTP settings.' );
            }
        }
    }

    if ( 'ru' === $lang ) {
        $txt_title    = 'WP Test Email: Đ”Đ¸Đ°ĐłĐ˝ĐľŃŃ‚Đ¸ĐşĐ° ĐľŃ‚ĐżŃ€Đ°Đ˛ĐşĐ¸ ĐżĐľŃ‡Ń‚Ń‹';
        $txt_subtitle = 'ĐśĐłĐ˝ĐľĐ˛ĐµĐ˝Đ˝Đ°ŃŹ ĐżŃ€ĐľĐ˛ĐµŃ€ĐşĐ° Ń„ŃĐ˝ĐşŃ†Đ¸Đ¸ wp_mail(), Đ´ĐľŃŃ‚Đ°Đ˛Đ»ŃŹĐµĐĽĐľŃŃ‚Đ¸ ĐżĐ¸ŃĐµĐĽ Đ¸ ĐşĐľŃ€Ń€ĐµĐşŃ‚Đ˝ĐľŃŃ‚Đ¸ SPF/DKIM.';
        $txt_to       = 'ĐźĐľĐ»ŃŃ‡Đ°Ń‚ĐµĐ»ŃŚ (Email)';
        $txt_sub      = 'Đ˘ĐµĐĽĐ° ĐżĐ¸ŃŃŚĐĽĐ°';
        $txt_name     = 'ĐĐĽŃŹ ĐľŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ĐµĐ»ŃŹ (From Name)';
        $txt_from     = 'Email ĐľŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ĐµĐ»ŃŹ (From Email)';
        $txt_body     = 'Đ˘ĐµĐşŃŃ‚ ĐżĐ¸ŃŃŚĐĽĐ°';
        $txt_btn      = 'ĐžŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ŃŚ Ń‚ĐµŃŃ‚ĐľĐ˛ĐľĐµ ĐżĐ¸ŃŃŚĐĽĐľ';
        $txt_tester_title = 'đź”Ť Đ˘ĐµŃŃ‚Đ¸Ń€ĐľĐ˛Đ°Đ˝Đ¸Đµ ĐşĐ°Ń‡ĐµŃŃ‚Đ˛Đ° Đ´ĐľŃŃ‚Đ°Đ˛ĐşĐ¸ Đ¸ ĐżĐľĐ´ĐżĐ¸ŃĐµĐą SPF / DKIM / DMARC';
        $txt_tester_desc  = 'Đ”Đ»ŃŹ ĐşĐľĐĽĐżĐ»ĐµĐşŃĐ˝ĐľĐą ĐżŃ€ĐľĐ˛ĐµŃ€ĐşĐ¸ ĐżĐµŃ€ĐµĐąĐ´Đ¸Ń‚Đµ Đ˝Đ° ŃĐµŃ€Đ˛Đ¸Ń <a href="https://www.mail-tester.com/" target="_blank" rel="noopener noreferrer" style="font-weight:700;color:#2271b1;text-decoration:underline;">mail-tester.com â†—</a>, ŃĐşĐľĐżĐ¸Ń€ŃĐąŃ‚Đµ Đ˛Ń€ĐµĐĽĐµĐ˝Đ˝Ń‹Đą email-Đ°Đ´Ń€ĐµŃ (Đ˝Đ°ĐżŃ€Đ¸ĐĽĐµŃ€: <code>test-xxxx@srv1.mail-tester.com</code>), Đ˛ŃŃ‚Đ°Đ˛ŃŚŃ‚Đµ ĐµĐłĐľ Đ˛ ĐżĐľĐ»Đµ <strong>Â«ĐźĐľĐ»ŃŃ‡Đ°Ń‚ĐµĐ»ŃŚÂ»</strong> Đ˝Đ¸Đ¶Đµ Đ¸ Đ˝Đ°Đ¶ĐĽĐ¸Ń‚Đµ <strong>Â«ĐžŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ŃŚÂ»</strong>.';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'WP Test Email: Test odesĂ­lĂˇnĂ­ e-mailĹŻ';
        $txt_subtitle = 'OkamĹľitĂ© otestovĂˇnĂ­ funkce wp_mail() a doruÄŤovĂˇnĂ­ zprĂˇv.';
        $txt_to       = 'PĹ™Ă­jemce (Email)';
        $txt_sub      = 'PĹ™edmÄ›t zprĂˇvy';
        $txt_name     = 'JmĂ©no odesĂ­latele';
        $txt_from     = 'E-mail odesĂ­latele';
        $txt_body     = 'Text zprĂˇvy';
        $txt_btn      = 'Odeslat testovacĂ­ e-mail';
        $txt_tester_title = 'đź”Ť Test doruÄŤitelnosti a podpisĹŻ SPF / DKIM / DMARC';
        $txt_tester_desc  = 'Pro otestovĂˇnĂ­ otevĹ™ete <a href="https://www.mail-tester.com/" target="_blank" rel="noopener noreferrer" style="font-weight:700;color:#2271b1;text-decoration:underline;">mail-tester.com â†—</a>, zkopĂ­rujte testovacĂ­ e-mail a vloĹľte jej nĂ­Ĺľe do pole <strong>PĹ™Ă­jemce</strong>.';
    } else {
        $txt_title    = 'WP Test Email: Diagnostic Mail Dispatch';
        $txt_subtitle = 'On-demand verification of wp_mail() delivery through local PHP mail or SMTP.';
        $txt_to       = 'Recipient Email';
        $txt_sub      = 'Subject Line';
        $txt_name     = 'From Name';
        $txt_from     = 'From Email';
        $txt_body     = 'Message Body';
        $txt_btn      = 'Send Test Email';
        $txt_tester_title = 'đź”Ť SPF / DKIM / DMARC & Spam Deliverability Test';
        $txt_tester_desc  = 'To test spam score and DKIM/SPF signatures, open <a href="https://www.mail-tester.com/" target="_blank" rel="noopener noreferrer" style="font-weight:700;color:#2271b1;text-decoration:underline;">mail-tester.com â†—</a>, copy your temporary test address, paste it into <strong>Recipient Email</strong> below and click Send.';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>âś‰ď¸Ź <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AIâś…)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:15px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <!-- Mail-Tester Helper Card -->
        <div style="background:#f0f6fc; border-left:4px solid #2271b1; padding:14px 18px; border-radius:6px; margin-bottom:20px; box-shadow:0 1px 2px rgba(0,0,0,.04);">
            <div style="font-size:14px; font-weight:700; color:#1d2327; margin-bottom:6px;">
                <?php echo $txt_tester_title; ?>
            </div>
            <div style="font-size:13px; color:#475569; line-height:1.5;">
                <?php echo $txt_tester_desc; ?>
            </div>
        </div>

        <?php if ( ! empty( $result_msg ) ) : ?>
            <div class="notice <?php echo $result_ok ? 'notice-success' : 'notice-error'; ?> is-dismissible" style="margin-left:0; margin-bottom:20px;">
                <p style="font-size:14px;"><strong><?php echo esc_html( $result_msg ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_test_email_action', 'vladimir_nonce' ); ?>

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="vladimir_email_to"><strong><?php echo esc_html( $txt_to ); ?> *</strong></label></th>
                    <td>
                        <input type="email" name="vladimir_email_to" id="vladimir_email_to" value="<?php echo esc_attr( $to ); ?>" class="regular-text" placeholder="test-xxxx@srv1.mail-tester.com" style="width:100%;font-size:14px;padding:6px 10px;">
                        <p class="description" style="color:#64748b;margin-top:4px;">
                            <?php echo ( 'ru' === $lang ) ? 'ĐźĐľĐ»Đµ ĐżŃŃŃ‚ĐľĐµ ĐżĐľ ŃĐĽĐľĐ»Ń‡Đ°Đ˝Đ¸ŃŽ. Đ’ŃŃ‚Đ°Đ˛ŃŚŃ‚Đµ Đ˛Ń€ĐµĐĽĐµĐ˝Đ˝Ń‹Đą Đ°Đ´Ń€ĐµŃ Ń mail-tester.com Đ¸Đ»Đ¸ Đ»Đ¸Ń‡Đ˝Ń‹Đą email.' : 'Leave empty by default or enter your destination test address.'; ?>
                        </p>
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
                        <input type="text" name="vladimir_email_subject" id="vladimir_email_subject" value="<?php echo esc_attr( $subject ); ?>" class="regular-text" style="width:100%;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_email_message"><strong><?php echo esc_html( $txt_body ); ?></strong></label></th>
                    <td>
                        <textarea name="vladimir_email_message" id="vladimir_email_message" rows="9" class="large-text" style="font-family:monospace;font-size:13px;"><?php echo esc_textarea( $message ); ?></textarea>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <input type="submit" name="vladimir_send_test" class="button button-primary button-hero" value="<?php echo esc_attr( $txt_btn ); ?>">
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            âšˇ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-test-email-micro" target="_blank" rel="noopener noreferrer" style="text-decoration:none;">GitHub Docs â†—</a>
        </p>
    </div>
    <?php
}
