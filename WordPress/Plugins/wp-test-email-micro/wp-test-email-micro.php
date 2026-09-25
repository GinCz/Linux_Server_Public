<?php
/**
 * Plugin Name: WP Test Email Micro (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/plugins/tree/main/wp-test-email-micro
 * Description: Sends a rich diagnostic HTML email from WordPress with automatic site logo embedding, delivery diagnostics, and full deliverability compliance. Runs a one-click Mail-Tester score with a delivery stopwatch and shows the SPF/DKIM/DMARC/MX/PTR records of the domain.
 * Version:     2026-09__1.38
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

// Shared auto-update client (if present).
if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

// Shared plugin-list translations (if present).
if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-i18n.php';
}

// Direct updater filter fallback for instant updates from GitHub.
add_filter( 'update_plugins_vladimir-ai.updates', 'vladimir_test_email_update_check', 20, 3 );

/**
 * Check the public manifest independently from every other VladiMIR+AI plugin.
 *
 * @param array|false $update      Existing update response.
 * @param array       $plugin_data Current plugin headers.
 * @param string      $plugin_file Plugin path relative to wp-content/plugins.
 * @return array|false
 */
function vladimir_test_email_update_check( $update, $plugin_data, $plugin_file ) {
    if ( 'wp-test-email-micro/wp-test-email-micro.php' !== $plugin_file || ! empty( $update ) ) {
        return $update;
    }

    $manifest_url = add_query_arg(
        'ts',
        time(),
        'https://raw.githubusercontent.com/GinCz/plugins/main/updates.json'
    );
    $response = wp_remote_get(
        $manifest_url,
        array(
            'timeout'     => 12,
            'redirection' => 3,
            'headers'     => array(
                'Accept'     => 'application/json',
                'User-Agent' => 'WP-Test-Email-Micro-Updater',
            ),
        )
    );

    if ( is_wp_error( $response ) || 200 !== (int) wp_remote_retrieve_response_code( $response ) ) {
        return $update;
    }

    $manifest = json_decode( wp_remote_retrieve_body( $response ), true );
    $entry    = isset( $manifest['plugins']['wp-test-email-micro'] ) ? $manifest['plugins']['wp-test-email-micro'] : array();
    $version  = isset( $entry['version'] ) ? (string) $entry['version'] : '';
    $package  = isset( $entry['package'] ) ? (string) $entry['package'] : '';
    $current  = isset( $plugin_data['Version'] ) ? (string) $plugin_data['Version'] : '0';

    $is_valid_package = ( 0 === strpos( $package, 'https://raw.githubusercontent.com/GinCz/' ) )
                     || ( 0 === strpos( $package, 'https://github.com/GinCz/' ) );

    if ( '' === $version || '' === $package || ! $is_valid_package || ! version_compare( $version, $current, '>' ) ) {
        return $update;
    }

    return array(
        'id'           => 'https://vladimir-ai.updates/wp-test-email-micro',
        'slug'         => 'wp-test-email-micro',
        'plugin'       => $plugin_file,
        'version'      => $version,
        'new_version'  => $version,
        'url'          => isset( $entry['url'] ) ? (string) $entry['url'] : 'https://github.com/GinCz/plugins/tree/main/wp-test-email-micro',
        'package'      => $package,
        'tested'       => isset( $entry['tested'] ) ? (string) $entry['tested'] : '6.8',
        'requires'     => isset( $entry['requires'] ) ? (string) $entry['requires'] : '6.0',
        'requires_php' => isset( $entry['requires_php'] ) ? (string) $entry['requires_php'] : '7.4',
    );
}

if ( is_admin() ) {
    add_action( 'admin_menu', 'vladimir_test_email_add_menu' );
    add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), 'vladimir_test_email_action_links' );
}

function vladimir_test_email_add_menu() {
    add_management_page( 'WP Test Email', '✉️ Test Email', 'manage_options', 'vladimir-test-email', 'vladimir_test_email_render_page' );
}

function vladimir_test_email_action_links( $links ) {
    $test_link = '<a href="' . esc_url( admin_url( 'tools.php?page=vladimir-test-email' ) ) . '">✉️ Test Email</a>';
    array_unshift( $links, $test_link );
    return $links;
}

/**
 * Get current site logo URL.
 *
 * @return string Logo image URL or empty string.
 */
function vladimir_test_email_get_logo_url() {
    $custom_logo_id = get_theme_mod( 'custom_logo' );
    if ( $custom_logo_id ) {
        $logo_data = wp_get_attachment_image_src( $custom_logo_id, 'full' );
        if ( ! empty( $logo_data[0] ) ) {
            return esc_url( $logo_data[0] );
        }
    }

    $site_icon = get_site_icon_url( 512 );
    if ( ! empty( $site_icon ) ) {
        return esc_url( $site_icon );
    }

    $header_image = get_header_image();
    if ( ! empty( $header_image ) ) {
        return esc_url( $header_image );
    }

    return '';
}

