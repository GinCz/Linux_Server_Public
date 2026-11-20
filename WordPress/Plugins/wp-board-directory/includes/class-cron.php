<?php
/**
 * Expiration Watchdog & Automated Email Reminders
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class VB_Cron {

    public static function init() {
        if ( ! wp_next_scheduled( 'vb_board_daily_expiration_check' ) ) {
            wp_schedule_event( time(), 'daily', 'vb_board_daily_expiration_check' );
        }

        add_action( 'vb_board_daily_expiration_check', [ __CLASS__, 'process_expirations' ] );
        add_action( 'init', [ __CLASS__, 'handle_direct_renew_link' ] );
        add_action( 'wp_footer', [ __CLASS__, 'render_renew_success_modal' ] );
    }

    /**
     * Generate secure 1-click renewal URL without requiring login.
     */
    public static function get_renew_url( $post_id ) {
        $post = get_post( $post_id );
        if ( ! $post ) {
            return home_url( '/' );
        }
        $token = wp_hash( $post_id . '|' . $post->post_date . '|vb_renew_secure' );
        return add_query_arg( [
            'vb_action' => 'renew_ad',
            'lid'       => $post_id,
            'token'     => $token,
        ], home_url( '/' ) );
    }

    /**
     * Handle 1-click renewal from email link.
     */
    public static function handle_direct_renew_link() {
        if ( isset( $_GET['vb_action'] ) && 'renew_ad' === $_GET['vb_action'] ) {
            $lid   = absint( $_GET['lid'] ?? 0 );
            $token = sanitize_text_field( $_GET['token'] ?? '' );

            if ( ! $lid || empty( $token ) ) {
                wp_die( 'Неверная ссылка продления объявления.' );
            }

            $post = get_post( $lid );
            if ( ! $post || ! in_array( $post->post_type, [ 'vb_listing', 'vb_company' ], true ) ) {
                wp_die( 'Объявление не найдено.' );
            }

            $expected_token = wp_hash( $lid . '|' . $post->post_date . '|vb_renew_secure' );
            if ( ! hash_equals( $expected_token, $token ) ) {
                wp_die( 'Ошибка безопасности (недействительный токен ссылки).' );
            }

            // Extend publication by 6 months from now
            $new_expiry = date( 'Y-m-d 23:59:59', strtotime( '+6 months', current_time( 'timestamp' ) ) );
            update_post_meta( $lid, 'expiry_date', $new_expiry );
            update_post_meta( $lid, '_expiry_date', $new_expiry );
            update_post_meta( $lid, '_vb_expiry_date', $new_expiry );
            delete_post_meta( $lid, 'never_expires' );
            delete_post_meta( $lid, '_never_expires' );
            delete_post_meta( $lid, '_vb_never_expires' );

            // Reset reminder flags
            delete_post_meta( $lid, '_vb_reminded_14d' );
            delete_post_meta( $lid, '_vb_reminded_7d' );
            delete_post_meta( $lid, '_vb_expired_notified' );

            // Restore published status if it was expired or pending
            if ( in_array( $post->post_status, [ 'expired', 'draft', 'pending' ], true ) ) {
                wp_update_post( [
                    'ID'          => $lid,
                    'post_status' => 'publish',
                ] );
            }

            // Redirect to post with success flag
            $permalink = get_permalink( $lid );
            wp_safe_redirect( add_query_arg( [ 'vb_renewed' => '1' ], $permalink ) );
            exit;
        }
    }

    /**
     * Display a success notice banner when renewed.
     */
    public static function render_renew_success_modal() {
        if ( isset( $_GET['vb_renewed'] ) && '1' === $_GET['vb_renewed'] ) {
            ?>
            <div id="vb-renew-banner" style="position:fixed;bottom:24px;right:24px;z-index:999999;background:#059669;color:#fff;padding:16px 24px;border-radius:8px;box-shadow:0 10px 25px rgba(0,0,0,0.2);display:flex;align-items:center;gap:12px;font-family:inherit;font-size:15px;font-weight:600;">
                <span>✅ Публикация объявления успешно продлена на 6 месяцев!</span>
                <button type="button" onclick="this.parentElement.remove()" style="background:transparent;border:none;color:#fff;font-size:20px;cursor:pointer;line-height:1;">&times;</button>
            </div>
            <?php
        }
    }

    /**
     * Daily Watchdog: send 14-day & 7-day reminders, expire overdue listings.
     */
    public static function process_expirations() {
        $now = current_time( 'timestamp' );
        $site_name = get_bloginfo( 'name' );

        $listings = get_posts( [
            'post_type'      => [ 'vb_listing', 'vb_company' ],
            'post_status'    => [ 'publish' ],
            'posts_per_page' => -1,
            'fields'         => 'ids',
        ] );

        foreach ( $listings as $lid ) {
            // Check if post belongs to Vladimir or is set to never expire
            $post = get_post( $lid );
            $author_id = (int) $post->post_author;
            $email = get_post_meta( $lid, '_vb_email', true ) ?: get_post_meta( $lid, 'email', true );
            $is_vladimir = ( 1 === $author_id || strtolower( trim( $email ) ) === 'gin@volny.cz' || strtolower( trim( $email ) ) === 'gin.vladimir@gmail.com' );
            $never_expires = get_post_meta( $lid, 'never_expires', true ) ?: get_post_meta( $lid, '_never_expires', true );

            if ( $is_vladimir || $never_expires ) {
                continue; // Never expires, no reminders sent
            }

            $expiry = get_post_meta( $lid, 'expiry_date', true ) ?: get_post_meta( $lid, '_expiry_date', true ) ?: get_post_meta( $lid, '_vb_expiry_date', true );
            if ( ! $expiry ) {
                continue;
            }

            $exp_ts = strtotime( $expiry );
            if ( ! $exp_ts ) {
                continue;
            }

            $days_left = floor( ( $exp_ts - $now ) / DAY_IN_SECONDS );
            $renew_url = self::get_renew_url( $lid );
            $title = esc_html( $post->post_title );
            $exp_date_str = date( 'd.m.Y', $exp_ts );

            // Determine recipient email
            $recipient = $email;
            if ( empty( $recipient ) && $author_id > 1 ) {
                $user = get_userdata( $author_id );
                if ( $user && ! empty( $user->user_email ) ) {
                    $recipient = $user->user_email;
                }
            }

            if ( empty( $recipient ) || ! is_email( $recipient ) ) {
                // If overdue and no recipient, simply expire
                if ( $days_left < 0 ) {
                    wp_update_post( [ 'ID' => $lid, 'post_status' => 'expired' ] );
                }
                continue;
            }

            $headers = [ 'Content-Type: text/html; charset=UTF-8' ];

            // 1. Reminder: 14 Days Left
            if ( $days_left <= 14 && $days_left > 7 ) {
                if ( ! get_post_meta( $lid, '_vb_reminded_14d', true ) ) {
                    $subject = "[{$site_name}] Срок публикации объявления истекает через 14 дней";
                    $msg = "<p>Здравствуйте!</p>"
                         . "<p>Срок публикации вашего объявления <strong>«{$title}»</strong> на сайте {$site_name} истекает через 14 дней ({$exp_date_str}).</p>"
                         . "<p>Вы можете <strong>бесплатно продлить</strong> его публикацию еще на 6 месяцев в один клик:</p>"
                         . "<p><a href='{$renew_url}' style='background:#059669;color:#fff;padding:10px 18px;text-decoration:none;border-radius:4px;display:inline-block;font-weight:bold;'>Продлить публикацию бесплатно</a></p>"
                         . "<p style='color:#64748b;font-size:12px;'>Или перейдите по прямой ссылке: <a href='{$renew_url}'>{$renew_url}</a></p>"
                         . "<p>С уважением,<br>Администрация {$site_name}</p>";

                    wp_mail( $recipient, $subject, $msg, $headers );
                    update_post_meta( $lid, '_vb_reminded_14d', date( 'Y-m-d H:i:s' ) );
                }
            }

            // 2. Reminder: 7 Days Left
            if ( $days_left <= 7 && $days_left >= 0 ) {
                if ( ! get_post_meta( $lid, '_vb_reminded_7d', true ) ) {
                    $subject = "[{$site_name}] Внимание: срок публикации объявления истекает через 7 дней!";
                    $msg = "<p>Здравствуйте!</p>"
                         . "<p>Напоминаем, что срок публикации вашего объявления <strong>«{$title}»</strong> на сайте {$site_name} истекает через 7 дней ({$exp_date_str}).</p>"
                         . "<p>Если ваше объявление еще актуально, пожалуйста, продлите его <strong>бесплатно</strong> на 6 месяцев:</p>"
                         . "<p><a href='{$renew_url}' style='background:#059669;color:#fff;padding:10px 18px;text-decoration:none;border-radius:4px;display:inline-block;font-weight:bold;'>Продлить публикацию бесплатно</a></p>"
                         . "<p style='color:#64748b;font-size:12px;'>После окончания срока объявление будет автоматически снято с публикации.</p>"
                         . "<p>С уважением,<br>Администрация {$site_name}</p>";

                    wp_mail( $recipient, $subject, $msg, $headers );
                    update_post_meta( $lid, '_vb_reminded_7d', date( 'Y-m-d H:i:s' ) );
                }
            }

            // 3. Expired (< 0 days)
            if ( $days_left < 0 ) {
                wp_update_post( [ 'ID' => $lid, 'post_status' => 'expired' ] );

                if ( ! get_post_meta( $lid, '_vb_expired_notified', true ) ) {
                    $subject = "[{$site_name}] Срок публикации объявления «{$title}» истек";
                    $msg = "<p>Здравствуйте!</p>"
                         . "<p>Срок публикации вашего объявления <strong>«{$title}»</strong> на сайте {$site_name} подошел к концу, и оно было снято с публикации.</p>"
                         . "<p>Вы можете восстановить его и бесплатно продлить на 6 месяцев в любое удобное время:</p>"
                         . "<p><a href='{$renew_url}' style='background:#059669;color:#fff;padding:10px 18px;text-decoration:none;border-radius:4px;display:inline-block;font-weight:bold;'>Восстановить и продлить бесплатно</a></p>"
                         . "<p>С уважением,<br>Администрация {$site_name}</p>";

                    wp_mail( $recipient, $subject, $msg, $headers );
                    update_post_meta( $lid, '_vb_expired_notified', date( 'Y-m-d H:i:s' ) );
                }
            }
        }
    }
}
