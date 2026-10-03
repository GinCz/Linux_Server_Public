<?php
/**
 * VladiMIR+AI Suite - shared auto-update client (public GitHub repository).
 *
 * Master copy: _shared/vladimir-ai-updater.php
 * A byte-identical copy ships inside every plugin folder and is pulled in with
 * require_once. The first plugin loaded wins, the rest short-circuit, so a site
 * makes one manifest request every 6 hours no matter how many suite plugins it runs.
 *
 * Wiring:
 *   - every plugin header carries "Update URI: https://vladimir-ai.updates/<slug>"
 *   - WordPress dispatches its update check to update_plugins_vladimir-ai.updates
 *     and, because of that header, stops asking wordpress.org about these slugs
 *   - this client answers from updates.json in the public repository
 *   - the ZIP is downloaded directly by the WordPress core upgrader
 *
 * No tokens, no credentials, no external libraries: the repository is public, so
 * `wp plugin update --all`, the weekly update daemon, WP-Cron auto-updates and the
 * Update button in wp-admin all work exactly as they do for wordpress.org plugins.
 *
 * @package VladiMIR_AI_Suite
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( defined( 'VLADIMIR_AI_UPDATER_LOADED' ) || function_exists( 'vladimir_ai_update_manifest' ) ) {
    return;
}
define( 'VLADIMIR_AI_UPDATER_LOADED', '2026-09__1.31' );

// Virtual host used only as a routing key for the WordPress update_plugins_{$host}
// filter. No HTTP request is ever made to it.
define( 'VLADIMIR_AI_UPDATE_HOST', 'vladimir-ai.updates' );
define( 'VLADIMIR_AI_UPDATE_REPO', 'GinCz/plugins' );
define( 'VLADIMIR_AI_UPDATE_BRANCH', 'main' );
define( 'VLADIMIR_AI_UPDATE_MANIFEST', 'https://raw.githubusercontent.com/GinCz/plugins/main/updates.json' );
define( 'VLADIMIR_AI_UPDATE_TTL', 6 * HOUR_IN_SECONDS );
define( 'VLADIMIR_AI_UPDATE_TTL_FAIL', 15 * MINUTE_IN_SECONDS );

/**
 * Fetch and cache the suite manifest.
 *
 * Failures are cached too (short TTL) so a GitHub outage cannot turn every admin
 * page load into a blocking HTTP request.
 *
 * @param bool $force Bypass the cache.
 * @return array<string,mixed> Manifest array, empty on any failure.
 */