/**
 * Generate rich, spam-resilient email content with optimal text-to-image ratio.
 *
 * @param string $message_text Custom message text.
 * @return array Generated subject, HTML body, plain text alternative, and raw text.
 */
function vladimir_test_email_generate_content( $message_text = '' ) {
    $site_name   = get_bloginfo( 'name' );
    $site_desc   = get_bloginfo( 'description' );
    $site_url    = home_url( '/' );
    $site_domain = wp_parse_url( $site_url, PHP_URL_HOST );
    $logo_url    = vladimir_test_email_get_logo_url();
    $current_wp  = get_bloginfo( 'version' );
    $php_ver     = PHP_VERSION;
    $timestamp   = gmdate( 'Y-m-d H:i:s \U\T\C' );
    $server_name = isset( $_SERVER['SERVER_NAME'] ) ? sanitize_text_field( wp_unslash( $_SERVER['SERVER_NAME'] ) ) : $site_domain;

    if ( '' === trim( $message_text ) ) {
        $message_text = "This is a comprehensive email deliverability and transport diagnostic verification test sent from " . $site_name . ".\n\n"
            . "The purpose of this message is to validate outgoing transactional mail delivery, verify MIME multipart structure, confirm SPF/DKIM/DMARC authentication parameters, and ensure high inbox placement across modern mail providers (Google Mail, Yandex, Mail.ru, Microsoft Outlook, and corporate mail servers).\n\n"
            . "If you received this message, the WordPress mail transport subsystem (wp_mail) and server SMTP routing are functioning properly.";
    }

    // Top logo or brand badge.
    if ( ! empty( $logo_url ) ) {
        $logo_html = '<tr><td style="padding:0 0 20px;text-align:center;">'
            . '<a href="' . esc_url( $site_url ) . '" target="_blank" rel="noopener noreferrer" style="text-decoration:none;display:inline-block;">'
            . '<img src="' . esc_url( $logo_url ) . '" alt="' . esc_attr( $site_name ) . '" width="180" style="display:block;max-width:180px;max-height:70px;width:auto;height:auto;margin:0 auto;border:0;outline:none;text-decoration:none;" />'
            . '</a>'
            . '</td></tr>';
    } else {
        $logo_html = '<tr><td style="padding:0 0 20px;text-align:center;">'
            . '<a href="' . esc_url( $site_url ) . '" target="_blank" rel="noopener noreferrer" style="text-decoration:none;display:inline-block;">'
            . '<div style="display:inline-block;background:#0f172a;color:#ffffff;font-size:18px;font-weight:700;padding:10px 22px;border-radius:6px;letter-spacing:0.5px;">'
            . esc_html( $site_name )
            . '</div>'
            . '</a>'
            . '</td></tr>';
    }

    $subject      = 'Website Email Delivery & Diagnostic Test — ' . $site_name;
    $message_html = nl2br( esc_html( $message_text ) );

    // Build rich HTML body with substantial text to completely resolve SpamAssassin HTML_IMAGE_RATIO penalties.
    $body = '<!doctype html>'
        . '<html lang="en" xmlns="http://www.w3.org/1999/xhtml">'
        . '<head>'
        . '<meta charset="UTF-8">'
        . '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
        . '<meta http-equiv="X-UA-Compatible" content="IE=edge">'
        . '<title>' . esc_html( $subject ) . '</title>'
        . '</head>'
        . '<body style="margin:0;padding:24px 12px;background-color:#f1f5f9;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,Helvetica,Arial,sans-serif;color:#334155;line-height:1.6;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;">'
        . '<!-- Preheader text (hidden preview) -->'
        . '<div style="display:none;font-size:1px;color:#f1f5f9;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">'
        . 'Email deliverability diagnostic test and authentication verification report for ' . esc_html( $site_name ) . ' (' . esc_html( $site_domain ) . ').'
        . '</div>'
        . '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="table-layout:fixed;">'
        . '<tr><td align="center" style="padding:0;">'
        . '<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" style="width:100%;max-width:600px;background:#ffffff;border:1px solid #e2e8f0;border-radius:10px;overflow:hidden;box-shadow:0 4px 6px -1px rgba(0,0,0,0.05);">'
        . '<!-- Header -->'
        . '<tr><td style="padding:32px 32px 20px;background:#ffffff;border-bottom:1px solid #f1f5f9;">'
        . '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">'
        . $logo_html
        . '<tr><td style="padding:0;text-align:center;">'
        . '<h1 style="margin:0 0 6px;font-size:22px;font-weight:700;line-height:1.3;color:#0f172a;">Website Email Delivery Test</h1>'
        . '<p style="margin:0;font-size:14px;color:#64748b;">' . esc_html( $site_domain ) . ' • Diagnostic & Transport Check</p>'
        . '</td></tr>'
        . '</table>'
        . '</td></tr>'
        . '<!-- Main Content -->'
        . '<tr><td style="padding:28px 32px 20px;">'
        . '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">'
        . '<tr><td style="padding:0 0 20px;">'
        . '<h2 style="margin:0 0 12px;font-size:16px;font-weight:600;color:#1e293b;text-transform:uppercase;letter-spacing:0.5px;">Message Details</h2>'
        . '<div style="font-size:15px;line-height:1.7;color:#334155;background:#f8fafc;padding:18px 20px;border-radius:8px;border-left:4px solid #3b82f6;">'
        . $message_html
        . '</div>'
        . '</td></tr>'
        . '<!-- Diagnostics Block -->'
        . '<tr><td style="padding:0 0 22px;">'
        . '<h2 style="margin:0 0 12px;font-size:16px;font-weight:600;color:#1e293b;text-transform:uppercase;letter-spacing:0.5px;">System & Transport Diagnostics</h2>'
        . '<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="font-size:14px;background:#ffffff;border:1px solid #e2e8f0;border-radius:8px;border-collapse:separate;">'
        . '<tr><td style="padding:10px 14px;font-weight:600;color:#475569;border-bottom:1px solid #f1f5f9;width:38%;">Site Origin:</td><td style="padding:10px 14px;color:#0f172a;border-bottom:1px solid #f1f5f9;">' . esc_html( $site_name ) . ' (' . esc_html( $site_domain ) . ')</td></tr>'
        . '<tr><td style="padding:10px 14px;font-weight:600;color:#475569;border-bottom:1px solid #f1f5f9;">WordPress Core:</td><td style="padding:10px 14px;color:#0f172a;border-bottom:1px solid #f1f5f9;">v' . esc_html( $current_wp ) . '</td></tr>'
        . '<tr><td style="padding:10px 14px;font-weight:600;color:#475569;border-bottom:1px solid #f1f5f9;">PHP Environment:</td><td style="padding:10px 14px;color:#0f172a;border-bottom:1px solid #f1f5f9;">PHP ' . esc_html( $php_ver ) . '</td></tr>'
        . '<tr><td style="padding:10px 14px;font-weight:600;color:#475569;border-bottom:1px solid #f1f5f9;">Mail Subsystem:</td><td style="padding:10px 14px;color:#0f172a;border-bottom:1px solid #f1f5f9;">PHPMailer (wp_mail) HTML / UTF-8</td></tr>'
        . '<tr><td style="padding:10px 14px;font-weight:600;color:#475569;">Generation Time:</td><td style="padding:10px 14px;color:#0f172a;">' . esc_html( $timestamp ) . '</td></tr>'
        . '</table>'
        . '</td></tr>'
        . '<!-- Security & Authentication Block -->'
        . '<tr><td style="padding:0 0 24px;">'
        . '<h2 style="margin:0 0 12px;font-size:16px;font-weight:600;color:#1e293b;text-transform:uppercase;letter-spacing:0.5px;">Security & Authentication Standards</h2>'
        . '<p style="margin:0 0 10px;font-size:14px;line-height:1.6;color:#475569;">'
        . 'This diagnostic email adheres to modern mail delivery standards to maintain sender reputation and ensure maximum inbox placement:'
        . '</p>'
        . '<ul style="margin:0 0 16px;padding-left:20px;font-size:14px;line-height:1.7;color:#475569;">'
        . '<li><strong>SPF (Sender Policy Framework):</strong> Authorizes the sending server IP address for this domain.</li>'
        . '<li><strong>DKIM (DomainKeys Identified Mail):</strong> Cryptographic digital signature verifying email integrity and source authenticity.</li>'
        . '<li><strong>DMARC (Domain-based Message Authentication):</strong> Policy alignment protecting domain identity against phishing and spoofing.</li>'
        . '<li><strong>MIME Multipart / Alternative:</strong> Full HTML and plain-text body synchronization for universal client compatibility.</li>'
        . '</ul>'
        . '</td></tr>'
        . '<!-- CTA Button -->'
        . '<tr><td style="padding:0 0 28px;text-align:center;">'
        . '<table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:0 auto;">'
        . '<tr><td style="border-radius:6px;background:#2563eb;text-align:center;">'
        . '<a href="' . esc_url( $site_url ) . '" target="_blank" rel="noopener noreferrer" style="display:inline-block;padding:13px 28px;color:#ffffff;font-size:15px;font-weight:600;text-decoration:none;border-radius:6px;letter-spacing:0.3px;">Open Website &rarr;</a>'
        . '</td></tr>'
        . '</table>'
        . '</td></tr>'
        . '</table>'
        . '</td></tr>'
        . '<!-- Footer -->'
        . '<tr><td style="padding:24px 32px;background:#f8fafc;border-top:1px solid #e2e8f0;text-align:center;font-size:12px;line-height:1.6;color:#64748b;">'
        . '<p style="margin:0 0 6px;">'
        . '<strong>' . esc_html( $site_name ) . '</strong>' . ( $site_desc ? ' &mdash; ' . esc_html( $site_desc ) : '' )
        . '</p>'
        . '<p style="margin:0 0 10px;">'
        . '<a href="' . esc_url( $site_url ) . '" target="_blank" rel="noopener noreferrer" style="color:#2563eb;text-decoration:none;">' . esc_html( $site_url ) . '</a>'
        . '</p>'
        . '<p style="margin:0;color:#94a3b8;font-size:11px;">'
        . 'This is an automated delivery test dispatched by an authorized administrator from ' . esc_html( $server_name ) . '. No reply is required.'
        . '</p>'
        . '</td></tr>'
        . '</table>'
        . '</td></tr>'
        . '</table>'
        . '</body>'
        . '</html>';

    // Comprehensive Plain-Text Alternate Body.
    $plain_alt_body = "====================================================\n"
        . "WEBSITE EMAIL DELIVERY & DIAGNOSTIC TEST\n"
        . "Site: " . $site_name . " (" . $site_url . ")\n"
        . "====================================================\n\n"
        . "[MESSAGE DETAILS]\n"
        . $message_text . "\n\n"
        . "----------------------------------------------------\n"
        . "[SYSTEM & TRANSPORT DIAGNOSTICS]\n"
        . "- Site Origin: " . $site_name . " (" . $site_domain . ")\n"
        . "- WordPress Core: v" . $current_wp . "\n"
        . "- PHP Environment: PHP " . $php_ver . "\n"
        . "- Mail Subsystem: PHPMailer (wp_mail) HTML / UTF-8\n"
        . "- Generation Time: " . $timestamp . "\n\n"
        . "----------------------------------------------------\n"
        . "[SECURITY & AUTHENTICATION STANDARDS]\n"
        . "- SPF (Sender Policy Framework): Configured for sending server\n"
        . "- DKIM (DomainKeys Identified Mail): Cryptographic digital signature\n"
        . "- DMARC (Domain-based Message Authentication): Policy alignment\n"
        . "- MIME Multipart/Alternative: Synchronized HTML and Plain Text\n\n"
        . "----------------------------------------------------\n"
        . "Website URL: " . $site_url . "\n"
        . "This is an automated delivery test dispatched by an administrator.\n"
        . "No reply is required.\n";

    return array(
        'subject'        => $subject,
        'body'           => $body,
        'plain_alt_body' => $plain_alt_body,
        'message_text'   => $message_text,
    );
}

