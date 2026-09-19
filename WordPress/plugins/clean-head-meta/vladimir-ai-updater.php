<?php
/**
 * VladiMIR+AI Suite - shared auto-update client (private GitHub repository).
 *
 * Master copy: WordPress/_shared/vladimir-ai-updater.php
 * A byte-identical copy ships inside every plugin folder and is pulled in with
 * require_once. The first plugin loaded wins, the rest short-circuit, so the
 * runtime cost is one manifest request per site every 6 hours - not one per plugin.
 *
 * Wiring:
 *   - every plugin header carries "Update URI: https://vladimir-ai.updates/<slug>"
 *   - WordPress therefore dispatches its update check to update_plugins_vladimir-ai.updates
 *   - this client answers that filter from WordPress/updates.json in the private repo
 *   - the ZIP asset is downloaded from the GitHub API with the same token
 *
 * The token never lives in this repository. Each site defines it in wp-config.php:
 *   define( 'VLADIMIR_AI_GH_TOKEN', 'github_pat_...' );   // fine-grained, Contents: read-only
 *
 * @package VladiMIR_AI_Suite
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( defined( 'VLADIMIR_AI_UPDATER_LOADED' ) ) {
    return;
}
define( 'VLADIMIR_AI_UPDATER_LOADED', '2026-09__1.18' );

// Virtual host used only as a routing key for the WordPress update_plugins_{$host} filter.
// No HTTP request is ever made to it.
define( 'VLADIMIR_AI_UPDATE_HOST', 'vladimir-ai.updates' );
define( 'VLADIMIR_AI_UPDATE_REPO', 'GinCz/Secret_Privat' );
define( 'VLADIMIR_AI_UPDATE_BRANCH', 'main' );
define( 'VLADIMIR_AI_UPDATE_MANIFEST', 'WordPress/updates.json' );
define( 'VLADIMIR_AI_UPDATE_TTL', 6 * HOUR_IN_SECONDS );
define( 'VLADIMIR_AI_UPDATE_TTL_FAIL', 15 * MINUTE_IN_SECONDS );

/**
 * Read-only GitHub token. Constant first, single stored option as a fallback.
 *
 * @return string Empty string when the site is not wired for updates.
 */
function vladimir_ai_update_token() {
    if ( defined( 'VLADIMIR_AI_GH_TOKEN' ) && is_string( VLADIMIR_AI_GH_TOKEN ) ) {
        return trim( VLADIMIR_AI_GH_TOKEN );
    }

    $stored = get_site_option( '_vladimir_ai_gh_token', '' );

    return is_string( $stored ) ? trim( $stored ) : '';
}

/**
 * Standard headers for every GitHub API call made by the suite.
 *
 * @param string $accept Accept header value.
 * @return array<string,string>
 */
function vladimir_ai_update_headers( $accept = 'application/vnd.github.raw' ) {
    return array(
        'Authorization'        => 'Bearer ' . vladimir_ai_update_token(),
        'Accept'               => $accept,
        'X-GitHub-Api-Version' => '2022-11-28',
        'User-Agent'           => 'VladiMIR-AI-Suite-Updater',
    );
}

/**
 * Fetch and cache WordPress/updates.json from the private repository.
 *
 * Failures are cached too (short TTL) so a broken token or a GitHub outage cannot
 * turn every admin page load into a blocking HTTP request.
 *
 * @param bool $force Bypass the cache.
 * @return array<string,mixed> Manifest array, empty on any failure.
 */
function vladimir_ai_update_manifest( $force = false ) {
    static $runtime = null;

    if ( ! $force && is_array( $runtime ) ) {
        return $runtime;
    }

    if ( ! $force ) {
        $cached = get_site_transient( '_vladimir_ai_manifest' );
        if ( is_array( $cached ) ) {
            $runtime = $cached;
            return $runtime;
        }
    }

    $token = vladimir_ai_update_token();
    if ( '' === $token ) {
        $runtime = array();
        return $runtime;
    }

    $url = sprintf(
        'https://api.github.com/repos/%s/contents/%s?ref=%s',
        VLADIMIR_AI_UPDATE_REPO,
        VLADIMIR_AI_UPDATE_MANIFEST,
        VLADIMIR_AI_UPDATE_BRANCH
    );

    $response = wp_remote_get(
        $url,
        array(
            'timeout'     => 12,
            'redirection' => 3,
            'headers'     => vladimir_ai_update_headers(),
        )
    );

    if ( is_wp_error( $response ) || 200 !== (int) wp_remote_retrieve_response_code( $response ) ) {
        $reason = is_wp_error( $response )
            ? $response->get_error_message()
            : 'HTTP ' . wp_remote_retrieve_response_code( $response );

        update_site_option( '_vladimir_ai_update_last_error', $reason );
        set_site_transient( '_vladimir_ai_manifest', array(), VLADIMIR_AI_UPDATE_TTL_FAIL );

        $runtime = array();
        return $runtime;
    }

    $manifest = json_decode( wp_remote_retrieve_body( $response ), true );
    if ( ! is_array( $manifest ) || empty( $manifest['plugins'] ) || ! is_array( $manifest['plugins'] ) ) {
        update_site_option( '_vladimir_ai_update_last_error', 'Malformed updates.json' );
        set_site_transient( '_vladimir_ai_manifest', array(), VLADIMIR_AI_UPDATE_TTL_FAIL );

        $runtime = array();
        return $runtime;
    }

    delete_site_option( '_vladimir_ai_update_last_error' );
    set_site_transient( '_vladimir_ai_manifest', $manifest, VLADIMIR_AI_UPDATE_TTL );

    $runtime = $manifest;
    return $runtime;
}

