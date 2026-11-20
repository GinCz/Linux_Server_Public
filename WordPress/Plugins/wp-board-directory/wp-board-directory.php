<?php
/**
 * Plugin Name: WP Board & Directory (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/WordPress/tree/main/plugins/wp-board-directory
 * Description: Ultra-fast unified classified ads and business directory plugin. Integrates ads, company profiles, anti-fraud ratings, client-side WebP compression up to 15 photos, Cloudflare Turnstile and 1-Click migration.
 * Version:     2026-11__1.23
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-board-directory
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-board-directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Shared auto-update client (guarded)
if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

// Shared plugin-list translations (7 languages)
if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-i18n.php';
}

define( 'VB_BOARD_VERSION', '2026-11__1.22' );
define( 'VB_BOARD_PATH', plugin_dir_path( __FILE__ ) );
define( 'VB_BOARD_DIR', VB_BOARD_PATH );
define( 'VB_BOARD_URL', plugin_dir_url( __FILE__ ) );

// Load Submodules
require_once VB_BOARD_PATH . 'includes/class-db.php';
require_once VB_BOARD_PATH . 'includes/class-cpt.php';
require_once VB_BOARD_PATH . 'includes/class-ratings.php';
require_once VB_BOARD_PATH . 'includes/class-importer.php';
require_once VB_BOARD_PATH . 'includes/class-media-cleaner.php';
require_once VB_BOARD_PATH . 'includes/class-shortcodes.php';
require_once VB_BOARD_PATH . 'includes/class-cron.php';

// Activation Hook
register_activation_hook( __FILE__, function() {
    VB_DB::create_tables();
    VB_CPT::register_post_types();
    VB_CPT::register_taxonomies();
    flush_rewrite_rules();
} );

// Initialization
add_action( 'plugins_loaded', function() {
    VB_CPT::init();
    VB_Ratings::init();
    VB_Importer::init();
    VB_Media_Cleaner::init();
    VB_Shortcodes::init();
    VB_Cron::init();
} );

// Enqueue Frontend Assets
add_action( 'wp_enqueue_scripts', function() {
    wp_enqueue_style( 'vb-board-style', VB_BOARD_URL . 'assets/css/vb-board.css', [], VB_BOARD_VERSION );
    wp_enqueue_script( 'vb-board-script', VB_BOARD_URL . 'assets/js/vb-board.js', [], VB_BOARD_VERSION, true );

    wp_localize_script( 'vb-board-script', 'vbBoardData', [
        'ajaxUrl'  => admin_url( 'admin-ajax.php' ),
        'nonce'    => wp_create_nonce( 'vb_board_nonce' ),
        'isLogged' => is_user_logged_in(),
    ] );
} );