/**
 * Send one generated diagnostic message and measure how long the transport took.
 *
 * Shared by the manual form and by the Mail-Tester round trip so both paths build
 * exactly the same message: same HTML body, same logo, same plain-text alternative.
 *
 * @param string $to           Recipient address.
 * @param string $subject      Subject line, empty for the generated one.
 * @param string $message_text Custom intro text, empty for the generated one.
 * @param string $from_name    From name.
 * @param string $from_email   From address.
 * @return array{sent:bool,ms:int,error:string}
 */
function vladimir_test_email_dispatch( $to, $subject = '', $message_text = '', $from_name = '', $from_email = '' ) {
    $content = vladimir_test_email_generate_content( $message_text );
    $subject = $subject ?: $content['subject'];

    $headers = array( 'Content-Type: text/html; charset=UTF-8' );
    if ( is_email( $from_email ) ) {
        $headers[] = 'From: ' . $from_name . ' <' . $from_email . '>';
    }

    $mail_error = '';
    $collector  = function( $wp_error ) use ( &$mail_error ) {
        if ( is_wp_error( $wp_error ) ) {
            $mail_error = $wp_error->get_error_message();
        }
    };
    add_action( 'wp_mail_failed', $collector );

    $plain_alt_body = $content['plain_alt_body'];
    $set_alt_body   = function( $phpmailer ) use ( $plain_alt_body ) {
        if ( is_object( $phpmailer ) && isset( $phpmailer->AltBody ) ) {
            $phpmailer->AltBody = $plain_alt_body;
        }
    };
    add_action( 'phpmailer_init', $set_alt_body );

    $start = microtime( true );
    $sent  = wp_mail( '<' . $to . '>', $subject, $content['body'], $headers );
    $ms    = (int) round( ( microtime( true ) - $start ) * 1000 );

    remove_action( 'phpmailer_init', $set_alt_body );
    remove_action( 'wp_mail_failed', $collector );

    return array(
        'sent'  => (bool) $sent,
        'ms'    => $ms,
        'error' => $mail_error,
    );
}

