<?php
/**
 * Plugin Name: 404-410-301 (SEO 404/410 + Auto-Redirect to Homepage) (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/404-410-301
 * Description: Ultra-lightweight SEO-compliant 404/410 handler. Returns true HTTP 404/410 Not Found status to search engines (Yandex, Google) for instant deindexing while smoothly redirecting visitors to the homepage after a customizable countdown (default 5s).
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: 404-410-301
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_404_get_settings() {
    $defaults = array(
        'status_code'        => 404,
        'countdown'          => 5,
        'redirect_url'       => '',
        'allow_cancel'       => 1,
        'custom_title_ru'    => '',
        'custom_subtitle_ru' => '',
        'custom_title_cs'    => '',
        'custom_subtitle_cs' => '',
        'custom_title_en'    => '',
        'custom_subtitle_en' => '',
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-404-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/404-410-301" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        '404-410-301 (VladiMIR+AI)',
        '404-410-301',
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
        $txt_title        = '404-410-301: Настройки обработки несуществующих страниц';
        $txt_subtitle     = 'Модуль выдает честный HTTP 404/410 для поисковых роботов (Яндекс/Google) и плавно перенаправляет посетителей на главную.';
        $txt_saved        = 'Настройки успешно сохранены!';
        $txt_code_label   = 'HTTP Статус код для поисковых ботов';
        $txt_code_desc    = '404 (Not Found) — стандартно для удаления страниц. 410 (Gone) — страница удалена навсегда.';
        $txt_count_label  = 'Время до автопереадресации (секунды)';
        $txt_count_desc   = '0 — мгновенно перенаправлять; от 1 до 60 — с таймером обратного отсчета (по умолчанию: 5).';
        $txt_url_label    = 'URL для перенаправления';
        $txt_url_desc     = 'Оставьте пустым для перехода на главную страницу сайта (' . home_url( '/' ) . ').';
        $txt_cancel_label = 'Разрешить посетителю отменить автопереадресацию';
        $txt_cancel_desc  = 'Показывает кнопку «Остаться на странице» рядом с таймером.';
        $txt_save_btn     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title        = '404-410-301: Nastavení chybových stránek';
        $txt_subtitle     = 'Modul vrací korektní HTTP 404/410 pro vyhledávače a návštěvníky plynule přesměruje na hlavní stránku.';
        $txt_saved        = 'Nastavení bylo úspěšně uloženo!';
        $txt_code_label   = 'HTTP Stavový kód pro vyhledávače';
        $txt_code_desc    = '404 (Nenalezeno) nebo 410 (Trvale odstraněno).';
        $txt_count_label  = 'Čas do přesměrování (sekundy)';
        $txt_count_desc   = '0 pro okamžité přesměrování; 1–60 s odpočtem (výchozí: 5).';
        $txt_url_label    = 'Cílová URL přesměrování';
        $txt_url_desc     = 'Nechte prázdné pro přesměrování na úvodní stránku (' . home_url( '/' ) . ').';
        $txt_cancel_label = 'Povolit zrušení přesměrování';
        $txt_cancel_desc  = 'Zobrazí tlačítko „Zůstat na stránce“.';
        $txt_save_btn     = 'Uložit nastavení';
    } else {
        $txt_title        = '404-410-301: Error Pages & Auto-Redirect Settings';
        $txt_subtitle     = 'Returns true HTTP 404/410 headers for search bots and redirects human visitors smoothly with a live countdown.';
        $txt_saved        = 'Settings successfully saved!';
        $txt_code_label   = 'HTTP Status Code for Search Bots';
        $txt_code_desc    = '404 (Not Found) or 410 (Gone).';
        $txt_count_label  = 'Countdown Duration (Seconds)';
        $txt_count_desc   = '0 for immediate redirect; 1–60 with live countdown (default: 5).';
        $txt_url_label    = 'Redirect Target URL';
        $txt_url_desc     = 'Leave empty to redirect to homepage (' . home_url( '/' ) . ').';
        $txt_cancel_label = 'Allow Visitor to Cancel Redirect';
        $txt_cancel_desc  = 'Shows a "Stay on Page" button next to countdown.';
        $txt_save_btn     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🛡️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_404_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_404_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="status_code"><strong><?php echo esc_html( $txt_code_label ); ?></strong></label></th>
                    <td>
                        <select name="status_code" id="status_code" style="min-width:200px;">
                            <option value="404" <?php selected( $settings['status_code'], 404 ); ?>>404 Not Found (По умолчанию)</option>
                            <option value="410" <?php selected( $settings['status_code'], 410 ); ?>>410 Gone (Удалено навсегда)</option>
                        </select>
                        <p class="description"><?php echo esc_html( $txt_code_desc ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="countdown"><strong><?php echo esc_html( $txt_count_label ); ?></strong></label></th>
                    <td>
                        <input type="number" name="countdown" id="countdown" value="<?php echo esc_attr( $settings['countdown'] ); ?>" min="0" max="60" style="width:90px;">
                        <span style="margin-left:5px;color:#64748b;">сек.</span>
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

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save_btn, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/404-410-301" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_404_settings', function() {
    check_admin_referer( 'vladimir_save_404_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $status_code  = isset( $_POST['status_code'] ) && 410 === (int) $_POST['status_code'] ? 410 : 404;
    $countdown    = isset( $_POST['countdown'] ) ? max( 0, min( 60, (int) $_POST['countdown'] ) ) : 5;
    $redirect_url = isset( $_POST['redirect_url'] ) ? esc_url_raw( trim( (string) $_POST['redirect_url'] ) ) : '';
    $allow_cancel = isset( $_POST['allow_cancel'] ) ? 1 : 0;

    $updated = array(
        'status_code'  => $status_code,
        'countdown'    => $countdown,
        'redirect_url' => $redirect_url,
        'allow_cancel' => $allow_cancel,
    );

    update_option( '_vladimir_404_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-404-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. FRONTEND 404 HANDLER & COUNTDOWN ENGINE
// ─────────────────────────────────────────────

add_action( 'template_redirect', function() {
    if ( ! is_404() ) {
        return;
    }

    $settings = vladimir_404_get_settings();
    $code     = ( 410 === (int) $settings['status_code'] ) ? 410 : 404;

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
        <title><?php echo esc_html( $title ); ?> — <?php echo $site_name; ?></title>
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
                max-width: 520px;
                width: 100%;
                text-align: center;
                box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            }
            .code {
                font-size: 84px;
                font-weight: 800;
                line-height: 1;
                background: linear-gradient(135deg, #38bdf8 0%, #818cf8 100%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                margin-bottom: 12px;
            }
            h1 { font-size: 22px; font-weight: 700; color: #fff; margin-bottom: 12px; }
            p { color: #94a3b8; font-size: 15px; line-height: 1.6; margin-bottom: 24px; }
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
            <div class="code"><?php echo esc_html( (string) $code ); ?></div>
            <h1><?php echo esc_html( $title ); ?></h1>
            <p><?php echo esc_html( $subtitle ); ?></p>

            <div class="timer-box" id="timerBox">
                <?php echo esc_html( $msg_part ); ?> <span class="timer-num" id="count"><?php echo esc_html( (string) $countdown ); ?></span> <?php echo esc_html( $sec_word ); ?>
            </div>

            <div class="btn-group">
                <a href="<?php echo $t_url_esc; ?>" class="btn btn-primary"><?php echo esc_html( $go_now ); ?></a>
                <?php if ( $allow_can ) : ?>
                    <button type="button" class="btn btn-secondary" id="btnCancel"><?php echo esc_html( $btn_stay ); ?></button>
                <?php endif; ?>
            </div>
        </div>

        <script>
            (function() {
                var seconds = <?php echo (int) $countdown; ?>;
                var target = <?php echo json_encode( $target_url ); ?>;
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
    exit;
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
            $plugins[ $plugin_key ]['Name']        = '404-410-301 (SEO 404/410 + Переадресация на главную) (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Честная отдача HTTP 404/410 для поисковиков (Яндекс, Google) для быстрого удаления битых ссылок из индекса и плавная переадресация посетителей на главную страницу с таймером.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = '404-410-301 (SEO 404/410 + Přesměrování na úvod) (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Korektní HTTP 404/410 pro vyhledávače a plynulé přesměrování návštěvníků na úvodní stránku s odpočtem.';
        }
    }
    return $plugins;
} );
