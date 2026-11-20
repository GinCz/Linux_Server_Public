<?php
/**
 * Rating, Reviews & Anti-Fraud Vote Engine (Likes & Dislikes)
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class VB_Ratings {

    public static function init() {
        add_action( 'wp_ajax_vb_submit_vote', [ __CLASS__, 'ajax_submit_vote' ] );
        add_action( 'wp_ajax_nopriv_vb_submit_vote', [ __CLASS__, 'ajax_must_login' ] );
    }

    /**
     * Unauthenticated user rejection
     */
    public static function ajax_must_login() {
        wp_send_json_error( [
            'message' => 'Ставить лайки и дизлайки могут только зарегистрированные пользователи. Пожалуйста, войдите в свой аккаунт.',
            'code'    => 'auth_required',
        ] );
    }

    /**
     * Handle AJAX Vote (Like = 1, Dislike = -1)
     */
    public static function ajax_submit_vote() {
        check_ajax_referer( 'vb_board_nonce', 'nonce' );

        if ( ! is_user_logged_in() ) {
            self::ajax_must_login();
        }

        $user_id     = get_current_user_id();
        $target_type = sanitize_key( $_POST['target_type'] ?? 'listing' ); // 'listing' or 'company' or 'author'
        $target_id   = absint( $_POST['target_id'] ?? 0 );
        $vote_val    = intval( $_POST['rating'] ?? 0 ); // 1 for Like, -1 for Dislike
        $ip_address  = self::get_client_ip();

        if ( ! in_array( $vote_val, [ 1, -1 ], true ) || ! $target_id ) {
            wp_send_json_error( [ 'message' => 'Некорректные параметры голосования.' ] );
        }

        // 1. Prevent Self-Voting
        $post = get_post( $target_id );
        if ( $post ) {
            if ( (int) $post->post_author === $user_id ) {
                wp_send_json_error( [ 'message' => 'Вы не можете оценивать собственное объявление или компанию!' ] );
            }
        }

        global $wpdb;
        $table = $wpdb->prefix . 'vb_ratings';

        // 2. Check existing vote
        $existing = $wpdb->get_row( $wpdb->prepare(
            "SELECT id, rating FROM {$table} WHERE target_type = %s AND target_id = %d AND user_id = %d",
            $target_type,
            $target_id,
            $user_id
        ) );

        if ( $existing ) {
            if ( (int) $existing->rating === $vote_val ) {
                wp_send_json_error( [ 'message' => 'Вы уже поставили эту оценку ранее.' ] );
            } else {
                // Change vote from like to dislike or vice versa
                $wpdb->update(
                    $table,
                    [
                        'rating'     => $vote_val,
                        'ip_address' => $ip_address,
                        'created_at' => current_time( 'mysql' ),
                    ],
                    [ 'id' => $existing->id ],
                    [ '%d', '%s', '%s' ],
                    [ '%d' ]
                );
            }
        } else {
            // Anti-flood: max 15 votes per hour per IP/user
            $hour_ago = date( 'Y-m-d H:i:s', time() - 3600 );
            $recent_votes = $wpdb->get_var( $wpdb->prepare(
                "SELECT count(*) FROM {$table} WHERE (user_id = %d OR ip_address = %s) AND created_at > %s",
                $user_id,
                $ip_address,
                $hour_ago
            ) );

            if ( $recent_votes >= 15 ) {
                wp_send_json_error( [ 'message' => 'Слишком много оценок за короткий период. Пожалуйста, подождите немного.' ] );
            }

            // Insert new vote
            $wpdb->insert(
                $table,
                [
                    'target_type'    => $target_type,
                    'target_id'      => $target_id,
                    'user_id'        => $user_id,
                    'rating'         => $vote_val,
                    'review_content' => '',
                    'ip_address'     => $ip_address,
                    'status'         => 'approved',
                    'created_at'     => current_time( 'mysql' ),
                ],
                [ '%s', '%d', '%d', '%d', '%s', '%s', '%s', '%s' ]
            );
        }

        // 3. Recalculate Likes & Dislikes
        $stats = self::get_vote_stats( $target_type, $target_id );

        wp_send_json_success( [
            'message'  => $vote_val === 1 ? 'Вы поставили лайк 👍' : 'Вы поставили дизлайк 👎',
            'likes'    => $stats['likes'],
            'dislikes' => $stats['dislikes'],
        ] );
    }

    /**
     * Get Likes and Dislikes count for an item
     */
    public static function get_vote_stats( $target_type, $target_id ) {
        global $wpdb;
        $table = $wpdb->prefix . 'vb_ratings';

        $likes = (int) $wpdb->get_var( $wpdb->prepare(
            "SELECT count(*) FROM {$table} WHERE target_type = %s AND target_id = %d AND rating = 1 AND status = 'approved'",
            $target_type,
            $target_id
        ) );

        $dislikes = (int) $wpdb->get_var( $wpdb->prepare(
            "SELECT count(*) FROM {$table} WHERE target_type = %s AND target_id = %d AND rating = -1 AND status = 'approved'",
            $target_type,
            $target_id
        ) );

        // Update post meta cache
        if ( in_array( $target_type, [ 'listing', 'company' ], true ) ) {
            update_post_meta( $target_id, '_vb_likes', $likes );
            update_post_meta( $target_id, '_vb_dislikes', $dislikes );
        }

        return [
            'likes'    => $likes,
            'dislikes' => $dislikes,
        ];
    }

    /**
     * Get real client IP behind Cloudflare
     */
    public static function get_client_ip() {
        if ( ! empty( $_SERVER['HTTP_CF_CONNECTING_IP'] ) ) {
            return sanitize_text_field( $_SERVER['HTTP_CF_CONNECTING_IP'] );
        }
        if ( ! empty( $_SERVER['HTTP_X_FORWARDED_FOR'] ) ) {
            $parts = explode( ',', $_SERVER['HTTP_X_FORWARDED_FOR'] );
            return trim( sanitize_text_field( $parts[0] ) );
        }
        return sanitize_text_field( $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1' );
    }
}