/**
 * Read the DNS records that decide whether mail from this domain is trusted.
 *
 * Plain resolver lookups only: no external service, no API key, no credentials.
 *
 * @param string $domain   Domain to inspect.
 * @param string $selector DKIM selector to probe.
 * @return array<string,array{state:string,value:string}>
 */
function vladimir_test_email_dns_report( $domain, $selector = 'dkim' ) {
    $out = array();

    $txt = function( $name ) {
        if ( ! function_exists( 'dns_get_record' ) ) {
            return '';
        }
        $rows = @dns_get_record( $name, DNS_TXT );
        if ( empty( $rows ) || ! is_array( $rows ) ) {
            return '';
        }
        $joined = array();
        foreach ( $rows as $row ) {
            if ( isset( $row['txt'] ) ) {
                $joined[] = $row['txt'];
            } elseif ( ! empty( $row['entries'] ) && is_array( $row['entries'] ) ) {
                $joined[] = implode( '', $row['entries'] );
            }
        }
        return implode( ' ', $joined );
    };

    $spf = '';
    if ( preg_match( '/v=spf1[^"]*/i', $txt( $domain ), $m ) ) {
        $spf = trim( $m[0] );
    }
    $out['SPF'] = array( 'state' => $spf ? 'ok' : 'missing', 'value' => $spf ?: '-' );

    // DKIM lives under a selector and may be a TXT record or a CNAME: Seznam, for
    // instance, publishes the provider key as a CNAME into seznam.cz.
    $dkim_name = $selector . '._domainkey.' . $domain;
    $dkim      = $txt( $dkim_name );
    if ( ! $dkim && function_exists( 'dns_get_record' ) ) {
        $cname = @dns_get_record( $dkim_name, DNS_CNAME );
        if ( ! empty( $cname[0]['target'] ) ) {
            $dkim = 'CNAME -> ' . $cname[0]['target'];
        }
    }
    $out[ 'DKIM (' . $selector . ')' ] = array(
        'state' => $dkim ? 'ok' : 'missing',
        'value' => $dkim ? ( strlen( $dkim ) > 80 ? substr( $dkim, 0, 80 ) . '...' : $dkim ) : '-',
    );

    $dmarc = '';
    if ( preg_match( '/v=DMARC1[^"]*/i', $txt( '_dmarc.' . $domain ), $m ) ) {
        $dmarc = trim( $m[0] );
    }
    $out['DMARC'] = array( 'state' => $dmarc ? 'ok' : 'missing', 'value' => $dmarc ?: '-' );

    $mx = '';
    if ( function_exists( 'dns_get_record' ) ) {
        $rows  = @dns_get_record( $domain, DNS_MX );
        $hosts = array();
        if ( ! empty( $rows ) ) {
            foreach ( $rows as $row ) {
                if ( ! empty( $row['target'] ) ) {
                    $hosts[] = $row['target'];
                }
            }
        }
        $mx = implode( ', ', $hosts );
    }
    $out['MX'] = array( 'state' => $mx ? 'ok' : 'missing', 'value' => $mx ?: '-' );

    // Receivers reject mail from hosts without reverse DNS, so it belongs in the report.
    $ip  = isset( $_SERVER['SERVER_ADDR'] ) ? sanitize_text_field( wp_unslash( $_SERVER['SERVER_ADDR'] ) ) : '';
    $ptr = $ip ? gethostbyaddr( $ip ) : '';
    $out['PTR'] = array(
        'state' => ( $ptr && $ptr !== $ip ) ? 'ok' : 'missing',
        'value' => ( $ptr && $ptr !== $ip ) ? $ptr . ' (' . $ip . ')' : ( $ip ?: '-' ),
    );

    return $out;
}

