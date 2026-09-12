<?php
/**
 * Plugin Name: WooCommerce Авто генератор SKU & Поиск по артикулу (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-auto-sku
 * Description: Automatically assigns unique non-sequential 5-digit random SKUs (e.g. 74921, 18304) to new WooCommerce products if SKU is empty, while fully preserving manual edits (-1, -2). Enables instant frontend and admin search by SKU.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Requires Plugins: woocommerce
 * Text Domain: wp-auto-sku
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_auto_sku_get_settings() {
    $defaults = array(
        'sku_mode'          => 'random', // 'random' (in disorder: 74921) or 'sequential' (00001)
        'sku_digits'        => 5,
        'sku_prefix'        => '',
        'auto_assign_new'   => 1,
        'enable_sku_search' => 1,
    );
    $saved = get_option( '_vladimir_auto_sku_settings', array() );
    return wp_parse_args( is_array( $saved ) ? $saved : array(), $defaults );
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function( $links ) {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $settings_label = ( 'ru' === $lang ) ? 'Настройки' : ( ( 'cs' === $lang ) ? 'Nastavení' : 'Settings' );
    $docs_label     = ( 'ru' === $lang ) ? 'Документация ↗' : ( ( 'cs' === $lang ) ? 'Dokumentace ↗' : 'Documentation ↗' );

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-auto-sku-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-auto-sku" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'WooCommerce Auto SKU & Search (VladiMIR+AI)',
        'Auto SKU & Search',
        'manage_options',
        'vladimir-auto-sku-settings',
        'vladimir_auto_sku_render_settings_page'
    );
} );

function vladimir_auto_sku_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_auto_sku_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Auto SKU & Search: Настройки артикулов WooCommerce';
        $txt_subtitle = 'Автоматическая генерация уникальных 5-значных артикулов вразброс (74921, 18304) при сохранении возможности ручного ввода (-1, -2) и сквозной поиск по SKU.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_mode     = 'Тип генерации артикула';
        $txt_digits   = 'Количество цифр артикула';
        $txt_prefix   = 'Префикс артикула (необязательно)';
        $txt_auto     = 'Автоматически присваивать артикул при создании товара (если поле пустое)';
        $txt_search   = 'Включить сквозной поиск товаров по артикулу (в каталоге сайта и админке)';
        $txt_save     = 'Сохранить настройки';
        $txt_hint     = '💡 <strong>Ручное редактирование:</strong> Пользователь всегда может свободно менять артикул вручную на экране редактирования товара (дописывать суффиксы -1, -2 или вводить свой код). Плагин генерирует номер ТОЛЬКО если поле артикула оставлено пустым.';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Auto SKU & Search: Nastavení kódů produktů (SKU)';
        $txt_subtitle = 'Automatické generování náhodných 5místných kódů zboží a rychlé vyhledávání podle SKU.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_mode     = 'Typ generování kódu';
        $txt_digits   = 'Počet číslic kódu';
        $txt_prefix   = 'Prefix kódu (volitelné)';
        $txt_auto     = 'Automaticky přiřadit kód při vytvoření zboží (pokud je prázdný)';
        $txt_search   = 'Povolit vyhledávání produktů podle SKU';
        $txt_save     = 'Uložit nastavení';
        $txt_hint     = '💡 <strong>Ruční úprava:</strong> Uživatel může kód zboží kdykoli ručně upravit (přidat -1, -2). Generování probíhá pouze u prázdného pole.';
    } else {
        $txt_title    = 'Auto SKU & Search: WooCommerce SKU Settings';
        $txt_subtitle = 'Non-sequential 5-digit random SKU generator with full manual edit support and instant storewide search.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_mode     = 'Generation Mode';
        $txt_digits   = 'SKU Digit Count';
        $txt_prefix   = 'Optional Prefix';
        $txt_auto     = 'Auto-assign SKU on new product creation (only if empty)';
        $txt_search   = 'Enable Instant SKU Search in Shop & Admin';
        $txt_save     = 'Save Settings';
        $txt_hint     = '💡 <strong>Manual Overrides:</strong> Users can freely edit SKUs manually at any time (e.g. adding -1, -2). The generator only assigns a code when the field is empty.';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🏷️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <div style="background:#f0f9ff;border-left:4px solid #0284c7;padding:12px 16px;border-radius:4px;margin-bottom:20px;font-size:13px;color:#0369a1;">
            <?php echo wp_kses_post( $txt_hint ); ?>
        </div>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_auto_sku_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_auto_sku_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="sku_mode"><strong><?php echo esc_html( $txt_mode ); ?></strong></label></th>
                    <td>
                        <select name="sku_mode" id="sku_mode" style="min-width:260px;">
                            <option value="random" <?php selected( $settings['sku_mode'], 'random' ); ?>>Случайный пятизначный вразброс (напр. 74921, 18304)</option>
                            <option value="sequential" <?php selected( $settings['sku_mode'], 'sequential' ); ?>>Порядковый номер по цепочке (00001, 00002)</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="sku_digits"><strong><?php echo esc_html( $txt_digits ); ?></strong></label></th>
                    <td>
                        <input type="number" name="sku_digits" id="sku_digits" value="<?php echo esc_attr( $settings['sku_digits'] ); ?>" min="3" max="10" style="width:90px;">
                        <span style="color:#64748b;margin-left:6px;">цифр (по умолчанию: 5)</span>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="sku_prefix"><strong><?php echo esc_html( $txt_prefix ); ?></strong></label></th>
                    <td>
                        <input type="text" name="sku_prefix" id="sku_prefix" value="<?php echo esc_attr( $settings['sku_prefix'] ); ?>" class="regular-text" placeholder="Например: SK- или оставьте пустым" style="width:260px;">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><strong>Автоматизация</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="auto_assign_new" value="1" <?php checked( $settings['auto_assign_new'], 1 ); ?>>
                                <?php echo esc_html( $txt_auto ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_sku_search" value="1" <?php checked( $settings['enable_sku_search'], 1 ); ?>>
                                <?php echo esc_html( $txt_search ); ?>
                            </label>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-auto-sku" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_auto_sku_settings', function() {
    check_admin_referer( 'vladimir_save_auto_sku_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'sku_mode'          => ( isset( $_POST['sku_mode'] ) && 'sequential' === $_POST['sku_mode'] ) ? 'sequential' : 'random',
        'sku_digits'        => isset( $_POST['sku_digits'] ) ? max( 3, min( 10, (int) $_POST['sku_digits'] ) ) : 5,
        'sku_prefix'        => sanitize_text_field( (string) ( $_POST['sku_prefix'] ?? '' ) ),
        'auto_assign_new'   => isset( $_POST['auto_assign_new'] ) ? 1 : 0,
        'enable_sku_search' => isset( $_POST['enable_sku_search'] ) ? 1 : 0,
    );

    update_option( '_vladimir_auto_sku_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-auto-sku-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. RANDOM & SEQUENTIAL SKU GENERATOR
// ─────────────────────────────────────────────

function vladimir_generate_unique_sku() {
    $settings = vladimir_auto_sku_get_settings();
    $digits   = (int) $settings['sku_digits'];
    $prefix   = (string) $settings['sku_prefix'];
    $mode     = (string) $settings['sku_mode'];

    if ( 'random' === $mode ) {
        $min = (int) pow( 10, $digits - 1 );
        $max = (int) pow( 10, $digits ) - 1;

        for ( $i = 0; $i < 100; $i++ ) {
            $num       = mt_rand( $min, $max );
            $candidate = $prefix . $num;
            if ( ! function_exists( 'wc_get_product_id_by_sku' ) || ! wc_get_product_id_by_sku( $candidate ) ) {
                return $candidate;
            }
        }
        return $prefix . time();
    } else {
        $counter = (int) get_option( '_vladimir_auto_sku_counter', 1 );
        $sku     = $prefix . str_pad( (string) $counter, $digits, '0', STR_PAD_LEFT );
        update_option( '_vladimir_auto_sku_counter', $counter + 1 );
        return $sku;
    }
}

// ─────────────────────────────────────────────
// 5. AUTO-ASSIGNMENT (ONLY WHEN EMPTY — PRESERVES MANUAL EDITS)
// ─────────────────────────────────────────────

add_action( 'save_post_product', function( $post_id, $post, $update ) {
    if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
        return;
    }
    if ( wp_is_post_revision( $post_id ) ) {
        return;
    }

    $settings = vladimir_auto_sku_get_settings();
    if ( empty( $settings['auto_assign_new'] ) ) {
        return;
    }

    // Check if user manually entered an SKU in $_POST (e.g. from WooCommerce product edit screen)
    if ( isset( $_POST['_sku'] ) && '' !== trim( (string) $_POST['_sku'] ) ) {
        // User manually typed or edited an SKU (e.g. 74921-1, 74921-2) — DO NOT OVERWRITE!
        return;
    }

    // Check current SKU in post meta
    $current_sku = get_post_meta( $post_id, '_sku', true );
    if ( '' === trim( (string) $current_sku ) ) {
        $new_sku = vladimir_generate_unique_sku();
        update_post_meta( $post_id, '_sku', $new_sku );
    }
}, 20, 3 );

// ─────────────────────────────────────────────
// 6. INSTANT SEARCH BY SKU (FRONTEND & ADMIN)
// ─────────────────────────────────────────────

add_filter( 'posts_search', function( $search, $wp_query ) {
    global $wpdb;

    $settings = vladimir_auto_sku_get_settings();
    if ( empty( $settings['enable_sku_search'] ) || ! $wp_query->is_search() ) {
        return $search;
    }

    $q = $wp_query->get( 's' );
    if ( empty( $q ) ) {
        return $search;
    }

    $escaped_q = '%' . $wpdb->esc_like( $q ) . '%';
    $sku_sql   = $wpdb->prepare(
        " OR EXISTS (SELECT 1 FROM {$wpdb->postmeta} WHERE post_id = {$wpdb->posts}.ID AND meta_key = '_sku' AND meta_value LIKE %s)",
        $escaped_q
    );

    $search = preg_replace( "#\({$wpdb->posts}\.post_title LIKE [^)]+\)#", "$0" . $sku_sql, $search, 1 );
    return $search;
}, 20, 2 );

// ─────────────────────────────────────────────
// 7. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WooCommerce Авто генератор SKU & Поиск по артикулу (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Автоматически присваивает уникальные 5-значные артикулы вразброс новым товарам при пустом поле артикула. Полностью сохраняет ручные правки артикула (-1, -2) и включает поиск по артикулу.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WooCommerce Auto SKU & Search (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Automaticky generuje náhodné 5místné kódy zboží při vytvoření nového produktu a umožňuje ruční úpravy i vyhledávání.';
        }
    }
    return $plugins;
} );
