<?php
/**
 * Plugin Name: WP Test Email Micro (VladiMIR+AIâś…)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-test-email-micro
 * Description: Instant diagnostic email test tool for WordPress. Send test emails via wp_mail() on demand to verify SMTP/PHP mail delivery. Zero persistent background processes, zero database pollution.
 * Version:     2026-09__1.29
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
 * ĐźĐľĐ¸ŃĐş Đ»ĐľĐłĐľŃ‚Đ¸ĐżĐ° ŃĐ°ĐąŃ‚Đ° Đ¸Đ»Đ¸ Đ¸Đ·ĐľĐ±Ń€Đ°Đ¶ĐµĐ˝Đ¸ŃŹ Đ´Đ»ŃŹ Ń‚ĐµŃŃ‚Đ° HTML-ĐżĐ¸ŃĐµĐĽ
 */
function vladimir_test_email_get_logo_url() {
    $custom_logo_id = get_theme_mod( 'custom_logo' );
    if ( $custom_logo_id ) {
        $logo_data = wp_get_attachment_image_src( $custom_logo_id, 'full' );
        if ( ! empty( $logo_data[0] ) ) {
            return esc_url( $logo_data[0] );
        }
    }

    $site_icon = get_site_icon_url( 256 );
    if ( ! empty( $site_icon ) ) {
        return esc_url( $site_icon );
    }

    // ĐŃ‰ĐµĐĽ ĐĽĐ¸Đ˝Đ¸Đ°Ń‚ŃŽŃ€Ń Ń‚ĐľĐ˛Đ°Ń€Đ°/ĐżĐľŃŃ‚Đ°
    $posts = get_posts( array(
        'post_type'      => array( 'product', 'post' ),
        'post_status'    => 'publish',
        'posts_per_page' => 1,
        'meta_key'       => '_thumbnail_id',
    ) );
    if ( ! empty( $posts ) ) {
        $thumb = get_the_post_thumbnail_url( $posts[0], 'medium' );
        if ( ! empty( $thumb ) ) {
            return esc_url( $thumb );
        }
    }

    return '';
}

/**
 * Đ“ĐµĐ˝ĐµŃ€Đ°Ń‚ĐľŃ€ ĐżŃ€ĐľŃ„ĐµŃŃĐ¸ĐľĐ˝Đ°Đ»ŃŚĐ˝ĐľĐłĐľ HTML-ĐżĐ¸ŃŃŚĐĽĐ° Đ˝Đ° Đ°Đ˝ĐłĐ»Đ¸ĐąŃĐşĐľĐĽ ŃŹĐ·Ń‹ĐşĐµ Ń Đ»ĐľĐłĐľŃ‚Đ¸ĐżĐľĐĽ
 */