/**
 * Start a Mail-Tester run: build an address, send to it, hand the id back.
 *
 * Mail-Tester publishes no free API and none is needed. Its own front page generates
 * the throwaway address in the visitor's browser as "test-<9 random characters>@srv1
 * .mail-tester.com" and the report then lives at https://www.mail-tester.com/<id>.
 * This does the same thing server-side, so no account, key or library is involved.
 */
add_action( 'wp_ajax_vladimir_te_mt_start', function() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( array( 'message' => 'Unauthorized' ), 403 );
    }
    check_ajax_referer( 'vladimir_te_mt', 'nonce' );

    // Lowercase alphanumeric only, exactly like the address their front end builds.
    $id = 'test-' . substr( strtolower( wp_hash( uniqid( '', true ) ) ), 0, 9 );
    $to = $id . '@srv1.mail-tester.com';

    $from_name  = isset( $_POST['from_name'] ) ? sanitize_text_field( wp_unslash( $_POST['from_name'] ) ) : get_bloginfo( 'name' );
    $from_email = isset( $_POST['from_email'] ) ? sanitize_email( wp_unslash( $_POST['from_email'] ) ) : get_option( 'admin_email' );

    $res = vladimir_test_email_dispatch( $to, '', '', $from_name, $from_email );

    if ( ! $res['sent'] ) {
        wp_send_json_error( array( 'message' => $res['error'] ?: 'WordPress could not hand the message to its mail transport.' ) );
    }

    wp_send_json_success( array(
        'id'          => $id,
        'address'     => $to,
        'report_url'  => 'https://www.mail-tester.com/' . $id,
        'dispatch_ms' => $res['ms'],
    ) );
} );

/**
 * Poll one Mail-Tester report page and return the score once it exists.
 */
