<?php
/**
 * Plugin Name: Image Resizer on Upload (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/image-resizer
 * Description: Automatically resizes massive JPEG and PNG uploads down to a configurable maximum size (default: 1600x1600 px) with high-quality compression. Saves server disk space and speeds up the site. Optional Cloudflare Edge delivery.
 * Version:     2026-10__1.38
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/image-resizer
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: image-resizer
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Shared auto-update client (public GitHub repository, see updates.json).
if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

// Shared plugin-list translations (8 languages).
if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-i18n.php';
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_ir_get_settings() {
    $defaults = array(
        'max_width'         => 1600,
        'max_height'        => 1600,
        'jpeg_quality'      => 92,
        'enable_resize'     => 1,
        'enable_cloudflare' => 0, // Disabled by default for RU / non-CF sites
        'cloudflare_domain' => '', // e.g. https://images.mysite.com
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-ir-settings' ) ) . '" style="white-space:nowrap;">' . esc_html( $settings_label ) . '</a>';
    $docs_link     = '<a href="https://github.com/GinCz/plugins/tree/main/image-resizer" target="_blank" style="white-space:nowrap;">' . esc_html( $docs_label ) . '</a>';

    return array_merge( array(
        'settings' => $settings_link,
        'docs'     => $docs_link,
    ), $links );
} );

add_action( 'admin_head-plugins.php', function() {
    static $css_done = false;
    if ( ! $css_done ) {
        $css_done = true;
        echo '<style>.plugins .row-actions { white-space: nowrap !important; }</style>';
    }
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Image Resizer on Upload (VladiMIR+AI✅)',
        '🖼️ Image Resizer',
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
        $txt_title          = 'Image Resizer: Настройки автоматического масштабирования фото';
        $txt_subtitle       = 'Уменьшает огромные фото при загрузке (с камер и телефонов), освобождая место на SSD диске хостинга.';
        $txt_saved          = 'Настройки успешно сохранены!';
        $txt_en             = 'Включить локальное масштабирование изображений при загрузке';
        $txt_w              = 'Максимальная ширина (px)';
        $txt_h              = 'Максимальная высота (px)';
        $txt_q              = 'Качество JPEG (от 60 до 100)';
        $txt_q_desc         = 'Рекомендуется: 90–92 (отличное качество без визуальных потерь и артефактов).';
        $txt_cf_title       = 'Раздача и оптимизация через Cloudflare Edge';
        $txt_cf_badge       = 'Опционально';
        $txt_cf_warn        = '⚠️ Внимание: оставьте выключенным для сайтов в зоне .RU / .РФ и серверов в России, где сервисы Cloudflare могут быть заблокированы или работать нестабильно.';
        $txt_cf_en          = 'Включить обработку и раздачу изображений через Cloudflare Edge';
        $txt_cf_domain      = 'Домен раздачи Cloudflare / Worker URL';
        $txt_cf_domain_desc = 'Например: https://images.mysite.com (подменяет домен uploads на лету в выводе страниц без изменения базы данных).';
        $txt_save           = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title          = 'Image Resizer: Nastavení změny velikosti obrázků';
        $txt_subtitle       = 'Automaticky zmenšuje velké fotografie při nahrávání na web a šetří místo na disku.';
        $txt_saved          = 'Nastavení bylo úspěšně uloženo!';
        $txt_en             = 'Povolit lokální automatické zmenšování fotografií';
        $txt_w              = 'Maximální šířka (px)';
        $txt_h              = 'Maximální výška (px)';
        $txt_q              = 'Kvalita JPEG (60–100)';
        $txt_q_desc         = 'Doporučeno: 90–92 pro ostré zobrazení a úsporu místa.';
        $txt_cf_title       = 'Doručování a optimalizace přes Cloudflare Edge';
        $txt_cf_badge       = 'Volitelné';
        $txt_cf_warn        = '⚠️ Upozornění: ponechte vypnuté pro weby v zóně .RU a servery v Rusku, kde může být Cloudflare blokován.';
        $txt_cf_en          = 'Povolit doručování obrázků přes Cloudflare Edge';
        $txt_cf_domain      = 'Cloudflare doména / Worker URL';
        $txt_cf_domain_desc = 'Např.: https://images.mysite.com (dynamicky nahradí doménu uploads na webu bez zásahu do databáze).';
        $txt_save           = 'Uložit nastavení';
    } else {
        $txt_title          = 'Image Resizer: Upload Resizing Settings';
        $txt_subtitle       = 'Downscales oversized photo uploads to save server storage and improve page load speed.';
        $txt_saved          = 'Settings successfully saved!';
        $txt_en             = 'Enable Local Automatic Upload Resizing';
        $txt_w              = 'Maximum Width (px)';
        $txt_h              = 'Maximum Height (px)';
        $txt_q              = 'JPEG Quality (60-100)';
        $txt_q_desc         = 'Recommended: 90-92 for high visual quality.';
        $txt_cf_title       = 'Cloudflare Edge Delivery & Optimization';
        $txt_cf_badge       = 'Optional';
        $txt_cf_warn        = '⚠️ Note: Leave disabled for websites in the .RU zone and Russian servers where Cloudflare may be blocked or unstable.';
        $txt_cf_en          = 'Enable Cloudflare Edge image delivery';
        $txt_cf_domain      = 'Cloudflare Delivery Domain / Worker URL';
        $txt_cf_domain_desc = 'e.g. https://images.mysite.com (rewrites upload URLs on-the-fly without modifying the database).';
        $txt_save           = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🖼️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI✅)</span>
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
                    <th scope="row"><strong>Status</strong></th>
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

                <tr>
                    <td colspan="2" style="padding:20px 0 5px 0;">
                        <hr style="border:0;border-top:1px solid #e2e8f0;margin:0 0 15px 0;">
                        <h3 style="margin:0 0 5px 0;display:flex;align-items:center;gap:8px;">
                            <span>☁️ <?php echo esc_html( $txt_cf_title ); ?></span>
                            <span style="font-size:11px;background:#f59e0b;color:#fff;padding:2px 7px;border-radius:10px;font-weight:600;"><?php echo esc_html( $txt_cf_badge ); ?></span>
                        </h3>
                        <p style="color:#b91c1c;font-size:13px;margin:5px 0 10px 0;background:#fef2f2;border-left:3px solid #ef4444;padding:8px 12px;border-radius:4px;">
                            <?php echo esc_html( $txt_cf_warn ); ?>
                        </p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><strong>Cloudflare Edge</strong></th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_cloudflare" id="enable_cloudflare" value="1" <?php checked( $settings['enable_cloudflare'], 1 ); ?>>
                            <?php echo esc_html( $txt_cf_en ); ?>
                        </label>
                    </td>
                </tr>
                <tr id="row_cf_domain" style="<?php echo empty( $settings['enable_cloudflare'] ) ? 'display:none;' : ''; ?>">
                    <th scope="row"><label for="cloudflare_domain"><strong><?php echo esc_html( $txt_cf_domain ); ?></strong></label></th>
                    <td>
                        <input type="url" name="cloudflare_domain" id="cloudflare_domain" value="<?php echo esc_attr( $settings['cloudflare_domain'] ); ?>" placeholder="https://images.mysite.com" style="width:360px;">
                        <p class="description"><?php echo esc_html( $txt_cf_domain_desc ); ?></p>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <script>
        document.addEventListener('DOMContentLoaded', function() {
            var cfCheck = document.getElementById('enable_cloudflare');
            var cfRow = document.getElementById('row_cf_domain');
            if (cfCheck && cfRow) {
                cfCheck.addEventListener('change', function() {
                    cfRow.style.display = this.checked ? '' : 'none';
                });
            }
        });
        </script>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/plugins/tree/main/image-resizer" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_ir_settings', function() {
    check_admin_referer( 'vladimir_save_ir_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $cf_domain = isset( $_POST['cloudflare_domain'] ) ? esc_url_raw( trim( $_POST['cloudflare_domain'] ) ) : '';
    $cf_domain = rtrim( $cf_domain, '/' );

    $updated = array(
        'enable_resize'     => isset( $_POST['enable_resize'] ) ? 1 : 0,
        'max_width'         => isset( $_POST['max_width'] ) ? max( 300, min( 8000, (int) $_POST['max_width'] ) ) : 1600,
        'max_height'        => isset( $_POST['max_height'] ) ? max( 300, min( 8000, (int) $_POST['max_height'] ) ) : 1600,
        'jpeg_quality'      => isset( $_POST['jpeg_quality'] ) ? max( 50, min( 100, (int) $_POST['jpeg_quality'] ) ) : 92,
        'enable_cloudflare' => isset( $_POST['enable_cloudflare'] ) ? 1 : 0,
        'cloudflare_domain' => $cf_domain,
    );

    update_option( '_vladimir_ir_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-ir-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. IMAGE RESIZE ON UPLOAD ENGINE (LOCAL)
// ─────────────────────────────────────────────

add_filter( 'wp_handle_upload', function( $upload ) {
    $settings = vladimir_ir_get_settings();
    if ( empty( $settings['enable_resize'] ) ) {
        return $upload;
    }

    if ( ! isset( $upload['file'] ) || ! isset( $upload['type'] ) ) {
        return $upload;
    }

    $allowed_types = array( 'image/jpeg', 'image/png', 'image/webp' );
    if ( ! in_array( $upload['type'], $allowed_types, true ) ) {
        return $upload;
    }

    if ( ! file_exists( $upload['file'] ) || ! is_writable( $upload['file'] ) ) {
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

add_filter( 'wp_editor_set_quality', function( $default_quality ) {
    $settings = vladimir_ir_get_settings();
    return ! empty( $settings['jpeg_quality'] ) ? (int) $settings['jpeg_quality'] : $default_quality;
} );

add_filter( 'big_image_size_threshold', function( $threshold ) {
    $settings = vladimir_ir_get_settings();

    if ( empty( $settings['enable_resize'] ) ) {
        return $threshold;
    }

    $cap = max( (int) $settings['max_width'], (int) $settings['max_height'] );

    return ( $cap > 0 && $cap <= $threshold ) ? false : $threshold;
} );

// ─────────────────────────────────────────────
// 5. CLOUDFLARE EDGE DELIVERY ENGINE (OPTIONAL)
// ─────────────────────────────────────────────

function vladimir_ir_get_cf_domain() {
    static $cf_domain = null;
    if ( null !== $cf_domain ) {
        return $cf_domain;
    }
    $settings = vladimir_ir_get_settings();
    if ( empty( $settings['enable_cloudflare'] ) || empty( $settings['cloudflare_domain'] ) ) {
        $cf_domain = false;
        return $cf_domain;
    }
    $cf_domain = rtrim( trim( $settings['cloudflare_domain'] ), '/' );
    return $cf_domain;
}

function vladimir_ir_rewrite_url_to_cf( $url ) {
    $cf_domain = vladimir_ir_get_cf_domain();
    if ( empty( $cf_domain ) || empty( $url ) || ! is_string( $url ) ) {
        return $url;
    }

    // Only process supported web images
    if ( ! preg_match( '/\.(jpe?g|png|webp|gif|avif)(\?.*)?$/i', $url ) ) {
        return $url;
    }

    $upload_dir = wp_get_upload_dir();
    $base_url   = rtrim( $upload_dir['baseurl'], '/' );

    if ( strpos( $url, $base_url ) === 0 ) {
        $parsed_site = wp_parse_url( $base_url );
        $parsed_cf   = wp_parse_url( $cf_domain );

        if ( ! empty( $parsed_site['host'] ) && ! empty( $parsed_cf['host'] ) ) {
            $site_prefix = $parsed_site['scheme'] . '://' . $parsed_site['host'];
            $cf_prefix   = $parsed_cf['scheme'] . '://' . $parsed_cf['host'];
            return str_replace( $site_prefix, $cf_prefix, $url );
        }
    }

    return $url;
}

// Rewrites single attachment URL
add_filter( 'wp_get_attachment_url', function( $url ) {
    return vladimir_ir_rewrite_url_to_cf( $url );
}, 99 );

// Rewrites responsive srcset entries
add_filter( 'wp_calculate_image_srcset', function( $sources ) {
    $cf_domain = vladimir_ir_get_cf_domain();
    if ( empty( $cf_domain ) || ! is_array( $sources ) ) {
        return $sources;
    }

    foreach ( $sources as $width => $source ) {
        if ( isset( $source['url'] ) ) {
            $sources[ $width ]['url'] = vladimir_ir_rewrite_url_to_cf( $source['url'] );
        }
    }

    return $sources;
}, 99 );

// Rewrites content images dynamically without modifying the database
add_filter( 'the_content', function( $content ) {
    $cf_domain = vladimir_ir_get_cf_domain();
    if ( empty( $cf_domain ) || empty( $content ) || ! is_string( $content ) ) {
        return $content;
    }

    $upload_dir = wp_get_upload_dir();
    $base_url   = rtrim( $upload_dir['baseurl'], '/' );
    $parsed_site = wp_parse_url( $base_url );
    $parsed_cf   = wp_parse_url( $cf_domain );

    if ( ! empty( $parsed_site['host'] ) && ! empty( $parsed_cf['host'] ) ) {
        $site_prefix = $parsed_site['scheme'] . '://' . $parsed_site['host'];
        $cf_prefix   = $parsed_cf['scheme'] . '://' . $parsed_cf['host'];

        $content = preg_replace_callback(
            '#(' . preg_quote( $site_prefix, '#' ) . ')/[^\s"\'>]+\.(jpe?g|png|webp|gif|avif)(\?[^\s"\'>]*)?#i',
            function( $m ) use ( $site_prefix, $cf_prefix ) {
                return str_replace( $site_prefix, $cf_prefix, $m[0] );
            },
            $content
        );
    }

    return $content;
}, 99 );