function vladimir_test_email_generate_content() {
    $site_name   = get_bloginfo( 'name' );
    $site_url    = home_url();
    $admin_email = get_option( 'admin_email' );
    $date_str    = current_time( 'Y-m-d H:i:s' ) . ' (UTC' . get_option( 'gmt_offset' ) . ')';
    $rnd_id      = strtoupper( substr( md5( uniqid( (string) mt_rand(), true ) ), 0, 8 ) );
    $logo_url    = vladimir_test_email_get_logo_url();

    // ĐˇĐ»ŃŃ‡Đ°ĐąĐ˝Ń‹Đą Ń‚ĐľĐ˛Đ°Ń€ Đ¸Đ»Đ¸ ĐżŃĐ±Đ»Đ¸ĐşĐ°Ń†Đ¸ŃŹ Đ´Đ»ŃŹ ĐµŃŃ‚ĐµŃŃ‚Đ˛ĐµĐ˝Đ˝ĐľĐłĐľ Ń‚ĐµĐşŃŃ‚Đ°
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
        $sample_text  = wp_trim_words( wp_strip_all_tags( strip_shortcodes( $raw_content ) ), 35, '...' );
    }

    $subject = "{$site_name} - Email Deliverability & SPF/DKIM/DMARC Verification [Test #{$rnd_id}]";

    // ĐˇĐ±ĐľŃ€ĐşĐ° ĐşŃ€Đ°ŃĐ¸Đ˛ĐľĐłĐľ HTML ŃĐ°Đ±Đ»ĐľĐ˝Đ° ĐżĐ¸ŃŃŚĐĽĐ°
    $logo_html = '';
    if ( ! empty( $logo_url ) ) {
        $logo_html = '<div style="text-align:center;padding-bottom:20px;border-bottom:2px solid #e2e8f0;margin-bottom:24px;">'
                   . '<img src="' . esc_url( $logo_url ) . '" alt="' . esc_attr( $site_name ) . '" style="max-height:75px;max-width:240px;height:auto;border:0;outline:none;" />'
                   . '</div>';
    }

    $featured_html = '';
    if ( ! empty( $sample_title ) ) {
        $featured_html = '<div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:6px;padding:16px;margin:20px 0;">'
                       . '<h3 style="margin:0 0 8px 0;font-size:16px;color:#1e293b;">' . esc_html( $sample_title ) . '</h3>'
                       . '<p style="margin:0 0 10px 0;font-size:14px;color:#475569;line-height:1.5;">' . esc_html( $sample_text ) . '</p>'
                       . '<a href="' . esc_url( $sample_url ) . '" style="color:#2563eb;font-size:13px;font-weight:600;text-decoration:none;">View Publication &rarr;</a>'
                       . '</div>';
    }

    $body = '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Email Verification</title></head>'
          . '<body style="margin:0;padding:20px;background-color:#f1f5f9;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#334155;">'
          . '<div style="max-width:600px;margin:0 auto;background:#ffffff;border-radius:8px;border:1px solid #cbd5e1;padding:32px;box-shadow:0 4px 6px -1px rgba(0,0,0,0.05);">'
          . $logo_html
          . '<h2 style="margin:0 0 16px 0;font-size:20px;color:#0f172a;font-weight:700;">Diagnostic Email Delivery Test</h2>'
          . '<p style="margin:0 0 14px 0;font-size:15px;line-height:1.6;color:#334155;">Hello,</p>'
          . '<p style="margin:0 0 16px 0;font-size:15px;line-height:1.6;color:#334155;">This is an automated diagnostic verification message dispatched from <strong style="color:#0f172a;">' . esc_html( $site_name ) . '</strong> (<a href="' . esc_url( $site_url ) . '" style="color:#2563eb;text-decoration:none;">' . esc_html( $site_url ) . '</a>).</p>'
          . '<p style="margin:0 0 16px 0;font-size:14px;line-height:1.6;color:#475569;">The purpose of this email is to evaluate mail routing integrity, DKIM signature authentication, SPF alignment, DMARC policy validation, and SpamAssassin deliverability scores on <a href="https://www.mail-tester.com/" style="color:#2563eb;font-weight:600;">Mail-Tester.com</a>.</p>'
          . $featured_html
          . '<table style="width:100%;border-collapse:collapse;margin:24px 0;font-size:13px;background:#f8fafc;border-radius:6px;overflow:hidden;border:1px solid #e2e8f0;">'
          . '<tr><th style="text-align:left;padding:10px 14px;border-bottom:1px solid #e2e8f0;color:#64748b;font-weight:600;width:40%;">Site Host:</th><td style="padding:10px 14px;border-bottom:1px solid #e2e8f0;color:#0f172a;font-weight:600;">' . esc_html( parse_url( $site_url, PHP_URL_HOST ) ) . '</td></tr>'
          . '<tr><th style="text-align:left;padding:10px 14px;border-bottom:1px solid #e2e8f0;color:#64748b;font-weight:600;">Sender Admin:</th><td style="padding:10px 14px;border-bottom:1px solid #e2e8f0;color:#0f172a;">' . esc_html( $admin_email ) . '</td></tr>'
          . '<tr><th style="text-align:left;padding:10px 14px;border-bottom:1px solid #e2e8f0;color:#64748b;font-weight:600;">Dispatch Time:</th><td style="padding:10px 14px;border-bottom:1px solid #e2e8f0;color:#0f172a;">' . esc_html( $date_str ) . '</td></tr>'
          . '<tr><th style="text-align:left;padding:10px 14px;color:#64748b;font-weight:600;">Checksum ID:</th><td style="padding:10px 14px;color:#0f172a;font-family:monospace;font-weight:700;">SPF-DKIM-' . esc_html( $rnd_id ) . '</td></tr>'
          . '</table>'
          . '<p style="margin:20px 0 0 0;font-size:13px;color:#64748b;line-height:1.5;">If this message arrived in your inbox or passed the spam test, the mail configuration on this server is healthy and functioning properly.</p>'
          . '<div style="margin-top:28px;padding-top:18px;border-top:1px solid #e2e8f0;font-size:12px;color:#94a3b8;text-align:center;">'
          . '&copy; ' . date('Y') . ' <strong>' . esc_html( $site_name ) . '</strong> &bull; Powered by VladiMIR+AI Suite'
          . '</div>'
          . '</div></body></html>';

    return array( 'subject' => $subject, 'body' => $body );
}