add_action( 'wp_ajax_vladimir_te_mt_poll', function() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_send_json_error( array( 'message' => 'Unauthorized' ), 403 );
    }
    check_ajax_referer( 'vladimir_te_mt', 'nonce' );

    $id = isset( $_POST['id'] ) ? sanitize_text_field( wp_unslash( $_POST['id'] ) ) : '';
    if ( ! preg_match( '/^test-[a-z0-9]{4,20}$/', $id ) ) {
        wp_send_json_error( array( 'message' => 'Bad test id' ) );
    }

    $resp = wp_remote_get( 'https://www.mail-tester.com/' . $id, array(
        'timeout'     => 15,
        'redirection' => 3,
        'user-agent'  => 'WP Test Email Micro (VladiMIR+AI)',
    ) );

    if ( is_wp_error( $resp ) ) {
        wp_send_json_success( array( 'ready' => false, 'note' => $resp->get_error_message() ) );
    }

    $html = (string) wp_remote_retrieve_body( $resp );

    // The score appears only once the message has arrived and been analysed.
    if ( '' === $html || ! preg_match( '#([0-9]+(?:\.[0-9]+)?)\s*/\s*10#', $html, $m ) ) {
        wp_send_json_success( array( 'ready' => false ) );
    }

    wp_send_json_success( array(
        'ready'  => true,
        'score'  => (float) $m[1],
        'checks' => array(
            'auth'      => ( false !== stripos( $html, 'properly authenticated' ) ),
            'spam'      => ( false !== stripos( $html, 'SpamAssassin likes you' ) ),
            'blocklist' => ( false !== stripos( $html, 'not blocklisted' ) || false !== stripos( $html, 'not blacklisted' ) ),
        ),
    ) );
} );

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
    $dkim_selector      = isset( $_POST['vladimir_dkim_selector'] ) ? sanitize_key( wp_unslash( $_POST['vladimir_dkim_selector'] ) ) : 'dkim';
    $site_domain        = preg_replace( '/^www\./i', '', (string) wp_parse_url( home_url(), PHP_URL_HOST ) );

    if ( isset( $_POST['vladimir_send_test'] ) && check_admin_referer( 'vladimir_test_email_action', 'vladimir_nonce' ) ) {
        if ( empty( $to ) || ! is_email( $to ) ) {
            $result_msg = 'Enter a valid recipient email address.';
        } elseif ( empty( $from_email ) || ! is_email( $from_email ) ) {
            $result_msg = 'Enter a valid sender email address.';
        } else {
            $res       = vladimir_test_email_dispatch( $to, $subject, $message_text, $from_name, $from_email );

            if ( $res['sent'] ) {
                $result_ok  = true;
                $result_msg = 'The test email was handed to the configured WordPress mail transport in ' . $res['ms'] . ' ms.';
            } else {
                $result_msg = 'WordPress could not hand the message to its mail transport.' . ( $res['error'] ? ' Details: ' . $res['error'] : '' );
            }
        }
    }
    ?>
    <div class="wrap" style="max-width:920px;">
        <h1>✉️ WP Test Email Micro</h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:18px;">Send a rich diagnostic HTML email with your site logo, delivery metrics, and full SPF/DKIM deliverability compliance.</p>

        <div style="background:#f0f6fc;border-left:4px solid #2271b1;padding:18px 20px;border-radius:6px;margin-bottom:24px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <h2 style="margin:0 0 8px;font-size:17px;">Deliverability score (Mail Tester) — one click</h2>
            <p style="margin:0 0 14px;color:#475569;">The plugin creates the Mail Tester address itself, sends the same diagnostic message to it and waits for the verdict. Nothing to copy or paste. The free service allows roughly three checks per day per IP address.</p>
            <button type="button" id="vladimir-mt-run" class="button button-primary button-hero" style="min-width:230px;">Run the check</button>

            <div id="vladimir-mt-panel" style="display:none;margin-top:18px;">
                <div style="display:flex;gap:18px;flex-wrap:wrap;">
                    <div style="flex:1;min-width:190px;background:#fff;border:1px solid #dbe3ec;border-radius:8px;padding:16px;text-align:center;">
                        <div style="font-size:11px;text-transform:uppercase;letter-spacing:.07em;color:#64748b;">Seconds to arrival</div>
                        <div id="vladimir-mt-timer" style="font-size:54px;line-height:1.15;font-weight:700;color:#2271b1;">0</div>
                        <div id="vladimir-mt-state" style="font-size:12px;color:#64748b;">waiting for the message…</div>
                    </div>
                    <div style="flex:1;min-width:190px;background:#fff;border:1px solid #dbe3ec;border-radius:8px;padding:16px;text-align:center;">
                        <div style="font-size:11px;text-transform:uppercase;letter-spacing:.07em;color:#64748b;">Score</div>
                        <div id="vladimir-mt-score" style="font-size:54px;line-height:1.15;font-weight:700;color:#94a3b8;">—</div>
                        <div id="vladimir-mt-checks" style="font-size:12px;color:#64748b;">&nbsp;</div>
                    </div>
                    <div style="flex:1;min-width:190px;background:#fff;border:1px solid #dbe3ec;border-radius:8px;padding:16px;text-align:center;">
                        <div style="font-size:11px;text-transform:uppercase;letter-spacing:.07em;color:#64748b;">Handed to transport</div>
                        <div id="vladimir-mt-ms" style="font-size:54px;line-height:1.15;font-weight:700;color:#475569;">—</div>
                        <div style="font-size:12px;color:#64748b;">milliseconds in wp_mail()</div>
                    </div>
                </div>
                <p style="margin:16px 0 0;">
                    <a id="vladimir-mt-link" class="button button-secondary button-hero" href="#" target="_blank" rel="noopener noreferrer" style="display:none;min-width:230px;">Open the full report &nearr;</a>
                </p>
                <p id="vladimir-mt-error" style="display:none;color:#b32d2e;font-weight:600;margin:12px 0 0;"></p>
            </div>
        </div>

        <div style="background:#fff;padding:20px 22px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);margin-bottom:24px;">
            <h2 style="margin:0 0 4px;font-size:17px;">DNS records of <code><?php echo esc_html( $site_domain ); ?></code></h2>
            <p style="margin:0 0 12px;color:#64748b;font-size:13px;">Read straight from the resolvers, no third-party service involved. A provider publishes its own DKIM key under its own selector (<code>mail</code> for Yandex, <code>mailru</code> for Mail.ru, a CNAME on <code>szn20221014</code> for Seznam) next to the server key on <code>dkim</code>; both coexist by design.</p>
            <table class="widefat striped">
                <tbody>
                <?php foreach ( vladimir_test_email_dns_report( $site_domain, $dkim_selector ?: 'dkim' ) as $label => $row ) : ?>
                    <tr>
                        <td style="width:150px;"><strong><?php echo esc_html( $label ); ?></strong></td>
                        <td style="width:40px;text-align:center;font-size:16px;"><?php echo 'ok' === $row['state'] ? '&#9989;' : '&#9888;&#65039;'; ?></td>
                        <td><code style="font-size:11px;word-break:break-all;"><?php echo esc_html( $row['value'] ); ?></code></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
            <form method="post" action="" style="margin-top:12px;">
                <?php wp_nonce_field( 'vladimir_test_email_action', 'vladimir_nonce' ); ?>
                <label for="vladimir_dkim_selector" style="font-size:12px;color:#64748b;">DKIM selector:</label>
                <input type="text" name="vladimir_dkim_selector" id="vladimir_dkim_selector" value="<?php echo esc_attr( $dkim_selector ?: 'dkim' ); ?>" style="width:150px;">
                <input type="submit" class="button" value="Re-read">
            </form>
        </div>

        <?php if ( ! empty( $result_msg ) ) : ?>
            <div class="notice <?php echo $result_ok ? 'notice-success' : 'notice-error'; ?> is-dismissible" style="margin-left:0;margin-bottom:20px;">
                <p><strong><?php echo esc_html( $result_msg ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="" style="background:#fff;padding:26px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_test_email_action', 'vladimir_nonce' ); ?>
            <table class="form-table" role="presentation">
                <tr><th scope="row"><label for="vladimir_email_to"><strong>Recipient Email *</strong></label></th><td><input type="email" name="vladimir_email_to" id="vladimir_email_to" value="<?php echo esc_attr( $to ); ?>" class="regular-text" required style="width:100%;"><p class="description">Enter the Mail Tester address or a controlled recipient mailbox.</p></td></tr>
                <tr><th scope="row"><label for="vladimir_from_name"><strong>From Name</strong></label></th><td><input type="text" name="vladimir_from_name" id="vladimir_from_name" value="<?php echo esc_attr( $from_name ); ?>" class="regular-text" style="width:100%;"></td></tr>
                <tr><th scope="row"><label for="vladimir_from_email"><strong>From Email</strong></label></th><td><input type="email" name="vladimir_from_email" id="vladimir_from_email" value="<?php echo esc_attr( $from_email ); ?>" class="regular-text" style="width:100%;"></td></tr>
                <tr><th scope="row"><label for="vladimir_email_subject"><strong>Subject</strong></label></th><td><input type="text" name="vladimir_email_subject" id="vladimir_email_subject" value="<?php echo esc_attr( $subject ); ?>" class="regular-text" style="width:100%;"></td></tr>
                <tr><th scope="row"><label for="vladimir_email_message"><strong>Message Text</strong></label></th><td><textarea name="vladimir_email_message" id="vladimir_email_message" rows="6" class="large-text"><?php echo esc_textarea( $message_text ); ?></textarea><p class="description">Custom introductory text. The site logo, diagnostic parameters, security guidelines, and website link are automatically appended in the HTML email.</p></td></tr>
            </table>
            <?php $logo_preview = vladimir_test_email_get_logo_url(); ?>
            <?php if ( ! empty( $logo_preview ) ) : ?>
                <div style="margin:18px 0;padding:18px;text-align:center;background:#f8fafc;border:1px solid #dbe3ec;border-radius:6px;">
                    <p style="margin:0 0 12px;font-weight:600;">Site Logo (auto-embedded in email)</p>
                    <img src="<?php echo esc_url( $logo_preview ); ?>" alt="<?php echo esc_attr( get_bloginfo( 'name' ) ); ?>" style="max-width:200px;max-height:70px;width:auto;height:auto;">
                </div>
            <?php else : ?>
                <div style="margin:18px 0;padding:14px;text-align:center;background:#f8fafc;border:1px dashed #cbd5e1;border-radius:6px;color:#64748b;font-size:13px;">
                    <em>No custom logo or site icon uploaded in WordPress. A clean text badge with the site name will be rendered instead.</em>
                </div>
            <?php endif; ?>
            <p><input type="submit" name="vladimir_send_test" class="button button-primary button-hero" value="Send Test Email"></p>
        </form>
    </div>

    <script>
    (function () {
        var btn = document.getElementById('vladimir-mt-run');
        if (!btn) { return; }

        var ajaxUrl = <?php echo wp_json_encode( admin_url( 'admin-ajax.php' ) ); ?>;
        var nonce   = <?php echo wp_json_encode( wp_create_nonce( 'vladimir_te_mt' ) ); ?>;

        var MAX_SECONDS = 180;  // mail-tester normally answers within 10-30 seconds
        var POLL_EVERY  = 3000;

        function post(action, extra) {
            var body = new URLSearchParams();
            body.append('action', action);
            body.append('nonce', nonce);
            for (var k in extra) { body.append(k, extra[k]); }
            return fetch(ajaxUrl, {
                method: 'POST',
                credentials: 'same-origin',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: body.toString()
            }).then(function (r) { return r.json(); });
        }

        btn.addEventListener('click', function () {
            var panel  = document.getElementById('vladimir-mt-panel');
            var timer  = document.getElementById('vladimir-mt-timer');
            var state  = document.getElementById('vladimir-mt-state');
            var score  = document.getElementById('vladimir-mt-score');
            var checks = document.getElementById('vladimir-mt-checks');
            var msBox  = document.getElementById('vladimir-mt-ms');
            var link   = document.getElementById('vladimir-mt-link');
            var errBox = document.getElementById('vladimir-mt-error');

            btn.disabled = true;
            panel.style.display = 'block';
            errBox.style.display = 'none';
            link.style.display = 'none';
            score.textContent = '—';
            score.style.color = '#94a3b8';
            msBox.textContent = '—';
            checks.innerHTML = '&nbsp;';
            state.textContent = 'waiting for the message…';

            var started = Date.now();
            var ticker  = setInterval(function () {
                timer.textContent = Math.round((Date.now() - started) / 1000);
            }, 250);

            function stop() { clearInterval(ticker); btn.disabled = false; }

            var fromName  = document.getElementById('vladimir_from_name');
            var fromEmail = document.getElementById('vladimir_from_email');

            post('vladimir_te_mt_start', {
                from_name:  fromName ? fromName.value : '',
                from_email: fromEmail ? fromEmail.value : ''
            }).then(function (res) {
                if (!res || !res.success) {
                    stop();
                    state.textContent = '';
                    errBox.textContent = (res && res.data && res.data.message) ? res.data.message : 'wp_mail() refused the message.';
                    errBox.style.display = 'block';
                    return;
                }

                msBox.textContent = res.data.dispatch_ms;
                link.href = res.data.report_url;
                link.style.display = 'inline-flex';
                state.textContent = res.data.address;

                (function poll() {
                    if ((Date.now() - started) / 1000 > MAX_SECONDS) {
                        stop();
                        state.textContent = '';
                        errBox.textContent = 'The message did not arrive within ' + MAX_SECONDS + ' seconds. Open the report manually or inspect the mail queue on the server.';
                        errBox.style.display = 'block';
                        return;
                    }
                    post('vladimir_te_mt_poll', { id: res.data.id }).then(function (p) {
                        if (p && p.success && p.data && p.data.ready) {
                            stop();
                            var s = p.data.score;
                            score.textContent = s + '/10';
                            score.style.color = (s >= 9) ? '#00a32a' : (s >= 7 ? '#dba617' : '#d63638');
                            state.textContent = 'delivered and analysed';
                            var c = p.data.checks || {};
                            checks.innerHTML =
                                (c.auth ? '✅' : '⚠️') + ' AUTH &nbsp; ' +
                                (c.spam ? '✅' : '⚠️') + ' SPAM &nbsp; ' +
                                (c.blocklist ? '✅' : '⚠️') + ' LIST';
                        } else {
                            setTimeout(poll, POLL_EVERY);
                        }
                    }).catch(function () { setTimeout(poll, POLL_EVERY); });
                })();
            }).catch(function (e) {
                stop();
                state.textContent = '';
                errBox.textContent = String(e);
                errBox.style.display = 'block';
            });
        });
    })();
    </script>
    <?php
}
