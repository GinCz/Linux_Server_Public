<?php
/**
 * Plugin Name: Clean Head Meta & Anti-Fingerprint (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/clean-head-meta
 * Description: Cleans WordPress <head> clutter, removes generator version tags, strips obsolete XML-RPC pingback links and emoji scripts, and adds clean author and designer meta tags (VladiMIR).
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: clean-head-meta
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_clean_head_get_settings() {
     = array(
        'remove_generator'          => 1,
        'disable_xmlrpc'            => 1,
        'remove_rsd_wlw'            => 1,
        'remove_shortlink_rest'     => 1,
        'remove_oembed'             => 1,
        'disable_emojis'            => 1,
        'add_author_meta'           => 1,
        'author_name'               => 'VladiMIR',
        'clean_theme_pingback_html' => 1,
    );
     = get_option( '_vladimir_clean_head_settings', array() );
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

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-clean-head-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/clean-head-meta" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Clean Head Meta (VladiMIR+AI)',
        'Очистка Head Meta',
        'manage_options',
        'vladimir-clean-head-settings',
        'vladimir_clean_head_render_settings_page'
    );
} );

function vladimir_clean_head_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_clean_head_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'Очистка Head Meta & Защита от отпечатков: Настройки';
                = 'Удаление мусора, версий CMS и опасных ссылок из секции &lt;head&gt; для безопасности и ускорения сайта.';
               = 'Настройки успешно сохранены!';
                 = 'Скрывать версию WordPress (wp_generator)';
            = 'Удаляет метатег генератора с версией движка от ботов и сканеров уязвимостей.';
              = 'Блокировать XML-RPC пингбэки (pings_open)';
         = 'Защищает сайт от DDoS атак через пингбэки XML-RPC.';
             = 'Удалять устаревшие ссылки RSD и WLW Manifest';
            = 'Удаляет ссылки для устаревших клиентов блоггинга Windows Live Writer.';
          = 'Удалять ссылки shortlink и REST API link из &lt;head&gt;';
           = 'Удаляет лишние теги link rel="shortlink" и rel="https://api.w.org/".';
              = 'Удалять oEmbed discovery links';
         = 'Удаляет метаданные встраивания постов на внешних сайтах.';
              = 'Отключать скрипты и стили Emojis';
          = 'Экономит ~15 КБ сетевого трафика и устраняет лишний JS скрипт на каждой странице.';
              = 'Добавлять чистые метатеги Author и Designer';
         = 'Добавляет метатеги автора в начале &lt;head&gt;.';
         = 'Имя автора / разработчика:';
          = 'Вырезать теги pingback/profile из HTML темы';
          = 'Удаляет жестко прописанные разработчиками темы ссылки на pingback.';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'Vyčištění Head Meta & Ochrana soukromí: Nastavení';
                = 'Odstranění zbytečného kódu a verzí CMS ze sekce &lt;head&gt; pro vyšší bezpečnost a rychlost.';
               = 'Nastavení bylo úspěšně uloženo!';
                 = 'Skrýt verzi WordPressu (wp_generator)';
            = 'Odstraní meta tag generátoru před skenery.';
              = 'Blokovat XML-RPC pingbacky';
         = 'Chrání web před DDoS útoky přes pingback.';
             = 'Odstranit odkazy RSD a WLW Manifest';
            = 'Vyčistí zastaralé odkazy pro Live Writer.';
          = 'Odstranit shortlink a REST API link ze záhlaví';
           = 'Odstraní zbytečné link tagy ze sekce head.';
              = 'Odstranit oEmbed linky';
         = 'Vypne vkládání příspěvků do cizích webů.';
              = 'Vypnout načítání emotikonů (Emojis)';
          = 'Ušetří načítání zbytečného JS a CSS na každé stránce.';
              = 'Přidat čisté meta tagy Author a Designer';
         = 'Přidá meta tagy na začátek sekce &lt;head&gt;.';
         = 'Jméno autora / designéra:';
          = 'Odstranit pingback přímo z kódu šablony';
          = 'Filtruje pevně zadané linky pingback v šabloně.';
            = 'Uložit nastavení';
    } else {
               = 'Clean Head Meta & Anti-Fingerprint: Settings';
                = 'Remove CMS version, obsolete links, and clutter from &lt;head&gt; for speed and security.';
               = 'Settings successfully saved!';
                 = 'Hide WordPress Generator Version';
            = 'Strips generator meta tag from bots and vulnerability scanners.';
              = 'Block XML-RPC Pingbacks';
         = 'Protects website against XML-RPC DDoS amplification attacks.';
             = 'Remove RSD & WLW Manifest Links';
            = 'Cleans obsolete discovery links for desktop blogging clients.';
          = 'Remove Shortlink & REST Output Links from &lt;head&gt;';
           = 'Strips unnecessary link tags from document header.';
              = 'Remove oEmbed Discovery Links';
         = 'Disables oEmbed discovery meta tags.';
              = 'Disable WordPress Emoji Scripts and Styles';
          = 'Saves ~15 KB of JS/CSS requests on every single page load.';
              = 'Add Clean Author & Designer Meta Tags';
         = 'Outputs clean attribution tags at the very top of &lt;head&gt;.';
         = 'Author / Designer Name:';
          = 'Strip Theme Hardcoded Pingbacks from HTML';
          = 'Removes hardcoded pingback/profile links emitted by active theme.';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🛡️ <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_clean_head_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_clean_head_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="remove_generator" value="1" <?php checked( ['remove_generator'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_xmlrpc" value="1" <?php checked( ['disable_xmlrpc'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="remove_rsd_wlw" value="1" <?php checked( ['remove_rsd_wlw'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="remove_shortlink_rest" value="1" <?php checked( ['remove_shortlink_rest'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="remove_oembed" value="1" <?php checked( ['remove_oembed'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_emojis" value="1" <?php checked( ['disable_emojis'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="clean_theme_pingback_html" value="1" <?php checked( ['clean_theme_pingback_html'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><?php echo esc_html(  ); ?></th>
                    <td>
                        <label>
                            <input type="checkbox" name="add_author_meta" value="1" <?php checked( ['add_author_meta'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <br><br>
                        <label>
                            <strong><?php echo esc_html(  ); ?></strong>
                            <input type="text" name="author_name" value="<?php echo esc_attr( ['author_name'] ); ?>" class="regular-text" style="max-width:200px;">
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
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/clean-head-meta" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_clean_head_settings', function() {
    check_admin_referer( 'vladimir_save_clean_head_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'remove_generator'          => isset( ['remove_generator'] ) ? 1 : 0,
        'disable_xmlrpc'            => isset( ['disable_xmlrpc'] ) ? 1 : 0,
        'remove_rsd_wlw'            => isset( ['remove_rsd_wlw'] ) ? 1 : 0,
        'remove_shortlink_rest'     => isset( ['remove_shortlink_rest'] ) ? 1 : 0,
        'remove_oembed'             => isset( ['remove_oembed'] ) ? 1 : 0,
        'disable_emojis'            => isset( ['disable_emojis'] ) ? 1 : 0,
        'add_author_meta'           => isset( ['add_author_meta'] ) ? 1 : 0,
        'author_name'               => sanitize_text_field( (string) ( ['author_name'] ?? 'VladiMIR' ) ),
        'clean_theme_pingback_html' => isset( ['clean_theme_pingback_html'] ) ? 1 : 0,
    );

    update_option( '_vladimir_clean_head_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-clean-head-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. CLEANUP ENGINE HOOKS
// ─────────────────────────────────────────────

 = vladimir_clean_head_get_settings();

// 1. Remove generator
if ( ! empty( ['remove_generator'] ) ) {
    remove_action( 'wp_head', 'wp_generator' );
    add_filter( 'the_generator', '__return_empty_string' );
}

// 2. Disable XML-RPC pingbacks
if ( ! empty( ['disable_xmlrpc'] ) ) {
    add_filter( 'pings_open', '__return_false', 9999 );
}

// 3. Remove unnecessary header clutter
if ( ! empty( ['remove_rsd_wlw'] ) ) {
    remove_action( 'wp_head', 'rsd_link' );
    remove_action( 'wp_head', 'wlwmanifest_link' );
}

if ( ! empty( ['remove_shortlink_rest'] ) ) {
    remove_action( 'wp_head', 'wp_shortlink_wp_head' );
    remove_action( 'wp_head', 'rest_output_link_wp_head' );
    remove_action( 'template_redirect', 'rest_output_link_header', 11 );
}

if ( ! empty( ['remove_oembed'] ) ) {
    remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
}

// 4. Disable Emojis
if ( ! empty( ['disable_emojis'] ) ) {
    add_action( 'init', function() {
        remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
        remove_action( 'admin_print_scripts', 'print_emoji_detection_script' );
        remove_action( 'wp_print_styles', 'print_emoji_styles' );
        remove_action( 'admin_print_styles', 'print_emoji_styles' );
        remove_filter( 'the_content_feed', 'wp_staticize_emoji' );
        remove_filter( 'comment_text_rss', 'wp_staticize_emoji' );
        remove_filter( 'wp_mail', 'wp_staticize_emoji_for_email' );
    } );
}

// 5. Output Author / Designer meta tags
if ( ! empty( ['add_author_meta'] ) ) {
    add_action( 'wp_head', function() use (  ) {
         = esc_attr( ! empty( ['author_name'] ) ? ['author_name'] : 'VladiMIR' );
        echo "\n<!-- Author & Designer (VladiMIR+AI) -->\n";
        echo '<meta name="author" content="' .  . '" />' . "\n";
        echo '<meta name="designer" content="' .  . '" />' . "\n";
    }, 0 );
}

// 6. Clean theme pingbacks from HTML buffer
if ( ! empty( ['clean_theme_pingback_html'] ) ) {
    add_action( 'template_redirect', function() {
        if ( is_admin() ) {
            return;
        }
        ob_start( function(  ) {
            if ( empty(  ) || ! is_string(  ) ) {
                return ;
            }
             = preg_replace( '/\s*<link\s+rel=[\'"]pingback[\'"][^>]*>/i', '',  );
             = preg_replace( '/\s*<link\s+rel=[\'"]profile[\'"][^>]*>/i', '',  );
            return ;
        } );
    }, 1 );
}

// ─────────────────────────────────────────────
// 5. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'Очистка Head Meta & Защита от отпечатков (VladiMIR+AI)';
            [  ]['Description'] = 'Очищает мусор в &lt;head&gt;, скрывает версию WordPress, удаляет ссылки XML-RPC pingback и эмодзи, добавляет чистые метатеги автора. Включает панель настроек на одной странице.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'Vyčištění Head Meta & Ochrana soukromí (VladiMIR+AI)';
            [  ]['Description'] = 'Vyčistí záhlaví &lt;head&gt; od zbytečného kódu, skryje verzi WordPressu, odstraní zastaralé odkazy pingback a emoji a poskytuje přehlednou stránku nastavení.';
        }
    }
    return ;
} );

