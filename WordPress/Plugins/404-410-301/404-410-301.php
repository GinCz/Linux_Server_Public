<?php
/**
 * Plugin Name: 404-410-301 (SEO 404/410 + Auto-Redirect & Maintenance Mode) (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/404-410-301
 * Description: Ultra-lightweight SEO-compliant 404/410 handler and Maintenance Mode with auto-redirect. Returns true HTTP 404/410 or 503 status to search engines while smoothly redirecting visitors to the homepage or custom URL after a customizable countdown.
 * Version:     2026-10__1.32
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/404-410-301
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: 404-410-301
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Shared auto-update client (private GitHub repository, see WordPress/README.md).
if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

// Shared plugin-list translations (8 languages, see WordPress/README.md).
if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-i18n.php';
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_404_get_settings() {
    $defaults = array(
        // 404 / 410 settings
        'status_code'              => 404,
        'countdown'                => 5,
        'redirect_url'             => '',
        'allow_cancel'             => 1,

        // Maintenance Mode settings
        'maintenance_mode'         => 0,
        'maintenance_status_code'  => 503,
        'maintenance_countdown'    => 5,
        'maintenance_redirect_url' => '',
        'maintenance_allow_cancel' => 1,
    );
    $saved = get_option( '_vladimir_404_settings', array() );
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-404-settings' ) ) . '" style="white-space:nowrap;">' . esc_html( $settings_label ) . '</a>';
    $docs_link     = '<a href="https://github.com/GinCz/plugins/tree/main/404-410-301" target="_blank" style="white-space:nowrap;">' . esc_html( $docs_label ) . '</a>';

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
        '404-410-301 (VladiMIR+AI✅)',
        '🔀 404-410-301',
        'manage_options',
        'vladimir-404-settings',
        'vladimir_404_render_settings_page'
    );
} );

function vladimir_404_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_404_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title          = '404-410-301: Настройки обработки страниц и режима обслуживания';
        $txt_subtitle       = 'Управление ошибками 404/410 и режимом «Сайт в разработке» с умной плавной переадресацией посетителей.';
        $txt_saved          = 'Настройки успешно сохранены!';

        // Maintenance section
        $txt_maint_sec      = '🛠️ Режим «Сайт в разработке / Обслуживание» (Maintenance Mode)';
        $txt_maint_enable   = 'Включить режим «Сайт в разработке»';
        $txt_maint_desc     = 'Когда включено, все неавторизованные посетители видят страницу обслуживания и перенаправляются на указанный URL. Администраторы видят сайт в обычном режиме.';
        $txt_maint_url      = 'URL для перенаправления в режиме обслуживания';
        $txt_maint_url_desc = 'Куда перенаправлять посетителей (например, партнерский сайт). Оставьте пустым для перехода на главную (' . home_url( '/' ) . ').';
        $txt_maint_code     = 'HTTP Статус код для обслуживания';
        $txt_maint_code_d   = '503 — рекомендуется для временного обслуживания (не вредит SEO в Google/Яндекс). 200 — стандартный ответ. 302 — временный редирект.';
        $txt_maint_count    = 'Время до автопереадресации (секунды)';
        $txt_maint_count_d  = '0 — мгновенно перенаправлять; от 1 до 60 — с таймером обратного отсчета (по умолчанию: 5).';
        $txt_maint_cancel   = 'Разрешить посетителю отменить переадресацию';

        // 404/410 section
        $txt_404_sec        = '🔀 Обработка несуществующих страниц (404 / 410 Error Pages)';
        $txt_code_label     = 'HTTP Статус код для поисковых ботов';
        $txt_code_desc      = '404 (Not Found) — стандартно. 410 (Gone) — страница удалена навсегда.';
        $txt_count_label    = 'Время до автопереадресации (секунды)';
        $txt_count_desc     = '0 — мгновенно перенаправлять; от 1 до 60 — с таймером обратного отсчета (по умолчанию: 5).';
        $txt_url_label      = 'URL для перенаправления при 404/410';
        $txt_url_desc       = 'Оставьте пустым для перехода на главную страницу сайта (' . home_url( '/' ) . ').';
        $txt_cancel_label   = 'Разрешить посетителю отменить автопереадресацию';
        $txt_cancel_desc    = 'Показывает кнопку «Остаться на странице» рядом с таймером.';
        $txt_save_btn       = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title          = '404-410-301: Nastavení chybových stránek a režimu údržby';
        $txt_subtitle       = 'Správa chyb 404/410 a režimu «Web ve výstavbě» s plynulým přesměrováním.';
        $txt_saved          = 'Nastavení bylo úspěšně uloženo!';

        $txt_maint_sec      = '🛠️ Režim «Web ve výstavbě / Údržba» (Maintenance Mode)';
        $txt_maint_enable   = 'Aktivovat režim «Web ve výstavbě»';
        $txt_maint_desc     = 'Návštěvníci uvidí stránku údržby s odpočtem a přesměrováním. Administrátoři mají plný přístup.';
        $txt_maint_url      = 'Cílová URL přesměrování při údržbě';
        $txt_maint_url_desc = 'Kam přesměrovat návštěvníky. Nechte prázdné pro úvodní stránku (' . home_url( '/' ) . ').';
        $txt_maint_code     = 'HTTP Stavový kód pro údržbu';
        $txt_maint_code_d   = '503 (Doporučeno pro SEO) nebo 200.';
        $txt_maint_count    = 'Čas do přesměrování (sekundy)';
        $txt_maint_count_d  = '0 pro okamžité přesměrování; 1–60 s odpočtem (výchozí: 5).';
        $txt_maint_cancel   = 'Povolit zrušení přesměrování';

        $txt_404_sec        = '🔀 Nastavení chybových stránek (404 / 410)';
        $txt_code_label     = 'HTTP Stavový kód pro vyhledávače';
        $txt_code_desc      = '404 (Nenalezeno) nebo 410 (Trvale odstraněno).';
        $txt_count_label    = 'Čas do přesměrování (sekundy)';
        $txt_count_desc     = '0 pro okamžité přesměrování; 1–60 s odpočtem (výchozí: 5).';
        $txt_url_label      = 'Cílová URL přesměrování';
        $txt_url_desc       = 'Nechte prázdné pro přesměrování na úvodní stránku (' . home_url( '/' ) . ').';
        $txt_cancel_label   = 'Povolit zrušení přesměrování';
        $txt_cancel_desc    = 'Zobrazí tlačítko „Zůstat na stránce“.';
        $txt_save_btn       = 'Uložit nastavení';
    } else {
        $txt_title          = '404-410-301: Error Pages & Maintenance Mode Settings';
        $txt_subtitle       = 'Manage 404/410 errors and Site Under Construction / Maintenance mode with smart auto-redirects.';
        $txt_saved          = 'Settings successfully saved!';

        $txt_maint_sec      = '🛠️ Site Under Construction / Maintenance Mode';
        $txt_maint_enable   = 'Enable "Site Under Construction" Mode';
        $txt_maint_desc     = 'When enabled, public visitors see a maintenance card and are redirected. Administrators have full access.';
        $txt_maint_url      = 'Maintenance Redirect URL';
        $txt_maint_url_desc = 'Target redirect URL during maintenance. Leave empty for homepage (' . home_url( '/' ) . ').';
        $txt_maint_code     = 'HTTP Status Code for Maintenance';
        $txt_maint_code_d   = '503 (Recommended for SEO) or 200 / 302.';
        $txt_maint_count    = 'Countdown Duration (Seconds)';
        $txt_maint_count_d  = '0 for immediate redirect; 1–60 with live countdown (default: 5).';
        $txt_maint_cancel   = 'Allow Visitor to Cancel Redirect';

        $txt_404_sec        = '🔀 Non-Existent Pages (404 / 410 Error Pages)';
        $txt_code_label     = 'HTTP Status Code for Search Bots';
        $txt_code_desc      = '404 (Not Found) or 410 (Gone).';
        $txt_count_label    = 'Countdown Duration (Seconds)';
        $txt_count_desc     = '0 for immediate redirect; 1–60 with live countdown (default: 5).';
        $txt_url_label      = '404/410 Redirect Target URL';
        $txt_url_desc       = 'Leave empty to redirect to homepage (' . home_url( '/' ) . ').';
        $txt_cancel_label   = 'Allow Visitor to Cancel Redirect';
        $txt_cancel_desc    = 'Shows a "Stay on Page" button next to countdown.';
        $txt_save_btn       = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
            <span>🛡️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI✅ v2026-10__1.32)</span>
            <?php if ( ! empty( $settings['maintenance_mode'] ) ) : ?>
                <span style="font-size:12px;background:#d97706;color:#fff;padding:3px 10px;border-radius:12px;font-weight:700;">⚠️ MAINTENANCE ACTIVE</span>
            <?php endif; ?>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px 28px;border:1px solid #ccd0d4;border-radius:10px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_404_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_404_settings">

            <!-- SECTION 1: MAINTENANCE MODE -->
            <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:18px 20px;margin-bottom:24px;">
                <h2 style="font-size:16px;margin-top:0;margin-bottom:12px;color:#0f172a;display:flex;align-items:center;gap:8px;">
                    <?php echo esc_html( $txt_maint_sec ); ?>
                </h2>

                <table class="form-table" role="presentation" style="margin-top:0;">
                    <tr>
                        <th scope="row"><strong><?php echo esc_html( $txt_maint_enable ); ?></strong></th>
                        <td>
                            <label style="display:inline-flex;align-items:center;gap:8px;font-weight:600;color:<?php echo ! empty( $settings['maintenance_mode'] ) ? '#b45309' : 'inherit'; ?>;">
                                <input type="checkbox" name="maintenance_mode" value="1" <?php checked( $settings['maintenance_mode'], 1 ); ?>>
                                <?php echo esc_html( $txt_maint_enable ); ?>
                            </label>
                            <p class="description" style="margin-top:4px;"><?php echo esc_html( $txt_maint_desc ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="maintenance_redirect_url"><strong><?php echo esc_html( $txt_maint_url ); ?></strong></label></th>
                        <td>
                            <input type="url" name="maintenance_redirect_url" id="maintenance_redirect_url" value="<?php echo esc_attr( $settings['maintenance_redirect_url'] ); ?>" class="regular-text" placeholder="https://..." style="width:100%;">
                            <p class="description"><?php echo esc_html( $txt_maint_url_desc ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="maintenance_status_code"><strong><?php echo esc_html( $txt_maint_code ); ?></strong></label></th>
                        <td>
                            <select name="maintenance_status_code" id="maintenance_status_code" style="min-width:240px;">
                                <option value="503" <?php selected( $settings['maintenance_status_code'], 503 ); ?>>503 Service Unavailable (Recommended)</option>
                                <option value="200" <?php selected( $settings['maintenance_status_code'], 200 ); ?>>200 OK</option>
                                <option value="302" <?php selected( $settings['maintenance_status_code'], 302 ); ?>>302 Found (Temporary Redirect)</option>
                            </select>
                            <p class="description"><?php echo esc_html( $txt_maint_code_d ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="maintenance_countdown"><strong><?php echo esc_html( $txt_maint_count ); ?></strong></label></th>
                        <td>
                            <input type="number" name="maintenance_countdown" id="maintenance_countdown" value="<?php echo esc_attr( $settings['maintenance_countdown'] ); ?>" min="0" max="60" style="width:90px;">
                            <span style="margin-left:5px;color:#64748b;">sec.</span>
                            <p class="description"><?php echo esc_html( $txt_maint_count_d ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><strong><?php echo esc_html( $txt_maint_cancel ); ?></strong></th>
                        <td>
                            <label>
                                <input type="checkbox" name="maintenance_allow_cancel" value="1" <?php checked( $settings['maintenance_allow_cancel'], 1 ); ?>>
                                <?php echo esc_html( $txt_cancel_desc ); ?>
                            </label>
                        </td>
                    </tr>
                </table>
            </div>

            <!-- SECTION 2: 404 / 410 ERROR PAGES -->
            <div style="background:#fff;border:1px solid #e2e8f0;border-radius:8px;padding:18px 20px;">
                <h2 style="font-size:16px;margin-top:0;margin-bottom:12px;color:#0f172a;display:flex;align-items:center;gap:8px;">
                    <?php echo esc_html( $txt_404_sec ); ?>
                </h2>

                <table class="form-table" role="presentation" style="margin-top:0;">
                    <tr>
                        <th scope="row"><label for="status_code"><strong><?php echo esc_html( $txt_code_label ); ?></strong></label></th>
                        <td>
                            <select name="status_code" id="status_code" style="min-width:240px;">
                                <option value="404" <?php selected( $settings['status_code'], 404 ); ?>>404 Not Found (default)</option>
                                <option value="410" <?php selected( $settings['status_code'], 410 ); ?>>410 Gone (permanently removed)</option>
                            </select>
                            <p class="description"><?php echo esc_html( $txt_code_desc ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="countdown"><strong><?php echo esc_html( $txt_count_label ); ?></strong></label></th>
                        <td>
                            <input type="number" name="countdown" id="countdown" value="<?php echo esc_attr( $settings['countdown'] ); ?>" min="0" max="60" style="width:90px;">
                            <span style="margin-left:5px;color:#64748b;">sec.</span>
                            <p class="description"><?php echo esc_html( $txt_count_desc ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="redirect_url"><strong><?php echo esc_html( $txt_url_label ); ?></strong></label></th>
                        <td>
                            <input type="url" name="redirect_url" id="redirect_url" value="<?php echo esc_attr( $settings['redirect_url'] ); ?>" class="regular-text" placeholder="<?php echo esc_attr( home_url( '/' ) ); ?>" style="width:100%;">
                            <p class="description"><?php echo esc_html( $txt_url_desc ); ?></p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><strong><?php echo esc_html( $txt_cancel_label ); ?></strong></th>
                        <td>
                            <label>
                                <input type="checkbox" name="allow_cancel" value="1" <?php checked( $settings['allow_cancel'], 1 ); ?>>
                                <?php echo esc_html( $txt_cancel_desc ); ?>
                            </label>
                        </td>
                    </tr>
                </table>
            </div>

            <div style="margin-top:24px;">
                <?php submit_button( $txt_save_btn, 'primary', 'submit', false, array( 'style' => 'padding: 6px 20px; font-size: 14px;' ) ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/404-410-301" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_404_settings', function() {
    check_admin_referer( 'vladimir_save_404_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $status_code              = isset( $_POST['status_code'] ) && 410 === (int) $_POST['status_code'] ? 410 : 404;
    $countdown                = isset( $_POST['countdown'] ) ? max( 0, min( 60, (int) $_POST['countdown'] ) ) : 5;
    $redirect_url             = isset( $_POST['redirect_url'] ) ? esc_url_raw( trim( (string) $_POST['redirect_url'] ) ) : '';
    $allow_cancel             = isset( $_POST['allow_cancel'] ) ? 1 : 0;

    $maintenance_mode         = isset( $_POST['maintenance_mode'] ) ? 1 : 0;
    $maint_code_raw           = isset( $_POST['maintenance_status_code'] ) ? (int) $_POST['maintenance_status_code'] : 503;
    $maintenance_status_code  = in_array( $maint_code_raw, array( 200, 302, 503 ), true ) ? $maint_code_raw : 503;
    $maintenance_countdown    = isset( $_POST['maintenance_countdown'] ) ? max( 0, min( 60, (int) $_POST['maintenance_countdown'] ) ) : 5;
    $maintenance_redirect_url = isset( $_POST['maintenance_redirect_url'] ) ? esc_url_raw( trim( (string) $_POST['maintenance_redirect_url'] ) ) : '';
    $maintenance_allow_cancel = isset( $_POST['maintenance_allow_cancel'] ) ? 1 : 0;

    $updated = array(
        'status_code'              => $status_code,
        'countdown'                => $countdown,
        'redirect_url'             => $redirect_url,
        'allow_cancel'             => $allow_cancel,
        'maintenance_mode'         => $maintenance_mode,
        'maintenance_status_code'  => $maintenance_status_code,
        'maintenance_countdown'    => $maintenance_countdown,
        'maintenance_redirect_url' => $maintenance_redirect_url,
        'maintenance_allow_cancel' => $maintenance_allow_cancel,
    );

    update_option( '_vladimir_404_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-404-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. CARD RENDERING HELPER (Clean Glassmorphic UI)
// ─────────────────────────────────────────────

function vladimir_404_render_card( $lang, $page_title, $code_display, $subtitle, $msg_part, $countdown, $sec_word, $target_url, $go_now, $allow_cancel, $btn_stay ) {
    $site_name = esc_html( get_bloginfo( 'name' ) );
    $t_url_esc = esc_url( $target_url );

    header( 'Content-Type: text/html; charset=utf-8' );
    ?>
    <!DOCTYPE html>
    <html lang="<?php echo esc_attr( $lang ); ?>">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="robots" content="noindex, nofollow">
        <title><?php echo esc_html( $page_title ); ?> — <?php echo $site_name; ?></title>
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
                color: #e2e8f0;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }
            .card {
                background: rgba(30, 41, 59, 0.85);
                backdrop-filter: blur(12px);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 20px;
                padding: 48px 36px;
                max-width: 540px;
                width: 100%;
                text-align: center;
                box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            }
            .code {
                font-size: 80px;
                font-weight: 800;
                line-height: 1;
                background: linear-gradient(135deg, #38bdf8 0%, #818cf8 100%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                margin-bottom: 14px;
            }
            h1 { font-size: 22px; font-weight: 700; color: #fff; margin-bottom: 12px; }
            p.sub { color: #94a3b8; font-size: 15px; line-height: 1.6; margin-bottom: 24px; }
            .timer-box {
                background: rgba(15, 23, 42, 0.6);
                border: 1px solid rgba(56, 189, 248, 0.2);
                border-radius: 12px;
                padding: 16px;
                margin-bottom: 28px;
                font-size: 15px;
                color: #cbd5e1;
            }
            .timer-num {
                display: inline-block;
                min-width: 28px;
                font-size: 22px;
                font-weight: 800;
                color: #38bdf8;
            }
            .btn-group { display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; }
            .btn {
                display: inline-block;
                padding: 12px 24px;
                border-radius: 10px;
                font-size: 14px;
                font-weight: 600;
                text-decoration: none;
                transition: all 0.2s;
                cursor: pointer;
                border: none;
            }
            .btn-primary { background: #38bdf8; color: #0f172a; }
            .btn-primary:hover { background: #7dd3fc; }
            .btn-secondary { background: rgba(255, 255, 255, 0.08); color: #cbd5e1; border: 1px solid rgba(255, 255, 255, 0.15); }
            .btn-secondary:hover { background: rgba(255, 255, 255, 0.15); color: #fff; }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="code"><?php echo esc_html( (string) $code_display ); ?></div>
            <h1><?php echo esc_html( $page_title ); ?></h1>
            <p class="sub"><?php echo esc_html( $subtitle ); ?></p>

            <div class="timer-box" id="timerBox">
                <?php echo esc_html( $msg_part ); ?> <span class="timer-num" id="count"><?php echo esc_html( (string) $countdown ); ?></span> <?php echo esc_html( $sec_word ); ?>
            </div>

            <div class="btn-group">
                <a href="<?php echo $t_url_esc; ?>" class="btn btn-primary"><?php echo esc_html( $go_now ); ?></a>
                <?php if ( $allow_cancel ) : ?>
                    <button type="button" class="btn btn-secondary" id="btnCancel"><?php echo esc_html( $btn_stay ); ?></button>
                <?php endif; ?>
            </div>
        </div>

        <script>
            (function() {
                var seconds = <?php echo (int) $countdown; ?>;
                var target = <?php echo wp_json_encode( $target_url, JSON_HEX_TAG | JSON_HEX_AMP | JSON_UNESCAPED_SLASHES ); ?>;
                var countEl = document.getElementById('count');
                var timerBox = document.getElementById('timerBox');
                var btnCancel = document.getElementById('btnCancel');
                var timer = null;

                function tick() {
                    seconds--;
                    if (countEl) { countEl.textContent = seconds; }
                    if (seconds <= 0) {
                        clearInterval(timer);
                        window.location.href = target;
                    }
                }

                timer = setInterval(tick, 1000);

                if (btnCancel) {
                    btnCancel.addEventListener('click', function() {
                        clearInterval(timer);
                        if (timerBox) {
                            timerBox.style.display = 'none';
                        }
                        btnCancel.style.display = 'none';
                    });
                }
            })();
        </script>
    </body>
    </html>
    <?php
}

// ─────────────────────────────────────────────
// 5. FRONTEND HANDLER: MAINTENANCE & 404 ENGINE
// ─────────────────────────────────────────────

add_action( 'template_redirect', function() {
    $settings = vladimir_404_get_settings();

    // ── 5.1 MAINTENANCE MODE HANDLER ──
    if ( ! empty( $settings['maintenance_mode'] ) ) {
        // Bypass for admin, cron, CLI, login screens
        if ( is_admin() || wp_doing_cron() || ( defined( 'WP_CLI' ) && WP_CLI ) ) {
            return;
        }

        global $pagenow;
        if ( 'wp-login.php' === $pagenow || 'async-upload.php' === $pagenow ) {
            return;
        }

        // Bypass for administrators & users who can manage options
        if ( is_user_logged_in() && current_user_can( 'manage_options' ) ) {
            return;
        }

        $code = (int) $settings['maintenance_status_code'];
        if ( ! in_array( $code, array( 200, 302, 503 ), true ) ) {
            $code = 503;
        }

        $countdown  = (int) $settings['maintenance_countdown'];
        $target_url = ! empty( $settings['maintenance_redirect_url'] ) ? $settings['maintenance_redirect_url'] : home_url( '/' );
        $allow_can  = ! empty( $settings['maintenance_allow_cancel'] );

        if ( 0 === $countdown ) {
            wp_redirect( $target_url, ( 302 === $code ? 302 : 307 ) );
            exit;
        }

        status_header( $code );
        nocache_headers();
        if ( 503 === $code ) {
            header( 'Retry-After: 600' );
        }

        $locale = function_exists( 'get_locale' ) ? get_locale() : 'en_US';
        $lang   = strtolower( substr( $locale, 0, 2 ) );

        if ( 'ru' === $lang ) {
            $title      = 'Сайт находится в разработке';
            $code_badge = (string) $code;
            $subtitle   = 'На сайте ведутся технические работы. Вы будете перенаправлены на актуальный ресурс.';
            $msg_part   = 'Перенаправление через';
            $sec_word   = 'сек.';
            $go_now     = 'Перейти сейчас';
            $btn_stay   = 'Остаться на странице';
        } elseif ( 'cs' === $lang ) {
            $title      = 'Web je v rekonstrukci';
            $code_badge = (string) $code;
            $subtitle   = 'Na webu probíhá technická údržba. Budete přesměrováni na aktuální web.';
            $msg_part   = 'Přesměrování za';
            $sec_word   = 'sek.';
            $go_now     = 'Přejít ihned';
            $btn_stay   = 'Zůstat na stránce';
        } else {
            $title      = 'Site Under Maintenance';
            $code_badge = (string) $code;
            $subtitle   = 'We are currently undergoing scheduled maintenance. You will be redirected shortly.';
            $msg_part   = 'Redirecting in';
            $sec_word   = 'sec.';
            $go_now     = 'Go Now';
            $btn_stay   = 'Stay on Page';
        }

        vladimir_404_render_card( $lang, $title, $code_badge, $subtitle, $msg_part, $countdown, $sec_word, $target_url, $go_now, $allow_can, $btn_stay );
        exit;
    }

    // ── 5.2 404 / 410 ERROR PAGES HANDLER ──
    if ( ! is_404() ) {
        return;
    }

    $code = ( 410 === (int) $settings['status_code'] ) ? 410 : 404;

    status_header( $code );
    nocache_headers();

    $countdown   = (int) $settings['countdown'];
    $target_url  = ! empty( $settings['redirect_url'] ) ? $settings['redirect_url'] : home_url( '/' );
    $allow_can   = ! empty( $settings['allow_cancel'] );

    if ( 0 === $countdown ) {
        wp_safe_redirect( $target_url, 301 );
        exit;
    }

    $locale = function_exists( 'get_locale' ) ? get_locale() : 'en_US';
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    if ( 'ru' === $lang ) {
        $title    = ( 410 === $code ) ? '410 — Страница удалена' : '404 — Страница не найдена';
        $subtitle = 'Запрошенная страница не существует или была перемещена.';
        $msg_part = 'Вы будете перенаправлены на главную через';
        $sec_word = 'сек.';
        $go_now   = 'Перейти сейчас';
        $btn_stay = 'Остаться на странице';
    } elseif ( 'cs' === $lang ) {
        $title    = ( 410 === $code ) ? '410 — Stránka byla odstraněna' : '404 — Stránka nenalezena';
        $subtitle = 'Požadovaná stránka neexistuje nebo byla přesunuta.';
        $msg_part = 'Budete přesměrováni na úvodní stránku za';
        $sec_word = 'sek.';
        $go_now   = 'Přejít ihned';
        $btn_stay = 'Zůstat na stránce';
    } else {
        $title    = ( 410 === $code ) ? '410 — Page Gone' : '404 — Page Not Found';
        $subtitle = 'The page you are looking for does not exist or has been moved.';
        $msg_part = 'You will be redirected to the homepage in';
        $sec_word = 'sec.';
        $go_now   = 'Go Now';
        $btn_stay = 'Stay on Page';
    }

    vladimir_404_render_card( $lang, $title, (string) $code, $subtitle, $msg_part, $countdown, $sec_word, $target_url, $go_now, $allow_can, $btn_stay );
    exit;
}, 1 );