/**
 * Answer the core update check for every plugin whose Update URI points at our host.
 *
 * @param array|false $update      Existing update payload from another handler.
 * @param array       $plugin_data Plugin headers.
 * @param string      $plugin_file Plugin file relative to the plugins directory.
 * @return array|false
 */
function vladimir_ai_update_check( $update, $plugin_data, $plugin_file ) {
    if ( ! empty( $update ) ) {
        return $update;
    }

    $slug     = dirname( $plugin_file );
    $manifest = vladimir_ai_update_manifest();

    if ( '.' === $slug || empty( $manifest['plugins'][ $slug ] ) ) {
        return $update;
    }

    $entry = $manifest['plugins'][ $slug ];
    if ( empty( $entry['version'] ) || empty( $entry['package'] ) ) {
        return $update;
    }

    $installed = isset( $plugin_data['Version'] ) ? (string) $plugin_data['Version'] : '0';
    if ( ! version_compare( (string) $entry['version'], $installed, '>' ) ) {
        return $update;
    }

    return array(
        'id'           => VLADIMIR_AI_UPDATE_HOST . '/' . $slug,
        'slug'         => $slug,
        'plugin'       => $plugin_file,
        'version'      => (string) $entry['version'],
        'new_version'  => (string) $entry['version'],
        'url'          => isset( $entry['url'] ) ? (string) $entry['url'] : 'https://github.com/' . VLADIMIR_AI_UPDATE_REPO,
        'package'      => (string) $entry['package'],
        'tested'       => isset( $entry['tested'] ) ? (string) $entry['tested'] : '',
        'requires'     => isset( $entry['requires'] ) ? (string) $entry['requires'] : '',
        'requires_php' => isset( $entry['requires_php'] ) ? (string) $entry['requires_php'] : '',
    );
}
add_filter( 'update_plugins_' . VLADIMIR_AI_UPDATE_HOST, 'vladimir_ai_update_check', 10, 3 );

/**
 * Authorise the ZIP download. Release assets are private, so the upgrader needs the
 * same bearer token plus the octet-stream Accept header to get the binary instead of JSON.
 *
 * @param array  $args HTTP args.
 * @param string $url  Target URL.
 * @return array
 */
function vladimir_ai_update_authorize_download( $args, $url ) {
    if ( 0 !== strpos( (string) $url, 'https://api.github.com/repos/' . VLADIMIR_AI_UPDATE_REPO . '/' ) ) {
        return $args;
    }

    $token = vladimir_ai_update_token();
    if ( '' === $token ) {
        return $args;
    }

    $is_asset = ( false !== strpos( $url, '/releases/assets/' ) ) || ( false !== strpos( $url, '/zipball/' ) );

    $args['headers'] = array_merge(
        isset( $args['headers'] ) && is_array( $args['headers'] ) ? $args['headers'] : array(),
        vladimir_ai_update_headers( $is_asset ? 'application/octet-stream' : 'application/vnd.github.raw' )
    );

    return $args;
}
add_filter( 'http_request_args', 'vladimir_ai_update_authorize_download', 10, 2 );

/**
 * Drop the manifest cache whenever an admin asks WordPress to re-check for updates,
 * so "Check again" is never answered from a stale 6-hour cache.
 */
function vladimir_ai_update_flush_cache() {
    delete_site_transient( '_vladimir_ai_manifest' );
}
add_action( 'upgrader_process_complete', 'vladimir_ai_update_flush_cache' );
add_action( 'load-update-core.php', 'vladimir_ai_update_flush_cache' );

/**
 * Surface a misconfiguration (missing token, unreachable manifest) on the plugins screen
 * instead of failing silently - a silent updater is worse than no updater.
 */
function vladimir_ai_update_admin_notice() {
    $screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
    if ( ! $screen || ! in_array( $screen->id, array( 'plugins', 'plugins-network' ), true ) ) {
        return;
    }

    if ( ! current_user_can( 'update_plugins' ) ) {
        return;
    }

    if ( '' === vladimir_ai_update_token() ) {
        echo '<div class="notice notice-warning"><p><strong>VladiMIR+AI Suite:</strong> auto-updates are idle - '
            . 'add <code>define( \'VLADIMIR_AI_GH_TOKEN\', \'github_pat_...\' );</code> to wp-config.php.</p></div>';
        return;
    }

    $error = get_site_option( '_vladimir_ai_update_last_error', '' );
    if ( ! empty( $error ) ) {
        echo '<div class="notice notice-error"><p><strong>VladiMIR+AI Suite:</strong> update manifest unreachable ('
            . esc_html( (string) $error ) . ').</p></div>';
    }
}
add_action( 'admin_notices', 'vladimir_ai_update_admin_notice' );
