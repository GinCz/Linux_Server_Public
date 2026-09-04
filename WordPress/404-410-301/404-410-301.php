<?php
/**
 * Plugin Name: 404-410-301 (SEO 404/410 + Auto-Redirect to Homepage) (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/404-410-301
 * Description: Ultra-lightweight SEO-compliant 404 handler by VladiMIR+AI. Returns true HTTP 404 Not Found status to search engines (Yandex, Google) for instant deindexing while smoothly redirecting visitors to the homepage after 5 seconds with an interactive live countdown.
 * Version:     2026.09.04
 * Author:      VladiMIR+AI (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Text Domain: 404-410-301
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Intercept 404 errors and render SEO-compliant 404 stub with auto-redirect
add_action( 'template_redirect', function() {
    if ( ! is_404() ) {
        return;
    }

    // 1. Send strict HTTP 404 Not Found header for SEO bots
    status_header( 404 );
    nocache_headers();

    // 2. Determine language (RU / CS / EN)
    $locale = function_exists( 'get_locale' ) ? get_locale() : 'en_US';
    $lang = strtolower( substr( $locale, 0, 2 ) );

    $site_name = get_bloginfo( 'name' );
    $home_url  = esc_url( home_url( '/' ) );

    if ( 'ru' === $lang ) {
        $t_title       = '404 — Страница не найдена';
        $t_subtitle    = 'Запрашиваемый адрес не существует или был удалён';
        $t_redirecting = 'Через <b id="timer">5</b> сек. вы перейдёте на главную страницу';
        $t_button      = 'Перейти на главную сейчас';
        $t_cancel      = 'Остаться на этой странице';
    } elseif ( 'cs' === $lang ) {
        $t_title       = '404 — Stránka nenalezena';
        $t_subtitle    = 'Požadovaná stránka neexistuje nebo byla odstraněna';
        $t_redirecting = 'Za <b id="timer">5</b> sekund budete přesměrováni na hlavní stránku';
        $t_button      = 'Přejít na hlavní stránku';
        $t_cancel      = 'Zůstat na této stránce';
    } else {
        $t_title       = '404 — Page Not Found';
        $t_subtitle    = 'The requested URL does not exist or has been removed';
        $t_redirecting = 'You will be redirected to the homepage in <b id="timer">5</b> seconds';
        $t_button      = 'Go to Homepage Now';
        $t_cancel      = 'Stay on this page';
    }

    // 3. Render ultra-lightweight standalone responsive HTML stub by VladiMIR+AI
    ?>
<!DOCTYPE html>
<html lang="<?php echo esc_attr( $lang ); ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow, noarchive">
    <meta http-equiv="refresh" content="5;url=<?php echo $home_url; ?>">
    <title><?php echo esc_html( $t_title . ' — ' . $site_name ); ?></title>
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
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid var(--border);
            border-radius: 20px;
            padding: 48px 36px;
            max-width: 520px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 40px rgba(0,0,0,0.25);
        }
        .badge {
            display: inline-block;
            background: var(--badge-bg);
            color: var(--badge-text);
            font-size: 14px;
            font-weight: 700;
            padding: 6px 14px;
            border-radius: 9999px;
            margin-bottom: 20px;
            letter-spacing: 0.5px;
        }
        h1 {
            font-size: 28px;
            font-weight: 800;
            margin-bottom: 12px;
            line-height: 1.25;
        }
        p.subtitle {
            color: var(--text-muted);
            font-size: 15px;
            margin-bottom: 24px;
            line-height: 1.5;
        }
        .redirect-box {
            background: rgba(0, 0, 0, 0.15);
            border-radius: 12px;
            padding: 14px 18px;
            margin-bottom: 28px;
            font-size: 14px;
            color: var(--text-muted);
        }
        .redirect-box b {
            color: var(--accent);
            font-size: 16px;
        }
        .progress-bar-bg {
            height: 4px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 2px;
            overflow: hidden;
            margin-top: 10px;
        }
        .progress-bar {
            height: 100%;
            width: 100%;
            background: var(--accent);
            animation: progress 5s linear forwards;
        }
        @keyframes progress {
            from { width: 100%; }
            to { width: 0%; }
        }
        .btn-group {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 13px 24px;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s ease;
            cursor: pointer;
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
            font-size: 13px;
            border: none;
        }
        .btn-link:hover {
            color: var(--text);
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">HTTP 404 NOT FOUND</div>
        <h1><?php echo esc_html( $t_title ); ?></h1>
        <p class="subtitle"><?php echo esc_html( $t_subtitle ); ?></p>
        
        <div class="redirect-box">
            <span><?php echo $t_redirecting; ?></span>
            <div class="progress-bar-bg">
                <div class="progress-bar" id="pbar"></div>
            </div>
        </div>

        <div class="btn-group">
            <a href="<?php echo $home_url; ?>" class="btn btn-primary"><?php echo esc_html( $t_button ); ?> ↗</a>
            <button onclick="stopTimer()" class="btn btn-link" id="cancel-btn"><?php echo esc_html( $t_cancel ); ?></button>
        </div>
    </div>

    <script>
        let timeLeft = 5;
        const timerElem = document.getElementById('timer');
        const pbarElem = document.getElementById('pbar');
        const cancelBtn = document.getElementById('cancel-btn');
        let timerId = null;

        function countdown() {
            timeLeft--;
            if (timeLeft <= 0) {
                window.location.href = "<?php echo $home_url; ?>";
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
                if (rbox) rbox.textContent = '<?php echo 'ru' === $lang ? 'Автоматический переход отменён' : ('cs' === $lang ? 'Automatické přesměrování zrušeno' : 'Auto-redirect canceled'); ?>';
            }
        }
    </script>
</body>
</html>
    <?php
    exit;
}, 1 );

// Multilingual plugin metadata (EN / CS / RU)
add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = '404-410-301 (SEO 404/410 + Авто-переход на Главную) (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Сверхлёгкий SEO-совместимый обработчик 404 ошибок от VladiMIR+AI. Отдаёт строгий код HTTP 404 Not Found поисковым роботам (Яндекс/Google) для мгновенного удаления мёртвых ссылок из индекса, а посетителей через 5 секунд с таймером плавно перенаправляет на главную страницу. 0 запросов к БД, 0 логов, максимальная скорость.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = '404-410-301 (SEO 404/410 + Auto-přesměrování na Hlavní) (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Ultralehký SEO kompatibilní modul pro obsluhu chyb 404 od VladiMIR+AI. Poskytuje striktní kód HTTP 404 Not Found pro vyhledávače (Google, Seznam) a návštěvníky po 5 sekundách s odpočtem automaticky přesměruje na hlavní stránku. 0 dotazů do DB, nulová zátěž.';
        }
    }
    return $plugins;
} );
