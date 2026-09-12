<?php
/**
 * Plugin Name: Image Resizer on Upload (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/image-resizer
 * Description: Automatically resizes massive JPEG and PNG uploads down to a configurable maximum size (default: 1600x1600 px) with high-quality compression. Saves server disk space and speeds up the site.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: image-resizer
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_ir_get_settings() {
    $defaults = array(
        'max_width'     => 1600,
        'max_height'    => 1600,
        'jpeg_quality'  => 92,
        'enable_resize' => 1,
    );
    $saved = get_option( '_vladimir_ir_settings', array() );
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-ir-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/image-resizer" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Image Resizer on Upload (VladiMIR+AI)',
        'Image Resizer',
        'manage_options',
        'vladimir-ir-settings',
        'vladimir_ir_render_settings_page'
    );
} );

function vladimir_ir_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_ir_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'Image Resizer: Настройки автоматического масштабирования фото';
        $txt_subtitle = 'Уменьшает огромные фото при загрузке (с камер и телефонов), освобождая место на SSD диске хостинга.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_en       = 'Включить масштабирование изображений при загрузке';
        $txt_w        = 'Максимальная ширина (px)';
        $txt_h        = 'Максимальная высота (px)';
        $txt_q        = 'Качество JPEG (от 60 до 100)';
        $txt_q_desc   = 'Рекомендуется: 90–92 (отличное качество без визуальных потерь и артефактов).';
        $txt_save     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'Image Resizer: Nastavení změny velikosti obrázků';
        $txt_subtitle = 'Automaticky zmenšuje velké fotografie při nahrávání na web a šetří místo na disku.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_en       = 'Povolit automatické zmenšování fotografií';
        $txt_w        = 'Maximální šířka (px)';
        $txt_h        = 'Maximální výška (px)';
        $txt_q        = 'Kvalita JPEG (60–100)';
        $txt_q_desc   = 'Doporučeno: 90–92 pro ostré zobrazení a úsporu místa.';
        $txt_save     = 'Uložit nastavení';
    } else {
        $txt_title    = 'Image Resizer: Upload Resizing Settings';
        $txt_subtitle = 'Downscales oversized photo uploads to save server storage and improve page load speed.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_en       = 'Enable Automatic Upload Resizing';
        $txt_w        = 'Maximum Width (px)';
        $txt_h        = 'Maximum Height (px)';
        $txt_q        = 'JPEG Quality (60-100)';
        $txt_q_desc   = 'Recommended: 90-92 for high visual quality.';
        $txt_save     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🖼️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_ir_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_ir_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Состояние</strong></th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_resize" value="1" <?php checked( $settings['enable_resize'], 1 ); ?>>
                            <?php echo esc_html( $txt_en ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="max_width"><strong><?php echo esc_html( $txt_w ); ?></strong></label></th>
                    <td>
                        <input type="number" name="max_width" id="max_width" value="<?php echo esc_attr( $settings['max_width'] ); ?>" min="600" max="6000" style="width:120px;"> px
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="max_height"><strong><?php echo esc_html( $txt_h ); ?></strong></label></th>
                    <td>
                        <input type="number" name="max_height" id="max_height" value="<?php echo esc_attr( $settings['max_height'] ); ?>" min="600" max="6000" style="width:120px;"> px
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="jpeg_quality"><strong><?php echo esc_html( $txt_q ); ?></strong></label></th>
                    <td>
                        <input type="number" name="jpeg_quality" id="jpeg_quality" value="<?php echo esc_attr( $settings['jpeg_quality'] ); ?>" min="50" max="100" style="width:120px;"> %
                        <p class="description"><?php echo esc_html( $txt_q_desc ); ?></p>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/image-resizer" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_ir_settings', function() {
    check_admin_referer( 'vladimir_save_ir_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'enable_resize' => isset( $_POST['enable_resize'] ) ? 1 : 0,
        'max_width'     => isset( $_POST['max_width'] ) ? max( 300, min( 8000, (int) $_POST['max_width'] ) ) : 1600,
        'max_height'    => isset( $_POST['max_height'] ) ? max( 300, min( 8000, (int) $_POST['max_height'] ) ) : 1600,
        'jpeg_quality'  => isset( $_POST['jpeg_quality'] ) ? max( 50, min( 100, (int) $_POST['jpeg_quality'] ) ) : 92,
    );

    update_option( '_vladimir_ir_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-ir-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. IMAGE RESIZE ON UPLOAD ENGINE
// ─────────────────────────────────────────────

add_filter( 'wp_handle_upload', function( $upload ) {
    $settings = vladimir_ir_get_settings();
    if ( empty( $settings['enable_resize'] ) ) {
        return $upload;
    }

    if ( ! isset( $upload['file'] ) || ! isset( $upload['type'] ) ) {
        return $upload;
    }

    $allowed_types = array( 'image/jpeg', 'image/png' );
    if ( ! in_array( $upload['type'], $allowed_types, true ) ) {
        return $upload;
    }

    $file_path = $upload['file'];
    $max_w     = (int) $settings['max_width'];
    $max_h     = (int) $settings['max_height'];
    $quality   = (int) $settings['jpeg_quality'];

    $editor = wp_get_image_editor( $file_path );
    if ( is_wp_error( $editor ) ) {
        return $upload;
    }

    $size = $editor->get_size();
    if ( $size['width'] > $max_w || $size['height'] > $max_h ) {
        $editor->set_quality( $quality );
        $resized = $editor->resize( $max_w, $max_h, false );
        if ( ! is_wp_error( $resized ) ) {
            $editor->save( $file_path );
        }
    }

    return $upload;
} );

add_filter( 'jpeg_quality', function( $default_quality ) {
    $settings = vladimir_ir_get_settings();
    return ! empty( $settings['jpeg_quality'] ) ? (int) $settings['jpeg_quality'] : $default_quality;
} );

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Image Resizer on Upload (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Автоматически уменьшает огромные фото при загрузке до 1600x1600 px с качеством 92%. Экономит дисковое пространство сервера.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Image Resizer on Upload (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Automaticky zmenšuje velké fotografie při nahrávání na 1600x1600 px v kvalitě 92%. Šetří místo na serveru.';
        }
    }
    return $plugins;
} );
