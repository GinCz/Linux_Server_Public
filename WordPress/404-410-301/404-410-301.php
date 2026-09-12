<?php
/**
 * Plugin Name: 404-410-301 (SEO 404/410 + Auto-Redirect to Homepage) (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/404-410-301
 * Description: Ultra-lightweight SEO-compliant 404 handler by VladiMIR+AI. Returns true HTTP 404 Not Found status to search engines (Yandex, Google) for instant deindexing while smoothly redirecting visitors to the homepage after 5 seconds with an interactive live countdown.
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
     = array(
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
     = get_option( '_vladimir_404_settings', array() );
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

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-404-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/404-410-301" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
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

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_404_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = '404-410-301: Настройки автоперехода';
                = 'Управление кодом HTTP 404/410, временем таймера и перенаправлением посетителей на главную страницу.';
               = 'Настройки успешно сохранены!';
              = 'HTTP статус ответа';
         = '404 (Not Found) — стандартный код для поисковиков; 410 (Gone) — для ускоренного удаления удаленных страниц из индекса.';
               = 'Время таймера (секунды)';
          = 'Количество секунд до перехода (0 — мгновенный переход без показа страницы, по умолчанию 5).';
                 = 'Целевой URL перехода';
            = 'Оставьте пустым для перехода на главную страницу сайта (' . home_url( '/' ) . ').';
              = 'Кнопка «Остаться на странице»';
         = 'Позволяет посетителю остановить таймер и остаться на странице 404.';
          = 'Кастомизация текстов (необязательно)';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = '404-410-301: Nastavení přesměrování';
                = 'Správa stavového kódu HTTP 404/410, času odpočtu a přesměrování návštěvníků na hlavní stránku.';
               = 'Nastavení bylo úspěšně uloženo!';
              = 'HTTP stavový kód';
         = '404 (Not Found) pro standardní vyhledávače; 410 (Gone) pro okamžité odstranění z indexu.';
               = 'Doba odpočtu (sekundy)';
          = 'Počet sekund do přesměrování (0 = okamžité bez zobrazení stránky, výchozí 5).';
                 = 'Cílová URL přesměrování';
            = 'Ponechte prázdné pro hlavní stránku webu (' . home_url( '/' ) . ').';
              = 'Tlačítko „Zůstat na stránce“';
         = 'Umožňuje návštěvníkovi zastavit odpočet a zůstat na stránce.';
          = 'Vlastní texty (volitelné)';
            = 'Uložit nastavení';
    } else {
               = '404-410-301: Auto-Redirect Settings';
                = 'Manage HTTP 404/410 status code, countdown timer, and visitor redirection.';
               = 'Settings successfully saved!';
              = 'HTTP Status Code';
         = '404 (Not Found) for search engines; 410 (Gone) for permanently deleted URLs.';
               = 'Countdown Duration (seconds)';
          = 'Seconds before redirect (0 = immediate without page display, default 5).';
                 = 'Destination Redirect URL';
            = 'Leave empty for site homepage (' . home_url( '/' ) . ').';
              = 'Show "Stay on this page" button';
         = 'Allows visitors to cancel the timer and stay on the page.';
          = 'Custom Headings (Optional)';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🔄 <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_404_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_404_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="status_code"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <select name="status_code" id="status_code">
                            <option value="404" <?php selected( ['status_code'], 404 ); ?>>404 Not Found</option>
                            <option value="410" <?php selected( ['status_code'], 410 ); ?>>410 Gone (Permanently Removed)</option>
                        </select>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="countdown"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="number" name="countdown" id="countdown" min="0" max="60" value="<?php echo esc_attr( ['countdown'] ); ?>" class="small-text">
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="redirect_url"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="url" name="redirect_url" id="redirect_url" value="<?php echo esc_attr( ['redirect_url'] ); ?>" class="regular-text" placeholder="<?php echo esc_url( home_url( '/' ) ); ?>">
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="allow_cancel" value="1" <?php checked( ['allow_cancel'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
            </table>

            <h3 style="margin-top:25px;border-top:1px solid #e2e8f0;padding-top:15px;"><?php echo esc_html(  ); ?></h3>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row">RU: Заголовок / Подзаголовок</th>
                    <td>
                        <input type="text" name="custom_title_ru" value="<?php echo esc_attr( ['custom_title_ru'] ); ?>" class="regular-text" placeholder="404 — Страница не найдена"><br><br>
                        <input type="text" name="custom_subtitle_ru" value="<?php echo esc_attr( ['custom_subtitle_ru'] ); ?>" class="large-text" placeholder="Запрашиваемый адрес не существует или был удалён">
                    </td>
                </tr>
                <tr>
                    <th scope="row">CS: Titulek / Podtitulek</th>
                    <td>
                        <input type="text" name="custom_title_cs" value="<?php echo esc_attr( ['custom_title_cs'] ); ?>" class="regular-text" placeholder="404 — Stránka nenalezena"><br><br>
                        <input type="text" name="custom_subtitle_cs" value="<?php echo esc_attr( ['custom_subtitle_cs'] ); ?>" class="large-text" placeholder="Požadovaná stránka neexistuje nebo byla odstraněna">
                    </td>
                </tr>
                <tr>
                    <th scope="row">EN: Title / Subtitle</th>
                    <td>
                        <input type="text" name="custom_title_en" value="<?php echo esc_attr( ['custom_title_en'] ); ?>" class="regular-text" placeholder="404 — Page Not Found"><br><br>
                        <input type="text" name="custom_subtitle_en" value="<?php echo esc_attr( ['custom_subtitle_en'] ); ?>" class="large-text" placeholder="The requested URL does not exist or has been removed">
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
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

     = array(
        'status_code'        => in_array( (int) ( ['status_code'] ?? 404 ), array( 404, 410 ), true ) ? (int) ['status_code'] : 404,
        'countdown'          => max( 0, min( 60, (int) ( ['countdown'] ?? 5 ) ) ),
        'redirect_url'       => esc_url_raw( trim( (string) ( ['redirect_url'] ?? '' ) ) ),
        'allow_cancel'       => isset( ['allow_cancel'] ) ? 1 : 0,
        'custom_title_ru'    => sanitize_text_field( (string) ( ['custom_title_ru'] ?? '' ) ),
        'custom_subtitle_ru' => sanitize_text_field( (string) ( ['custom_subtitle_ru'] ?? '' ) ),
        'custom_title_cs'    => sanitize_text_field( (string) ( ['custom_title_cs'] ?? '' ) ),
        'custom_subtitle_cs' => sanitize_text_field( (string) ( ['custom_subtitle_cs'] ?? '' ) ),
        'custom_title_en'    => sanitize_text_field( (string) ( ['custom_title_en'] ?? '' ) ),
        'custom_subtitle_en' => sanitize_text_field( (string) ( ['custom_subtitle_en'] ?? '' ) ),
    );

    update_option( '_vladimir_404_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-404-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. FRONTEND 404 INTERCEPTOR & REDIRECTOR
// ─────────────────────────────────────────────

add_action( 'template_redirect', function() {
    if ( ! is_404() ) {
        return;
    }

      = vladimir_404_get_settings();
        = (int) ['status_code'];
     = (int) ['countdown'];
      = ! empty( ['redirect_url'] ) ? esc_url( ['redirect_url'] ) : esc_url( home_url( '/' ) );

    // If countdown is 0, execute immediate redirect
    if ( 0 ===  ) {
        wp_safe_redirect( , 301 );
        exit;
    }

    // 1. Send HTTP 404 or 410 header for SEO bots
    status_header(  );
    nocache_headers();

    // 2. Determine language (RU / CS / EN)
     = function_exists( 'get_locale' ) ? get_locale() : 'en_US';
       = strtolower( substr( , 0, 2 ) );
     = get_bloginfo( 'name' );

    if ( 'ru' ===  ) {
               = ! empty( ['custom_title_ru'] ) ? ['custom_title_ru'] : '404 — Страница не найдена';
            = ! empty( ['custom_subtitle_ru'] ) ? ['custom_subtitle_ru'] : 'Запрашиваемый адрес не существует или был удалён';
         = 'Через <b id="timer">' .  . '</b> сек. вы перейдёте на главную страницу';
              = 'Перейти на главную сейчас';
              = 'Остаться на этой странице';
    } elseif ( 'cs' ===  ) {
               = ! empty( ['custom_title_cs'] ) ? ['custom_title_cs'] : '404 — Stránka nenalezena';
            = ! empty( ['custom_subtitle_cs'] ) ? ['custom_subtitle_cs'] : 'Požadovaná stránka neexistuje nebo byla odstraněna';
         = 'Za <b id="timer">' .  . '</b> sekund budete přesměrováni na hlavní stránku';
              = 'Přejít na hlavní stránku';
              = 'Zůstat na této stránce';
    } else {
               = ! empty( ['custom_title_en'] ) ? ['custom_title_en'] : '404 — Page Not Found';
            = ! empty( ['custom_subtitle_en'] ) ? ['custom_subtitle_en'] : 'The requested URL does not exist or has been removed';
         = 'You will be redirected to the homepage in <b id="timer">' .  . '</b> seconds';
              = 'Go to Homepage Now';
              = 'Stay on this page';
    }

     = ( 410 ===  ) ? 'HTTP 410 GONE' : 'HTTP 404 NOT FOUND';
    ?>
<!DOCTYPE html>
<html lang="<?php echo esc_attr(  ); ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow, noarchive">
    <meta http-equiv="refresh" content="<?php echo ; ?>;url=<?php echo ; ?>">
    <title><?php echo esc_html(  . ' — ' .  ); ?></title>
    <style>
        :root {
            --bg: #0f172a;
            --card-bg: rgba(30, 41, 59, 0.75);
            --border: rgba(255, 255, 255, 0.1);
            --text: #f8fafc;
            --text-muted: #94a3b8;
            --accent: #3b82f6;
            --accent-hover: #2563eb;
            --badge-bg: rgba(239, 68, 68, 0.15);
            --badge-text: #f87171;
        }
        @media (prefers-color-scheme: light) {
            :root {
                --bg: #f1f5f9;
                --card-bg: rgba(255, 255, 255, 0.85);
                --border: rgba(0, 0, 0, 0.08);
                --text: #0f172a;
                --text-muted: #64748b;
                --accent: #2563eb;
                --accent-hover: #1d4ed8;
                --badge-bg: rgba(239, 68, 68, 0.1);
                --badge-text: #dc2626;
            }
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .card {
            background: var(--card-bg);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 40px;
            max-width: 480px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.2);
            animation: fadeIn 0.4s ease-out;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .badge {
            display: inline-block;
            background: var(--badge-bg);
            color: var(--badge-text);
            padding: 6px 14px;
            border-radius: 9999px;
            font-size: 0.85rem;
            font-weight: 700;
            letter-spacing: 0.05em;
            margin-bottom: 20px;
        }
        h1 {
            font-size: 1.6rem;
            font-weight: 700;
            margin-bottom: 10px;
            line-height: 1.3;
        }
        p.subtitle {
            color: var(--text-muted);
            font-size: 0.95rem;
            margin-bottom: 30px;
            line-height: 1.5;
        }
        .redirect-box {
            background: rgba(0, 0, 0, 0.05);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 30px;
            font-size: 0.9rem;
        }
        .progress-bar-bg {
            height: 4px;
            background: rgba(0, 0, 0, 0.1);
            border-radius: 2px;
            margin-top: 12px;
            overflow: hidden;
        }
        .progress-bar {
            height: 100%;
            background: var(--accent);
            width: 100%;
            transform-origin: left;
            animation: drain <?php echo ; ?>s linear forwards;
        }
        @keyframes drain {
            from { transform: scaleX(1); }
            to { transform: scaleX(0); }
        }
        .btn-group {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 12px 24px;
            border-radius: 10px;
            font-size: 0.95rem;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.2s ease;
            border: none;
        }
        .btn-primary {
            background: var(--accent);
            color: #ffffff;
        }
        .btn-primary:hover {
            background: var(--accent-hover);
            transform: translateY(-1px);
        }
        .btn-link {
            background: transparent;
            color: var(--text-muted);
        }
        .btn-link:hover {
            color: var(--text);
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="badge"><?php echo esc_html(  ); ?></div>
        <h1><?php echo esc_html(  ); ?></h1>
        <p class="subtitle"><?php echo esc_html(  ); ?></p>
        
        <div class="redirect-box">
            <span><?php echo ; ?></span>
            <div class="progress-bar-bg">
                <div class="progress-bar" id="pbar"></div>
            </div>
        </div>

        <div class="btn-group">
            <a href="<?php echo ; ?>" class="btn btn-primary"><?php echo esc_html(  ); ?> ↗</a>
            <?php if ( ! empty( ['allow_cancel'] ) ) : ?>
                <button onclick="stopTimer()" class="btn btn-link" id="cancel-btn"><?php echo esc_html(  ); ?></button>
            <?php endif; ?>
        </div>
    </div>

    <script>
        let timeLeft = <?php echo ; ?>;
        const timerElem = document.getElementById('timer');
        const pbarElem = document.getElementById('pbar');
        const cancelBtn = document.getElementById('cancel-btn');
        let timerId = null;

        function countdown() {
            timeLeft--;
            if (timeLeft <= 0) {
                window.location.href = "<?php echo ; ?>";
            } else {
                if (timerElem) timerElem.textContent = timeLeft;
            }
        }

        timerId = setInterval(countdown, 1000);

        function stopTimer() {
            if (timerId) {
                clearInterval(timerId);
                timerId = null;
                if (pbarElem) pbarElem.style.animationPlayState = 'paused';
                if (cancelBtn) cancelBtn.style.display = 'none';
                const rbox = document.querySelector('.redirect-box span');
                if (rbox) rbox.textContent = '<?php echo 'ru' ===  ? 'Автоматический переход отменён' : ('cs' ===  ? 'Automatické přesměrování zrušeno' : 'Auto-redirect canceled'); ?>';
            }
        }
    </script>
</body>
</html>
    <?php
    exit;
}, 1 );

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = '404-410-301 (SEO 404/410 + Авто-переход на Главную) (VladiMIR+AI)';
            [  ]['Description'] = 'Сверхлёгкий SEO-совместимый обработчик 404 ошибок от VladiMIR+AI. Отдаёт строгий код HTTP 404 Not Found поисковым роботам (Яндекс/Google) для мгновенного удаления мёртвых ссылок из индекса, а посетителей с таймером плавно перенаправляет на главную страницу. Включает панель настроек на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = '404-410-301 (SEO 404/410 + Auto-přesměrování na Hlavní) (VladiMIR+AI)';
            [  ]['Description'] = 'Ultralehký SEO kompatibilní modul pro obsluhu chyb 404 od VladiMIR+AI. Poskytuje striktní kód HTTP 404 Not Found pro vyhledávače (Google, Seznam) a návštěvníky po zadaném odpočtu automaticky přesměruje na hlavní stránku.';
        }
    }
    return ;
} );

