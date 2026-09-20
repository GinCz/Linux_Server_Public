<?php
/**
 * VladiMIR+AI Suite - shared auto-update client (public GitHub repository).
 *
 * Master copy: WordPress/Plugins/_shared/vladimir-ai-updater.php
 * A byte-identical copy ships inside every plugin folder and is pulled in with
 * require_once. The first plugin loaded wins, the rest short-circuit, so a site
 * makes one manifest request every 6 hours no matter how many suite plugins it runs.
 *
 * Wiring:
 *   - every plugin header carries "Update URI: https://vladimir-ai.updates/<slug>"
 *   - WordPress dispatches its update check to update_plugins_vladimir-ai.updates
 *     and, because of that header, stops asking wordpress.org about these slugs
 *   - this client answers from WordPress/Plugins/updates.json in the public repository
 *   - the ZIP is a normal public release asset, downloaded by the core upgrader
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

// Two independent guards on purpose. The constant alone was not enough: when copies of
// DIFFERENT releases of this file sat in different plugin folders, one of them could be
// served from a stale OPcache entry, the constant check passed, and PHP still hit
// "Cannot redeclare vladimir_ai_update_manifest()" - a fatal error that took whole sites
// down with HTTP 500. Checking for the function itself cannot be fooled that way.
if ( defined( 'VLADIMIR_AI_UPDATER_LOADED' ) || function_exists( 'vladimir_ai_update_manifest' ) ) {
    return;
}
define( 'VLADIMIR_AI_UPDATER_LOADED', '2026-09__1.25' );

// Virtual host used only as a routing key for the WordPress update_plugins_{$host}
// filter. No HTTP request is ever made to it.
define( 'VLADIMIR_AI_UPDATE_HOST', 'vladimir-ai.updates' );
define( 'VLADIMIR_AI_UPDATE_REPO', 'GinCz/Linux_Server_Public' );
define( 'VLADIMIR_AI_UPDATE_BRANCH', 'main' );
define( 'VLADIMIR_AI_UPDATE_MANIFEST', 'https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/WordPress/Plugins/updates.json' );
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

/**
 * Is this download URL one we are willing to install from?
 *
 * Only HTTPS release assets of our own repository qualify. Everything else - another
 * repository, a raw file, a redirector, plain HTTP - is refused.
 *
 * @param string $package Candidate URL from the manifest.
 * @return bool
 */
function vladimir_ai_update_package_allowed( $package ) {
    $allowed = 'https://github.com/' . VLADIMIR_AI_UPDATE_REPO . '/releases/download/';

    if ( 0 !== strpos( $package, $allowed ) ) {
        return false;
    }

    $parts = wp_parse_url( $package );

    return ! empty( $parts['scheme'] ) && 'https' === $parts['scheme']
        && ! empty( $parts['host'] ) && 'github.com' === strtolower( $parts['host'] );
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

    // Hard allow-list for the download URL. The package is handed straight to the core
    // upgrader, which unpacks it over wp-content/plugins - so a manifest that ever got
    // tampered with must not be able to point a site at someone else's archive.
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
 * Drop the manifest cache whenever an admin asks WordPress to re-check for updates,
 * so "Check again" is never answered from a stale 6-hour cache.
 */
function vladimir_ai_update_flush_cache() {
    delete_site_transient( '_vladimir_ai_manifest' );
}
add_action( 'upgrader_process_complete', 'vladimir_ai_update_flush_cache' );
add_action( 'load-update-core.php', 'vladimir_ai_update_flush_cache' );

/**
 * Surface a broken manifest on the plugins screen instead of failing silently -
 * a silent updater is worse than no updater.
 */
function vladimir_ai_update_admin_notice() {
    $screen = function_exists( 'get_current_screen' ) ? get_current_screen() : null;
    if ( ! $screen || ! in_array( $screen->id, array( 'plugins', 'plugins-network' ), true ) ) {
        return;
    }

    if ( ! current_user_can( 'update_plugins' ) ) {
        return;
    }

    $error = get_site_option( '_vladimir_ai_update_last_error', '' );
    if ( ! empty( $error ) ) {
        echo '<div class="notice notice-error"><p><strong>VladiMIR+AI Suite:</strong> update manifest unreachable ('
            . esc_html( (string) $error ) . ').</p></div>';
    }
}
add_action( 'admin_notices', 'vladimir_ai_update_admin_notice' );
