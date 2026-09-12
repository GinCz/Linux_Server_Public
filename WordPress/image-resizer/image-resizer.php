<?php
/**
 * Plugin Name: Smart Image Resizer 1600px 95% (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/image-resizer
 * Description: Automatically resizes uploaded high-resolution images to a maximum of 1600x1600px while maintaining crisp 95% JPEG quality. Zero configuration, replaces heavy image optimization plugins.
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

function vladimir_image_resizer_get_settings() {
     = array(
        'max_width'    => 1600,
        'max_height'   => 1600,
        'jpeg_quality' => 95,
        'process_jpeg' => 1,
        'process_png'  => 1,
        'process_webp' => 1,
    );
     = get_option( '_vladimir_image_resizer_settings', array() );
    return wp_parse_args( is_array(  ) ?  : array(),  );
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function(  ) {
     = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
       = strtolower( substr( , 0, 2 ) );

     = ( 'ru' ===  ) ? 'Настройки' : ( ( 'cs' ===  ) ? 'Nastavení' : 'Settings' );
         = ( 'ru' ===  ) ? 'Документация ↗' : ( ( 'cs' ===  ) ? 'Dokumentace ↗' : 'Documentation ↗' );

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-image-resizer-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/image-resizer" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Smart Image Resizer (VladiMIR+AI)',
        'Сжатие изображений',
        'manage_options',
        'vladimir-image-resizer-settings',
        'vladimir_image_resizer_render_settings_page'
    );
} );

function vladimir_image_resizer_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_image_resizer_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'Умное сжатие изображений: Настройки';
                = 'Автоматическое пропорциональное уменьшение фото при загрузке без потери резкости и детализации.';
               = 'Настройки успешно сохранены!';
               = 'Максимальная ширина (px)';
          = 'Изображения шире этого значения будут пропорционально уменьшены (по умолчанию: 1600).';
               = 'Максимальная высота (px)';
          = 'Изображения выше этого значения будут пропорционально уменьшены (по умолчанию: 1600).';
             = 'Качество JPEG (%)';
           = 'Значение от 60 до 100. 95% обеспечивает отсутствие артефактов компрессии и размытия.';
             = 'Обрабатываемые форматы';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'Chytré zmenšení obrázků: Nastavení';
                = 'Automatické proporcionální zmenšení nahrávaných fotografií bez ztráty ostrosti a kvality.';
               = 'Nastavení bylo úspěšně uloženo!';
               = 'Maximální šířka (px)';
          = 'Obrázky širší než tato hodnota budou zmenšeny (výchozí: 1600).';
               = 'Maximální výška (px)';
          = 'Obrázky vyšší než tato hodnota budou zmenšeny (výchozí: 1600).';
             = 'Kvalita JPEG (%)';
           = 'Hodnota 60 až 100. 95 % zajišťuje ostrý obraz bez šumu.';
             = 'Zpracovávané formáty';
            = 'Uložit nastavení';
    } else {
               = 'Smart Image Resizer: Settings';
                = 'Automatic proportional image downscaling upon upload while preserving 95% crispness.';
               = 'Settings successfully saved!';
               = 'Maximum Width (px)';
          = 'Images exceeding this width will be downscaled proportionally (default: 1600).';
               = 'Maximum Height (px)';
          = 'Images exceeding this height will be downscaled proportionally (default: 1600).';
             = 'JPEG Quality (%)';
           = 'Value 60-100. 95% guarantees zero blurriness and clean typography.';
             = 'Supported Image Formats';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🖼️ <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_image_resizer_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_image_resizer_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="max_width"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="number" name="max_width" id="max_width" min="400" max="6000" step="50" value="<?php echo esc_attr( ['max_width'] ); ?>" class="small-text"> px
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="max_height"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="number" name="max_height" id="max_height" min="400" max="6000" step="50" value="<?php echo esc_attr( ['max_height'] ); ?>" class="small-text"> px
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="jpeg_quality"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="number" name="jpeg_quality" id="jpeg_quality" min="60" max="100" value="<?php echo esc_attr( ['jpeg_quality'] ); ?>" class="small-text"> %
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label style="margin-right:15px;">
                            <input type="checkbox" name="process_jpeg" value="1" <?php checked( ['process_jpeg'], 1 ); ?>>
                            JPEG (.jpg, .jpeg)
                        </label>
                        <label style="margin-right:15px;">
                            <input type="checkbox" name="process_png" value="1" <?php checked( ['process_png'], 1 ); ?>>
                            PNG (.png)
                        </label>
                        <label>
                            <input type="checkbox" name="process_webp" value="1" <?php checked( ['process_webp'], 1 ); ?>>
                            WebP (.webp)
                        </label>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/image-resizer" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_image_resizer_settings', function() {
    check_admin_referer( 'vladimir_save_image_resizer_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'max_width'    => max( 400, min( 6000, (int) ( ['max_width'] ?? 1600 ) ) ),
        'max_height'   => max( 400, min( 6000, (int) ( ['max_height'] ?? 1600 ) ) ),
        'jpeg_quality' => max( 60, min( 100, (int) ( ['jpeg_quality'] ?? 95 ) ) ),
        'process_jpeg' => isset( ['process_jpeg'] ) ? 1 : 0,
        'process_png'  => isset( ['process_png'] ) ? 1 : 0,
        'process_webp' => isset( ['process_webp'] ) ? 1 : 0,
    );

    update_option( '_vladimir_image_resizer_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-image-resizer-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. IMAGE PROCESSING ENGINE
// ─────────────────────────────────────────────

 = vladimir_image_resizer_get_settings();
  = (int) ['jpeg_quality'];

add_filter( 'jpeg_quality', function() use (  ) {
    return ;
} );

add_filter( 'wp_editor_set_quality', function() use (  ) {
    return ;
} );

add_filter( 'wp_handle_upload', function( zpr.psm1 ) {
    if ( ! empty( zpr.psm1['error'] ) ) {
        return zpr.psm1;
    }

          = vladimir_image_resizer_get_settings();
     = array();

    if ( ! empty( ['process_jpeg'] ) ) {
        [] = 'image/jpeg';
    }
    if ( ! empty( ['process_png'] ) ) {
        [] = 'image/png';
    }
    if ( ! empty( ['process_webp'] ) ) {
        [] = 'image/webp';
    }

    if ( empty(  ) || ! isset( zpr.psm1['type'] ) || ! in_array( zpr.psm1['type'], , true ) ) {
        return zpr.psm1;
    }

     = zpr.psm1['file'];
       = wp_get_image_editor(  );

    if ( is_wp_error(  ) ) {
        return zpr.psm1;
    }

       = ->get_size();
      = (int) ['max_width'];
      = (int) ['max_height'];
       = (int) ['jpeg_quality'];

    // Resize proportionally if dimensions exceed thresholds
    if ( ['width'] >  || ['height'] >  ) {
        ->set_quality(  );
         = ->resize( , , false );

        if ( ! is_wp_error(  ) ) {
            ->save(  );
        }
    }

    return zpr.psm1;
} );

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'Умное сжатие изображений 1600px 95% (VladiMIR+AI)';
            [  ]['Description'] = 'Автоматически уменьшает загружаемые фото до максимального размера 1600x1600px с высоким качеством 95% (без мыла и потери детализации). Включает панель настроек на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'Chytré zmenšení obrázků 1600px 95% (VladiMIR+AI)';
            [  ]['Description'] = 'Automaticky zmenšuje nahrané fotografie ve vysokém rozlišení na maximální rozměr 1600x1600 px při zachování špičkové kvality JPEG 95 % s přehlednou stránkou nastavení.';
        }
    }
    return ;
} );