if ( ! function_exists( 'vladimir_ai_update_manifest' ) ) {
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

    $response = wp_remote_get(
        add_query_arg( 'ts', time(), VLADIMIR_AI_UPDATE_MANIFEST ),
        array(
            'timeout'     => 12,
            'redirection' => 3,
            'headers'     => array(
                'Accept'     => 'application/json',
                'User-Agent' => 'VladiMIR-AI-Suite-Updater',
            ),
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
}

/**
 * Is this download URL one we are willing to install from?
 *
 * Only HTTPS release assets or raw packages of our own repository qualify.
 *
 * @param string $package Candidate URL from the manifest.
 * @return bool
 */
if ( ! function_exists( 'vladimir_ai_update_package_allowed' ) ) {
function vladimir_ai_update_package_allowed( $package ) {
    $allowed_repo_release = 'https://github.com/' . VLADIMIR_AI_UPDATE_REPO . '/releases/download/';
    $allowed_repo_raw     = 'https://raw.githubusercontent.com/' . VLADIMIR_AI_UPDATE_REPO . '/';
    $allowed_repo_zips    = 'https://github.com/' . VLADIMIR_AI_UPDATE_REPO . '/raw/';
    $allowed_legacy       = 'https://github.com/GinCz/Linux_Server_Public/releases/download/';

    $is_match = ( 0 === strpos( $package, $allowed_repo_release ) )
             || ( 0 === strpos( $package, $allowed_repo_raw ) )
             || ( 0 === strpos( $package, $allowed_repo_zips ) )
             || ( 0 === strpos( $package, $allowed_legacy ) );

    if ( ! $is_match ) {
        return false;
    }

    $parts = wp_parse_url( $package );

    return ! empty( $parts['scheme'] ) && 'https' === $parts['scheme']
        && ! empty( $parts['host'] ) && in_array( strtolower( $parts['host'] ), array( 'github.com', 'raw.githubusercontent.com' ), true );
}
}

/**
 * Answer the core update check for every plugin whose Update URI points at our host.
 *
 * @param array|false $update      Existing update payload from another handler.
 * @param array       $plugin_data Plugin headers.
 * @param string      $plugin_file Plugin file relative to the plugins directory.
 * @return array|false
 */
if ( ! function_exists( 'vladimir_ai_update_check' ) ) {
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

    if ( ! vladimir_ai_update_package_allowed( (string) $entry['package'] ) ) {
        update_site_option( '_vladimir_ai_update_last_error', 'Rejected package URL for ' . $slug );
        return $update;
    }

    $installed = isset( $plugin_data['Version'] ) ? (string) $plugin_data['Version'] : '0';
    if ( ! version_compare( (string) $entry['version'], $installed, '>' ) ) {
        return $update;
    }

    return array(
        'id'           => VLADIMIR_AI_UPDATE_HOST . '/' . $slug,
        'slug'         => $slug,
        'version'      => (string) $entry['version'],
        'new_version'  => (string) $entry['version'],
        'url'          => ! empty( $entry['url'] ) ? (string) $entry['url'] : 'https://github.com/' . VLADIMIR_AI_UPDATE_REPO,
        'package'      => (string) $entry['package'],
        'requires'     => ! empty( $entry['requires'] ) ? (string) $entry['requires'] : '6.0',
        'requires_php' => ! empty( $entry['requires_php'] ) ? (string) $entry['requires_php'] : '7.4',
        'tested'       => ! empty( $entry['tested'] ) ? (string) $entry['tested'] : '6.8',
    );
}
}

add_filter( 'update_plugins_' . VLADIMIR_AI_UPDATE_HOST, 'vladimir_ai_update_check', 10, 3 );

/**
 * Supply metadata for the "View version X details" modal on the Updates screen.
 *
 * @param false|object|array $result Default value.
 * @param string             $action Action name (e.g. "plugin_information").
 * @param object             $args   Query arguments.
 * @return false|object
 */
if ( ! function_exists( 'vladimir_ai_update_info' ) ) {
function vladimir_ai_update_info( $result, $action, $args ) {
    if ( 'plugin_information' !== $action || empty( $args->slug ) ) {
        return $result;
    }

    $manifest = vladimir_ai_update_manifest();
    if ( empty( $manifest['plugins'][ $args->slug ] ) ) {
        return $result;
    }

    $entry = $manifest['plugins'][ $args->slug ];

    $info               = new stdClass();
    $info->name         = ! empty( $entry['name'] ) ? $entry['name'] : $args->slug;
    $info->slug         = $args->slug;
    $info->version      = ! empty( $entry['version'] ) ? $entry['version'] : '0';
    $info->author       = '<a href="https://github.com/GinCz">VladiMIR (GinCz) + AI</a>';
    $info->homepage     = ! empty( $entry['url'] ) ? $entry['url'] : 'https://github.com/' . VLADIMIR_AI_UPDATE_REPO;
    $info->requires     = ! empty( $entry['requires'] ) ? $entry['requires'] : '6.0';
    $info->requires_php = ! empty( $entry['requires_php'] ) ? $entry['requires_php'] : '7.4';
    $info->tested       = ! empty( $entry['tested'] ) ? $entry['tested'] : '6.8';
    $info->download_link = ! empty( $entry['package'] ) ? $entry['package'] : '';

    $info->sections = array(
        'description' => 'Part of the VladiMIR+AI WordPress Plugin Suite. Ultra-lightweight, zero bloat, high security.',
        'changelog'   => '<p>See <a href="https://github.com/' . esc_attr( VLADIMIR_AI_UPDATE_REPO ) . '/tree/main/' . esc_attr( $args->slug ) . '/CHANGELOG.md">CHANGELOG.md</a> for release details.</p>',
    );

    return $info;
}
}

add_filter( 'plugins_api', 'vladimir_ai_update_info', 20, 3 );