function vladimir_test_email_render_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }

    $default_from_name  = get_bloginfo( 'name' );
    $default_from_email = get_option( 'admin_email' );
    $gen_content        = vladimir_test_email_generate_content();

    $to         = isset( $_POST['vladimir_email_to'] ) ? sanitize_email( wp_unslash( $_POST['vladimir_email_to'] ) ) : '';
    $from_name  = isset( $_POST['vladimir_from_name'] ) ? sanitize_text_field( wp_unslash( $_POST['vladimir_from_name'] ) ) : $default_from_name;
    $from_email = isset( $_POST['vladimir_from_email'] ) ? sanitize_email( wp_unslash( $_POST['vladimir_from_email'] ) ) : $default_from_email;
    $subject    = isset( $_POST['vladimir_email_subject'] ) ? sanitize_text_field( wp_unslash( $_POST['vladimir_email_subject'] ) ) : $gen_content['subject'];
    $message    = isset( $_POST['vladimir_email_message'] ) ? wp_unslash( $_POST['vladimir_email_message'] ) : $gen_content['body'];

    $result_msg = '';
    $result_ok  = false;

    if ( isset( $_POST['vladimir_send_test'] ) && check_admin_referer( 'vladimir_test_email_action', 'vladimir_nonce' ) ) {
        if ( empty( $to ) || ! is_email( $to ) ) {
            $result_msg = 'ĐžŃĐ¸Đ±ĐşĐ°: ĐźĐľĐ»Đµ Â«ĐźĐľĐ»ŃŃ‡Đ°Ń‚ĐµĐ»ŃŚÂ» Đ˝Đµ ĐĽĐľĐ¶ĐµŃ‚ Đ±Ń‹Ń‚ŃŚ ĐżŃŃŃ‚Ń‹ĐĽ! ĐŁĐşĐ°Đ¶Đ¸Ń‚Đµ ĐşĐľŃ€Ń€ĐµĐşŃ‚Đ˝Ń‹Đą email Đ°Đ´Ń€ĐµŃ.';
        } else {
            $sent_subject = $subject ?: ( '[' . get_bloginfo( 'name' ) . '] Diagnostic Test Email' );
            $sent_body    = $message;

            $headers = array( 'Content-Type: text/html; charset=UTF-8' );

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
                $result_msg = "âś… HTML-ĐżĐ¸ŃŃŚĐĽĐľ Ń Đ»ĐľĐłĐľŃ‚Đ¸ĐżĐľĐĽ ŃŃĐżĐµŃĐ˝Đľ ĐľŃ‚ĐżŃ€Đ°Đ˛Đ»ĐµĐ˝Đľ Đ˝Đ° {$to}!";
            } else {
                $result_msg = "âťŚ ĐžŃĐ¸Đ±ĐşĐ° ĐľŃ‚ĐżŃ€Đ°Đ˛ĐşĐ¸ ĐżĐ¸ŃŃŚĐĽĐ° Đ˝Đ° {$to}. " . ( $mail_error ? "Đ”ĐµŃ‚Đ°Đ»Đ¸: {$mail_error}" : 'ĐźŃ€ĐľĐ˛ĐµŃ€ŃŚŃ‚Đµ Đ˝Đ°ŃŃ‚Ń€ĐľĐąĐşĐ¸ ĐżĐľŃ‡Ń‚ĐľĐ˛ĐľĐłĐľ ŃĐµŃ€Đ˛ĐµŃ€Đ°.' );
            }
        }
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;margin-bottom:10px;">
            <span>âś‰ď¸Ź WP Test Email: Đ”Đ¸Đ°ĐłĐ˝ĐľŃŃ‚Đ¸ĐşĐ° ĐľŃ‚ĐżŃ€Đ°Đ˛ĐşĐ¸ ĐżĐľŃ‡Ń‚Ń‹</span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AIâś…)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:18px;">
            ĐśĐłĐ˝ĐľĐ˛ĐµĐ˝Đ˝Đ°ŃŹ ĐżŃ€ĐľĐ˛ĐµŃ€ĐşĐ° Ń„ŃĐ˝ĐşŃ†Đ¸Đ¸ <code>wp_mail()</code>, HTML-Đ˛ĐµŃ€ŃŃ‚ĐşĐ¸ Ń Đ»ĐľĐłĐľŃ‚Đ¸ĐżĐľĐĽ Đ¸ Đ˛Đ°Đ»Đ¸Đ´Đ°Ń†Đ¸Đ¸ Ń†Đ¸Ń„Ń€ĐľĐ˛Ń‹Ń… ĐżĐľĐ´ĐżĐ¸ŃĐµĐą SPF, DKIM Đ¸ DMARC.
        </p>

        <!-- Mail-Tester Helper Card -->
        <div style="background:#f0f6fc; border-left:4px solid #2271b1; padding:16px 20px; border-radius:6px; margin-bottom:24px; box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <div style="font-size:15px; font-weight:700; color:#1d2327; margin-bottom:6px;">
                đź”Ť Đ˘ĐµŃŃ‚Đ¸Ń€ĐľĐ˛Đ°Đ˝Đ¸Đµ ĐşĐ°Ń‡ĐµŃŃ‚Đ˛Đ° Đ´ĐľŃŃ‚Đ°Đ˛ĐşĐ¸ Đ¸ ĐżĐľĐ´ĐżĐ¸ŃĐµĐą SPF / DKIM / DMARC
            </div>
            <div style="font-size:13.5px; color:#475569; line-height:1.55;">
                Đ”Đ»ŃŹ ĐżŃ€ĐľĐ˛ĐµŃ€ĐşĐ¸ ĐżĐµŃ€ĐµĐąĐ´Đ¸Ń‚Đµ Đ˝Đ° ŃĐµŃ€Đ˛Đ¸Ń <a href="https://www.mail-tester.com/" target="_blank" rel="noopener noreferrer" style="font-weight:700;color:#2271b1;text-decoration:underline;">mail-tester.com â†—</a>, ŃĐşĐľĐżĐ¸Ń€ŃĐąŃ‚Đµ Đ˛Ń‹Đ´Đ°Đ˝Đ˝Ń‹Đą Đ˛Ń€ĐµĐĽĐµĐ˝Đ˝Ń‹Đą Đ°Đ´Ń€ĐµŃ (Đ˝Đ°ĐżŃ€Đ¸ĐĽĐµŃ€: <code>test-xxxx@srv1.mail-tester.com</code>), Đ˛ŃŃ‚Đ°Đ˛ŃŚŃ‚Đµ ĐµĐłĐľ Đ˛ ĐżĐľĐ»Đµ <strong>Â«ĐźĐľĐ»ŃŃ‡Đ°Ń‚ĐµĐ»ŃŚÂ»</strong> Đ˝Đ¸Đ¶Đµ Đ¸ Đ˝Đ°Đ¶ĐĽĐ¸Ń‚Đµ <strong>Â«ĐžŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ŃŚ Ń‚ĐµŃŃ‚ĐľĐ˛ĐľĐµ ĐżĐ¸ŃŃŚĐĽĐľÂ»</strong>.
            </div>
        </div>

        <?php if ( ! empty( $result_msg ) ) : ?>
            <div class="notice <?php echo $result_ok ? 'notice-success' : 'notice-error'; ?> is-dismissible" style="margin-left:0; margin-bottom:20px;">
                <p style="font-size:14px;"><strong><?php echo esc_html( $result_msg ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="" style="background:#fff;padding:26px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_test_email_action', 'vladimir_nonce' ); ?>

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="vladimir_email_to"><strong>ĐźĐľĐ»ŃŃ‡Đ°Ń‚ĐµĐ»ŃŚ (Email) *</strong></label></th>
                    <td>
                        <input type="email" name="vladimir_email_to" id="vladimir_email_to" value="<?php echo esc_attr( $to ); ?>" class="regular-text" placeholder="test-xxxx@srv1.mail-tester.com" style="width:100%;font-size:14px;padding:7px 10px;">
                        <p class="description" style="color:#64748b;margin-top:5px;">
                            ĐźĐľĐ»Đµ ĐżŃŃŃ‚ĐľĐµ ĐżĐľ ŃĐĽĐľĐ»Ń‡Đ°Đ˝Đ¸ŃŽ. Đ’ŃŃ‚Đ°Đ˛ŃŚŃ‚Đµ Đ˛Ń€ĐµĐĽĐµĐ˝Đ˝Ń‹Đą ŃŹŃ‰Đ¸Đş Ń mail-tester.com Đ¸Đ»Đ¸ Đ»Đ¸Ń‡Đ˝ŃŃŽ ĐżĐľŃ‡Ń‚Ń.
                        </p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_from_name"><strong>ĐĐĽŃŹ ĐľŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ĐµĐ»ŃŹ (From Name)</strong></label></th>
                    <td>
                        <input type="text" name="vladimir_from_name" id="vladimir_from_name" value="<?php echo esc_attr( $from_name ); ?>" class="regular-text" style="width:100%;padding:6px 10px;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_from_email"><strong>Email ĐľŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ĐµĐ»ŃŹ (From Email)</strong></label></th>
                    <td>
                        <input type="email" name="vladimir_from_email" id="vladimir_from_email" value="<?php echo esc_attr( $from_email ); ?>" class="regular-text" style="width:100%;padding:6px 10px;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_email_subject"><strong>Đ˘ĐµĐĽĐ° ĐżĐ¸ŃŃŚĐĽĐ° (English Subject)</strong></label></th>
                    <td>
                        <input type="text" name="vladimir_email_subject" id="vladimir_email_subject" value="<?php echo esc_attr( $subject ); ?>" class="regular-text" style="width:100%;padding:6px 10px;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="vladimir_email_message"><strong>Đ¨Đ°Đ±Đ»ĐľĐ˝ HTML-ĐżĐ¸ŃŃŚĐĽĐ° Ń Đ»ĐľĐłĐľŃ‚Đ¸ĐżĐľĐĽ</strong></label></th>
                    <td>
                        <textarea name="vladimir_email_message" id="vladimir_email_message" rows="12" class="large-text" style="font-family:monospace;font-size:12.5px;line-height:1.4;"><?php echo esc_textarea( $message ); ?></textarea>
                        <p class="description" style="color:#64748b;margin-top:5px;">
                            HTML-ĐĽĐ°ĐşĐµŃ‚ Đ˝Đ° Đ°Đ˝ĐłĐ»Đ¸ĐąŃĐşĐľĐĽ ŃŹĐ·Ń‹ĐşĐµ ŃĐľ Đ˛ŃŃ‚Ń€ĐľĐµĐ˝Đ˝Ń‹ĐĽ Đ»ĐľĐłĐľŃ‚Đ¸ĐżĐľĐĽ ŃĐ°ĐąŃ‚Đ° Đ¸ Ń‚ĐµŃ…Đ˝Đ¸Ń‡ĐµŃĐşĐ¸ĐĽĐ¸ Đ·Đ°ĐłĐľĐ»ĐľĐ˛ĐşĐ°ĐĽĐ¸.
                        </p>
                    </td>
                </tr>
            </table>

            <div style="margin-top:22px;">
                <input type="submit" name="vladimir_send_test" class="button button-primary button-hero" value="ĐžŃ‚ĐżŃ€Đ°Đ˛Đ¸Ń‚ŃŚ Ń‚ĐµŃŃ‚ĐľĐ˛ĐľĐµ HTML-ĐżĐ¸ŃŃŚĐĽĐľ">
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            âšˇ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-test-email-micro" target="_blank" rel="noopener noreferrer" style="text-decoration:none;">GitHub Docs â†—</a>
        </p>
    </div>
    <?php
}
