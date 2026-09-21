<?php
/**
 * Plugin Name: WP SEO Micro (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-seo-micro
 * Description: Ultra-lightweight complete SEO engine: Smart Title, Meta Description & Keywords, Open Graph social cards, canonical URLs, smart robots indexation control, native XML sitemap with image support (/sitemap.xml & /sitemaps.xml), automated Image SEO (filename cleanup & auto-alt), code & head speed cleaners, webmaster verifications (Yandex, Google, Seznam.cz), 301 archive redirects, and seamless 100% backward compatibility with SEOPress metadata. Zero database bloat.
 * Version:     2026-09__1.38
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-seo-micro
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-seo-micro
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Shared auto-update client (private GitHub repository, see WordPress/README.md).
// Guarded: a partial copy of the plugin folder must degrade to "no auto-updates",
// not to a fatal error on every page load.
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

function vladimir_seo_get_settings() {
    $defaults = array(
        'title_separator'          => '>',
        'enable_og_tags'           => 1,
        'enable_canonical'         => 1,
        'enable_smart_robots'      => 1,
        'enable_sitemap'           => 1,
        'enable_sitemap_images'    => 1,
        'enable_head_cleaner'      => 1,
        'enable_image_seo'         => 1,
        'enable_redirect_archives' => 1,
        'enable_keywords'          => 1,
        'enable_metabox'           => 1,
        'home_description'         => '',
        'home_keywords'            => '',
        'google_verify'            => '',
        'bing_verify'              => '',
        'yandex_verify'            => '',
        'seznam_verify'            => '',
        'pinterest_verify'         => '',
        'baidu_verify'             => '',
        'facebook_verify'          => '',
    );
    $saved = get_option( '_vladimir_seo_settings', array() );
    $settings = wp_parse_args( is_array( $saved ) ? $saved : array(), $defaults );

    // Fallback: auto-read historical SEOPress settings if fields are empty
    if ( empty( $settings['home_description'] ) ) {
        $seopress_titles = get_option( 'seopress_titles_option_name' );
        if ( is_array( $seopress_titles ) && ! empty( $seopress_titles['seopress_titles_home_site_desc'] ) ) {
            $settings['home_description'] = (string) $seopress_titles['seopress_titles_home_site_desc'];
        }
    }

    $seopress_adv = null;
    $ver_fields = array(
        'google_verify'    => 'seopress_advanced_google_webmaster',
        'bing_verify'      => 'seopress_advanced_bing_webmaster',
        'yandex_verify'    => 'seopress_advanced_yandex_webmaster',
        'seznam_verify'    => 'seopress_advanced_seznam_webmaster',
        'pinterest_verify' => 'seopress_advanced_pinterest_webmaster',
        'baidu_verify'     => 'seopress_advanced_baidu_webmaster',
        'facebook_verify'  => 'seopress_advanced_facebook_webmaster',
    );
    foreach ( $ver_fields as $local_k => $seopress_k ) {
        if ( empty( $settings[ $local_k ] ) ) {
            if ( null === $seopress_adv ) {
                $seopress_adv = get_option( 'seopress_advanced_option_name' );
            }
            if ( is_array( $seopress_adv ) && ! empty( $seopress_adv[ $seopress_k ] ) ) {
                $settings[ $local_k ] = (string) $seopress_adv[ $seopress_k ];
            }
        }
    }

    return $settings;
}

// ─────────────────────────────────────────────
// 2. PLUGIN ACTION LINKS (Settings & Documentation)
// ─────────────────────────────────────────────

add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), function( $links ) {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang   = strtolower( substr( $locale, 0, 2 ) );

    $settings_label = ( 'ru' === $lang ) ? 'Настройки' : ( ( 'cs' === $lang ) ? 'Nastavení' : 'Settings' );
    $docs_label     = ( 'ru' === $lang ) ? 'Документация ↗' : ( ( 'cs' === $lang ) ? 'Dokumentace ↗' : 'Documentation ↗' );

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-seo-micro-settings' ) ) . '" style="white-space:nowrap;">' . esc_html( $settings_label ) . '</a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-seo-micro" target="_blank" style="white-space:nowrap;">' . esc_html( $docs_label ) . '</a>';

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
        'WP SEO Micro (VladiMIR+AI✅)',
        'WP SEO Micro',
        'manage_options',
        'vladimir-seo-micro-settings',
        'vladimir_seo_render_settings_page'
    );
} );

function vladimir_seo_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_seo_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title    = 'WP SEO Micro: Настройки поисковой оптимизации';
        $txt_subtitle = 'Управление Title, Description, Keywords, Open Graph, robots, XML Sitemap, очисткой кода и верификацией с поддержкой SEOPress.';
        $txt_saved    = 'Настройки успешно сохранены!';
        $txt_sep      = 'Разделитель в теге Title';
        $txt_sep_desc = 'Символ между названием страницы и именем сайта (по умолчанию: >).';
        $txt_desc     = 'Meta Description главной страницы';
        $txt_desc_h   = 'Краткое описание сайта для поисковой выдачи Яндекс и Google (до 160 символов).';
        $txt_kw       = 'Meta Keywords главной страницы (через запятую)';
        $txt_kw_h     = 'Список ключевых поисковых запросов через запятую (например: шапки оптом, головные уборы, палантины).';
        $txt_og       = 'Включить разметку Open Graph (og:title, og:image, og:description)';
        $txt_og_desc  = 'Формирует привлекательные сниппеты ссылок при публикации в соцсетях и мессенджерах.';
        $txt_can      = 'Генерировать канонические ссылки (canonical URL)';
        $txt_can_desc = 'Защищает от дублей страниц в индексе поисковых систем.';
        $txt_rob      = 'Умное управление индексацией Robots (noindex на мусорные страницы)';
        $txt_rob_desc = 'Закрывает от индексации страницы поиска, архивы дат, авторов, метки, вложения и пагинацию.';
        $txt_map      = 'Включить нативную XML Карту Сайта (/sitemap.xml и /sitemaps.xml)';
        $txt_map_desc = 'Быстрая карта сайта для поисковиков: ' . home_url( '/sitemap.xml' ) . ' (и поддержка /sitemaps.xml).';
        $txt_map_img  = 'Включить изображения в XML карту сайта (<image:image>)';
        $txt_map_img_d= 'Добавляет теги картинок для лучшей индексации в Google Images и Яндекс Картинках.';
        $txt_clean    = 'Очистка исходного кода и ускорение сайта (Head & Headers Cleaner)';
        $txt_clean_d  = 'Удаляет Emoji, RSD, WLW, Shortlink, Generator, oEmbed, класс hentry, ?replytocom, X-Pingback и X-Powered-By.';
        $txt_img_seo  = 'SEO для изображений (Очистка имен файлов и Авто-Alt)';
        $txt_img_seo_d= 'Транслитерация и очистка имени файла при загрузке (UTF-8) + автогенерация Alt из имени файла и ключевых слов.';
        $txt_redir    = '301 редирект для архивов автора, дат и вложений';
        $txt_redir_d  = 'Перенаправляет страницы авторов, архивы дат и страницы вложений на главную или родительский пост.';
        $txt_kw_en    = 'Генерировать метатег Keywords (<meta name="keywords">)';
        $txt_kw_desc  = 'Автоматически выводит ключевые слова из меток товара, рубрик или персонального SEO-поля.';
        $txt_box      = 'Отображать SEO Метабокс в редакторе записей и товаров';
        $txt_box_desc = 'Позволяет задавать персональный Title, Meta Description и Keywords при редактировании страницы.';
        $txt_save     = 'Сохранить настройки';
        $txt_legacy   = '🛡️ <strong>100% совместимость с SEOPress:</strong> Плагин автоматически подхватывает Title, Description, Keywords, Canonical URL, Noindex и коды верификации из полей SEOPress (_seopress_*), гарантируя нулевую потерю позиций.';
        $txt_ver_h    = 'Верификация вебмастеров (Мета-теги поисковых систем)';
        $txt_ver_desc = 'Введите только коды верификации (содержимое атрибута content) или полный тег:';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'WP SEO Micro: Nastavení vyhledávačů (SEO)';
        $txt_subtitle = 'Správa titulků, meta popisků, klíčových slov, Open Graph tagů, robots, XML mapy stránek, čištění kódu a ověření SEOPress.';
        $txt_saved    = 'Nastavení bylo úspěšně uloženo!';
        $txt_sep      = 'Oddělovač v titulku (Title separator)';
        $txt_sep_desc = 'Znak mezi názvem stránky a webem (výchozí: >).';
        $txt_desc     = 'Meta Description úvodní stránky';
        $txt_desc_h   = 'Popis webu pro vyhledávače Google a Seznam (do 160 znaků).';
        $txt_kw       = 'Meta Keywords úvodní stránky (oddělená čárkou)';
        $txt_kw_h     = 'Klíčová slova webu oddělená čárkou.';
        $txt_og       = 'Povolit Open Graph tagy pro sociální sítě';
        $txt_og_desc  = 'Vytváří náhledy odkazů na sociálních sítích.';
        $txt_can      = 'Generovat kanonické URL adresy (canonical)';
        $txt_can_desc = 'Zabraňuje duplicitnímu obsahu ve vyhledávačích.';
        $txt_rob      = 'Chytrá správa indexace Robots (noindex pro nepotřebné stránky)';
        $txt_rob_desc = 'Zakazuje indexaci vyhledávání, archivů, štítků a stránkování.';
        $txt_map      = 'Povolit nativní XML mapu stránek (/sitemap.xml)';
        $txt_map_desc = 'Rychlá mapa stránek pro vyhledávače: ' . home_url( '/sitemap.xml' ) . '.';
        $txt_map_img  = 'Zahrnout obrázky do XML mapy stránek (<image:image>)';
        $txt_map_img_d= 'Zlepšuje indexaci obrázků v Google Obrázcích a Seznamu.';
        $txt_clean    = 'Čištění zdrojového kódu a zrychlení webu (Head & Headers Cleaner)';
        $txt_clean_d  = 'Odstraňuje Emoji, RSD, WLW, Shortlink, Generator, oEmbed, třídu hentry, ?replytocom, X-Pingback a X-Powered-By.';
        $txt_img_seo  = 'SEO pro obrázky (Čištění názvů souborů a Auto-Alt)';
        $txt_img_seo_d= 'Čištění názvů médií při nahrávání (UTF-8) + automatický Alt z názvu a klíčových slov.';
        $txt_redir    = '301 přesměrování pro archivy autorů, dat a příloh';
        $txt_redir_d  = 'Přesměruje stránky autorů, data a přílohy na hlavní stránku.';
        $txt_kw_en    = 'Generovat meta tag Keywords';
        $txt_kw_desc  = 'Automaticky doplňuje klíčová slova ze štítků a kategorií.';
        $txt_box      = 'Zobrazovat SEO pole v editoru příspěvků a produktů';
        $txt_box_desc = 'Umožňuje upravit Title, Description a Keywords každé stránky.';
        $txt_save     = 'Uložit nastavení';
        $txt_legacy   = '🛡️ <strong>Kompatibilita se SEOPress:</strong> Plugin automaticky načítá dříve uložené titulky, popisky i ověřovací kódy ze SEOPressu.';
        $txt_ver_h    = 'Ověření vyhledávačů (Webmaster Meta Tagy)';
        $txt_ver_desc = 'Zadejte ověřovací kód pro vyhledávače:';
    } else {
        $txt_title    = 'WP SEO Micro: Search Engine Optimization Settings';
        $txt_subtitle = 'Smart Titles, Meta Descriptions, Keywords, Open Graph tags, canonical URLs, robots control, XML sitemap with images, code cleaner, and webmaster verifications.';
        $txt_saved    = 'Settings successfully saved!';
        $txt_sep      = 'Title Separator';
        $txt_sep_desc = 'Character separating post title and site name (default: >).';
        $txt_desc     = 'Homepage Meta Description';
        $txt_desc_h   = 'Site summary snippet for search results (up to 160 characters).';
        $txt_kw       = 'Homepage Meta Keywords (comma separated)';
        $txt_kw_h     = 'Comma-separated target search phrases.';
        $txt_og       = 'Enable Open Graph Tags (Facebook, Telegram, WhatsApp)';
        $txt_og_desc  = 'Generates rich link preview cards on social platforms.';
        $txt_can      = 'Generate Canonical URLs';
        $txt_can_desc = 'Prevents search duplicate content penalties.';
        $txt_rob      = 'Smart Robots Meta Control (noindex on thin/junk pages)';
        $txt_rob_desc = 'Adds noindex to search results, author archives, date archives, tags, attachments, and pagination.';
        $txt_map      = 'Enable Native XML Sitemap (/sitemap.xml & /sitemaps.xml)';
        $txt_map_desc = 'High-performance sitemap at: ' . home_url( '/sitemap.xml' ) . '.';
        $txt_map_img  = 'Include Images in XML Sitemap (<image:image>)';
        $txt_map_img_d= 'Adds image tags for optimal indexing in Google and Yandex Images.';
        $txt_clean    = 'Clean HTML Head & HTTP Headers (Speed Optimization)';
        $txt_clean_d  = 'Removes Emoji, RSD, WLW, Shortlink, Generator, oEmbed, hentry class, ?replytocom, X-Pingback, and X-Powered-By.';
        $txt_img_seo  = 'Automated Image SEO (Filename Sanitization & Auto-Alt)';
        $txt_img_seo_d= 'Sanitizes media upload filenames (UTF-8 lowercase slug) + auto-generates Alt tags.';
        $txt_redir    = '301 Redirect for Author, Date & Attachment Archives';
        $txt_redir_d  = 'Permanently redirects author archives, date archives, and attachments to avoid duplicate content.';
        $txt_kw_en    = 'Generate Meta Keywords tag (<meta name="keywords">)';
        $txt_kw_desc  = 'Pulls keywords from product tags, categories, or custom fields.';
        $txt_box      = 'Display SEO Meta Box in Post & Product Editors';
        $txt_box_desc = 'Allows setting custom Title, Meta Description, and Keywords per item.';
        $txt_save     = 'Save Settings';
        $txt_legacy   = '🛡️ <strong>100% SEOPress Compatibility:</strong> Automatically reads historical _seopress_* title, description, keywords, canonical, and verification metadata.';
        $txt_ver_h    = 'Search Engine Webmaster Verification';
        $txt_ver_desc = 'Enter verification codes for search engine master consoles:';
    }
    ?>
    <div class="wrap" style="max-width:880px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🚀 <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI✅)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <!-- Sitemap Quick Links Box -->
        <div style="background:#f8fafc;border:1px solid #cbd5e1;padding:18px 22px;border-radius:8px;margin-bottom:24px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <h3 style="margin-top:0;font-size:15px;display:flex;align-items:center;gap:8px;color:#0f172a;">
                <span>🗺️ Карта сайта (XML Sitemap + Images)</span>
                <span style="font-size:11px;background:#10b981;color:#fff;padding:2px 8px;border-radius:10px;font-weight:600;">Active 24/7</span>
            </h3>
            <p style="margin-bottom:14px;color:#475569;font-size:13px;line-height:1.5;">
                Карта сайта формируется на лету без лишней нагрузки на базу данных, включает изображения и доступна сразу по обоим стандартным адресам для роботов Яндекс, Google и Seznam.cz:
            </p>
            <div style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
                <a href="<?php echo esc_url( home_url( '/sitemap.xml' ) ); ?>" target="_blank" class="button button-primary" style="display:inline-flex;align-items:center;gap:6px;font-weight:600;height:34px;line-height:32px;">
                    <span>🌐 Открыть /sitemap.xml ↗</span>
                </a>
                <a href="<?php echo esc_url( home_url( '/sitemaps.xml' ) ); ?>" target="_blank" class="button button-secondary" style="display:inline-flex;align-items:center;gap:6px;height:34px;line-height:32px;">
                    <span>🌐 Открыть /sitemaps.xml (SEOPress) ↗</span>
                </a>
            </div>
        </div>

        <div style="background:#f0fdf4;border-left:4px solid #16a34a;padding:12px 16px;border-radius:4px;margin-bottom:20px;font-size:13px;color:#15803d;">
            <?php echo wp_kses_post( $txt_legacy ); ?>
        </div>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_seo_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_seo_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="title_separator"><strong><?php echo esc_html( $txt_sep ); ?></strong></label></th>
                    <td>
                        <input type="text" name="title_separator" id="title_separator" value="<?php echo esc_attr( $settings['title_separator'] ); ?>" style="width:70px;text-align:center;">
                        <p class="description"><?php echo esc_html( $txt_sep_desc ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="home_description"><strong><?php echo esc_html( $txt_desc ); ?></strong></label></th>
                    <td>
                        <textarea name="home_description" id="home_description" rows="3" class="large-text" style="width:100%;"><?php echo esc_textarea( $settings['home_description'] ); ?></textarea>
                        <p class="description"><?php echo esc_html( $txt_desc_h ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="home_keywords"><strong><?php echo esc_html( $txt_kw ); ?></strong></label></th>
                    <td>
                        <input type="text" name="home_keywords" id="home_keywords" value="<?php echo esc_attr( $settings['home_keywords'] ); ?>" class="regular-text" style="width:100%;" placeholder="шапки оптом, головные уборы, палантины, шарфы, снуды">
                        <p class="description"><?php echo esc_html( $txt_kw_h ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><strong>SEO Core Options</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:12px;">
                            <label>
                                <input type="checkbox" name="enable_og_tags" value="1" <?php checked( $settings['enable_og_tags'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_og ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_og_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_canonical" value="1" <?php checked( $settings['enable_canonical'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_can ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_can_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_smart_robots" value="1" <?php checked( $settings['enable_smart_robots'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_rob ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_rob_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_sitemap" value="1" <?php checked( $settings['enable_sitemap'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_map ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_map_desc ); ?></p>

                            <label style="margin-left:24px;">
                                <input type="checkbox" name="enable_sitemap_images" value="1" <?php checked( $settings['enable_sitemap_images'], 1 ); ?>>
                                <?php echo esc_html( $txt_map_img ); ?>
                            </label>
                            <p class="description" style="margin-left:48px;margin-top:-8px;"><?php echo esc_html( $txt_map_img_d ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_head_cleaner" value="1" <?php checked( $settings['enable_head_cleaner'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_clean ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_clean_d ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_image_seo" value="1" <?php checked( $settings['enable_image_seo'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_img_seo ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_img_seo_d ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_redirect_archives" value="1" <?php checked( $settings['enable_redirect_archives'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_redir ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_redir_d ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_keywords" value="1" <?php checked( $settings['enable_keywords'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_kw_en ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_kw_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_metabox" value="1" <?php checked( $settings['enable_metabox'], 1 ); ?>>
                                <strong><?php echo esc_html( $txt_box ); ?></strong>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-8px;"><?php echo esc_html( $txt_box_desc ); ?></p>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <hr style="margin:25px 0;border:0;border-top:1px solid #e2e8f0;">

            <h3 style="font-size:15px;color:#0f172a;margin-bottom:6px;">🌐 <?php echo esc_html( $txt_ver_h ); ?></h3>
            <p class="description" style="margin-bottom:15px;"><?php echo esc_html( $txt_ver_desc ); ?></p>

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="yandex_verify">Яндекс Вебмастер (yandex-verification)</label></th>
                    <td>
                        <input type="text" name="yandex_verify" id="yandex_verify" value="<?php echo esc_attr( $settings['yandex_verify'] ); ?>" class="regular-text" style="width:100%;" placeholder="e.g. 7a8b9c0d1e2f3a4b">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="google_verify">Google Search Console (google-site-verification)</label></th>
                    <td>
                        <input type="text" name="google_verify" id="google_verify" value="<?php echo esc_attr( $settings['google_verify'] ); ?>" class="regular-text" style="width:100%;" placeholder="e.g. AbCdEfGhIjKlMnOpQrStUvWxYz123456789">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="seznam_verify">Seznam.cz Webmaster (seznam-wmt)</label></th>
                    <td>
                        <input type="text" name="seznam_verify" id="seznam_verify" value="<?php echo esc_attr( $settings['seznam_verify'] ); ?>" class="regular-text" style="width:100%;" placeholder="e.g. f9a8b7c6d5e4f3a2">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="bing_verify">Bing Webmaster (msvalidate.01)</label></th>
                    <td>
                        <input type="text" name="bing_verify" id="bing_verify" value="<?php echo esc_attr( $settings['bing_verify'] ); ?>" class="regular-text" style="width:100%;" placeholder="e.g. 1234567890ABCDEF1234567890ABCDEF">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="pinterest_verify">Pinterest Domain (p:domain_verify)</label></th>
                    <td>
                        <input type="text" name="pinterest_verify" id="pinterest_verify" value="<?php echo esc_attr( $settings['pinterest_verify'] ); ?>" class="regular-text" style="width:100%;" placeholder="e.g. abcdef1234567890abcdef1234567890">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="baidu_verify">Baidu Webmaster (baidu-site-verification)</label></th>
                    <td>
                        <input type="text" name="baidu_verify" id="baidu_verify" value="<?php echo esc_attr( $settings['baidu_verify'] ); ?>" class="regular-text" style="width:100%;" placeholder="e.g. code-xxxxxx">
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="facebook_verify">Facebook Domain Verification</label></th>
                    <td>
                        <input type="text" name="facebook_verify" id="facebook_verify" value="<?php echo esc_attr( $settings['facebook_verify'] ); ?>" class="regular-text" style="width:100%;" placeholder="e.g. 1234567890abcdef">
                    </td>
                </tr>
            </table>

            <div style="margin-top:24px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-seo-micro" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_seo_settings', function() {
    check_admin_referer( 'vladimir_save_seo_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $clean_verify = function( $val ) {
        $val = trim( (string) $val );
        if ( preg_match( '/content=[\'"]([^\'"]+)[\'"]/i', $val, $m ) ) {
            return sanitize_text_field( $m[1] );
        }
        return sanitize_text_field( $val );
    };

    $updated = array(
        'title_separator'          => sanitize_text_field( (string) ( $_POST['title_separator'] ?? '>' ) ),
        'enable_og_tags'           => isset( $_POST['enable_og_tags'] ) ? 1 : 0,
        'enable_canonical'         => isset( $_POST['enable_canonical'] ) ? 1 : 0,
        'enable_smart_robots'      => isset( $_POST['enable_smart_robots'] ) ? 1 : 0,
        'enable_sitemap'           => isset( $_POST['enable_sitemap'] ) ? 1 : 0,
        'enable_sitemap_images'    => isset( $_POST['enable_sitemap_images'] ) ? 1 : 0,
        'enable_head_cleaner'      => isset( $_POST['enable_head_cleaner'] ) ? 1 : 0,
        'enable_image_seo'         => isset( $_POST['enable_image_seo'] ) ? 1 : 0,
        'enable_redirect_archives' => isset( $_POST['enable_redirect_archives'] ) ? 1 : 0,
        'enable_keywords'          => isset( $_POST['enable_keywords'] ) ? 1 : 0,
        'enable_metabox'           => isset( $_POST['enable_metabox'] ) ? 1 : 0,
        'home_description'         => sanitize_textarea_field( (string) ( $_POST['home_description'] ?? '' ) ),
        'home_keywords'            => sanitize_text_field( (string) ( $_POST['home_keywords'] ?? '' ) ),
        'google_verify'            => $clean_verify( $_POST['google_verify'] ?? '' ),
        'bing_verify'              => $clean_verify( $_POST['bing_verify'] ?? '' ),
        'yandex_verify'            => $clean_verify( $_POST['yandex_verify'] ?? '' ),
        'seznam_verify'            => $clean_verify( $_POST['seznam_verify'] ?? '' ),
        'pinterest_verify'         => $clean_verify( $_POST['pinterest_verify'] ?? '' ),
        'baidu_verify'             => $clean_verify( $_POST['baidu_verify'] ?? '' ),
        'facebook_verify'          => $clean_verify( $_POST['facebook_verify'] ?? '' ),
    );

    update_option( '_vladimir_seo_settings', $updated );
    delete_transient( '_wsm_sitemap' );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-seo-micro-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. TITLE TAG GENERATION
// ─────────────────────────────────────────────

add_filter( 'pre_get_document_title', function( $title ) {
    $settings  = vladimir_seo_get_settings();
    $sep       = ' ' . trim( $settings['title_separator'] ?: '>' ) . ' ';
    $site_name = get_bloginfo( 'name' );

    if ( is_front_page() || is_home() ) {
        $desc = ! empty( $settings['home_description'] ) ? $settings['home_description'] : get_bloginfo( 'description' );
        return $desc ? ( $site_name . $sep . $desc ) : $site_name;
    }

    if ( is_singular() ) {
        $obj = get_queried_object();
        if ( $obj ) {
            $custom_title = get_post_meta( $obj->ID, '_wsm_title', true )
                         ?: get_post_meta( $obj->ID, '_seopress_titles_title', true )
                         ?: get_post_meta( $obj->ID, '_yoast_wpseo_title', true );

            if ( ! empty( $custom_title ) ) {
                return esc_html( str_replace(
                    array( '%%sitename%%', '%%sep%%', '%%sitedesc%%', '%%post_title%%' ),
                    array( $site_name, $sep, get_bloginfo( 'description' ), get_the_title( $obj->ID ) ),
                    $custom_title
                ) );
            }

            return get_the_title( $obj->ID ) . $sep . $site_name;
        }
    }

    if ( is_category() || is_tax( 'product_cat' ) || is_tax( 'brand' ) || is_tax( 'product_brand' ) ) {
        $obj = get_queried_object();
        if ( $obj && ! empty( $obj->name ) ) {
            return $obj->name . $sep . $site_name;
        }
    }

    if ( is_tag() || is_tax() ) {
        $obj = get_queried_object();
        if ( $obj && ! empty( $obj->name ) ) {
            return $obj->name . $sep . $site_name;
        }
    }

    if ( is_404() ) {
        return '404' . $sep . $site_name;
    }

    if ( is_search() ) {
        $locale = get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        $label  = ( 'ru' === $lang ) ? 'Поиск' : ( ( 'cs' === $lang ) ? 'Vyhledávání' : 'Search' );

        return $label . ': ' . get_search_query() . $sep . $site_name;
    }

    return $title;
}, 20 );

// ─────────────────────────────────────────────
// 5. ROBOTS META CONTROL
// ─────────────────────────────────────────────

add_action( 'wp_head', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_smart_robots'] ) ) {
        return;
    }

    if ( is_singular() ) {
        $post_id    = get_queried_object_id();
        $is_noindex = ( get_post_meta( $post_id, '_seopress_robots_index', true ) === 'yes' )
                   || ( get_post_meta( $post_id, '_wsm_noindex', true ) === '1' );
        if ( $is_noindex ) {
            echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
            return;
        }
    }

    // Thin, duplicate or technical pages must not bloat crawl budget
    if ( is_search() || is_404() || is_author() || is_date() || is_attachment() || is_tag() || is_tax( 'product_tag' ) || is_tax( 'post_format' ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    // Pagination archives
    if ( is_paged() ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    // Builder blocks & templates
    if ( is_singular( array( 'ux_block', 'wp_block', 'elementor_library' ) ) ) {
        echo "<meta name=\"robots\" content=\"noindex,nofollow\">\n";
        return;
    }

    // Clean indexable pages
    if ( is_front_page() || is_home() || is_singular( array( 'post', 'page', 'product' ) ) || is_category() || is_tax( 'product_cat' ) || is_tax( 'brand' ) || is_tax( 'product_brand' ) ) {
        echo "<meta name=\"robots\" content=\"index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1\">\n";
    }
}, 1 );

// ─────────────────────────────────────────────
// 6. META DESCRIPTION, KEYWORDS, CANONICAL, OPEN GRAPH & VERIFICATION
// ─────────────────────────────────────────────

add_action( 'wp_head', function() {
    $settings = vladimir_seo_get_settings();

    // 1. Webmaster Verifications
    $verifications = array(
        'google-site-verification'   => $settings['google_verify'] ?? '',
        'msvalidate.01'              => $settings['bing_verify'] ?? '',
        'yandex-verification'        => $settings['yandex_verify'] ?? '',
        'seznam-wmt'                 => $settings['seznam_verify'] ?? '',
        'p:domain_verify'            => $settings['pinterest_verify'] ?? '',
        'baidu-site-verification'    => $settings['baidu_verify'] ?? '',
        'facebook-domain-verification'=> $settings['facebook_verify'] ?? '',
    );
    foreach ( $verifications as $name => $code ) {
        if ( ! empty( $code ) ) {
            echo '<meta name="' . esc_attr( $name ) . '" content="' . esc_attr( trim( $code ) ) . "\">\n";
        }
    }

    // 2. Meta Description, Keywords, Canonical & OG
    $desc      = '';
    $keywords  = '';
    $title     = '';
    $permalink = '';
    $og_img    = '';
    $og_type   = 'website';

    if ( is_front_page() || is_home() ) {
        $desc      = ! empty( $settings['home_description'] ) ? $settings['home_description'] : get_bloginfo( 'description' );
        $keywords  = ! empty( $settings['home_keywords'] ) ? $settings['home_keywords'] : '';
        $title     = get_bloginfo( 'name' );
        $permalink = home_url( '/' );
    } elseif ( is_singular() ) {
        $obj = get_queried_object();
        if ( $obj ) {
            $desc = get_post_meta( $obj->ID, '_wsm_desc', true )
                 ?: get_post_meta( $obj->ID, '_seopress_titles_desc', true )
                 ?: get_post_meta( $obj->ID, '_yoast_wpseo_metadesc', true );

            if ( empty( $desc ) ) {
                $raw  = wp_strip_all_tags( strip_shortcodes( $obj->post_excerpt ?: $obj->post_content ) );
                $raw  = trim( preg_replace( '/\s+/', ' ', $raw ) );
                $desc = function_exists( 'mb_substr' ) ? mb_substr( $raw, 0, 160 ) : substr( $raw, 0, 160 );
            }

            $keywords = get_post_meta( $obj->ID, '_wsm_keywords', true )
                     ?: get_post_meta( $obj->ID, '_seopress_analysis_target_kw', true )
                     ?: get_post_meta( $obj->ID, '_yoast_wpseo_focuskw', true );

            if ( empty( $keywords ) ) {
                $tags = array();
                $post_tags = get_the_terms( $obj->ID, 'product_tag' ) ?: get_the_tags( $obj->ID );
                if ( ! empty( $post_tags ) && ! is_wp_error( $post_tags ) ) {
                    foreach ( $post_tags as $t ) {
                        $tags[] = $t->name;
                    }
                }
                $post_cats = get_the_terms( $obj->ID, 'product_cat' ) ?: get_the_category( $obj->ID );
                if ( ! empty( $post_cats ) && ! is_wp_error( $post_cats ) ) {
                    foreach ( $post_cats as $c ) {
                        $tags[] = $c->name;
                    }
                }
                if ( ! empty( $tags ) ) {
                    $keywords = implode( ', ', array_unique( $tags ) );
                } else {
                    $keywords = get_the_title( $obj->ID );
                }
            }

            $title     = get_the_title( $obj->ID );
            $permalink = get_post_meta( $obj->ID, '_wsm_canonical', true )
                      ?: get_post_meta( $obj->ID, '_seopress_titles_canonical', true )
                      ?: get_permalink( $obj->ID );
            $og_type   = 'article';

            if ( has_post_thumbnail( $obj->ID ) ) {
                $og_img = get_the_post_thumbnail_url( $obj->ID, 'large' );
            } elseif ( $seopress_fb = get_post_meta( $obj->ID, '_seopress_social_fb_img', true ) ) {
                $og_img = $seopress_fb;
            }
        }
    } elseif ( is_category() || is_tax( 'product_cat' ) || is_tax( 'brand' ) || is_tax( 'product_brand' ) ) {
        $obj = get_queried_object();
        if ( $obj ) {
            $desc      = wp_strip_all_tags( term_description( $obj->term_id ) );
            $keywords  = $obj->name . ', ' . get_bloginfo( 'name' );
            $title     = $obj->name;
            $permalink = get_term_link( $obj );
        }
    }

    if ( ! empty( $desc ) ) {
        echo '<meta name="description" content="' . esc_attr( trim( $desc ) ) . "\">\n";
    }

    if ( ! empty( $settings['enable_keywords'] ) && ! empty( $keywords ) ) {
        echo '<meta name="keywords" content="' . esc_attr( trim( $keywords ) ) . "\">\n";
    }

    if ( ! empty( $settings['enable_canonical'] ) && ! empty( $permalink ) ) {
        echo '<link rel="canonical" href="' . esc_url( $permalink ) . "\">\n";
    }

    if ( ! empty( $settings['enable_og_tags'] ) && ! empty( $permalink ) ) {
        echo '<meta property="og:type" content="' . esc_attr( $og_type ) . "\">\n";
        echo '<meta property="og:site_name" content="' . esc_attr( get_bloginfo( 'name' ) ) . "\">\n";
        echo '<meta property="og:title" content="' . esc_attr( $title ?: get_bloginfo( 'name' ) ) . "\">\n";
        echo '<meta property="og:url" content="' . esc_url( $permalink ) . "\">\n";
        if ( ! empty( $desc ) ) {
            echo '<meta property="og:description" content="' . esc_attr( trim( $desc ) ) . "\">\n";
        }
        if ( ! empty( $og_img ) ) {
            echo '<meta property="og:image" content="' . esc_url( $og_img ) . "\">\n";
        }
    }
}, 2 );

// ─────────────────────────────────────────────
// 7. SPEED & HEAD CLEANER OPTIMIZATION
// ─────────────────────────────────────────────

add_action( 'init', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_head_cleaner'] ) ) {
        return;
    }

    // 1. Remove Emoji scripts, styles and DNS prefetch
    remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
    remove_action( 'admin_print_scripts', 'print_emoji_detection_script' );
    remove_action( 'wp_print_styles', 'print_emoji_styles' );
    remove_action( 'admin_print_styles', 'print_emoji_styles' );
    remove_filter( 'the_content_feed', 'wp_staticize_emoji' );
    remove_filter( 'comment_text_rss', 'wp_staticize_emoji' );
    remove_filter( 'wp_mail', 'wp_staticize_emoji_for_email' );
    add_filter( 'tiny_mce_plugins', function( $plugins ) {
        return is_array( $plugins ) ? array_diff( $plugins, array( 'wpemoji' ) ) : array();
    } );
    add_filter( 'wp_resource_hints', function( $urls, $relation_type ) {
        if ( 'dns-prefetch' === $relation_type ) {
            $urls = array_filter( $urls, function( $url ) {
                return false === strpos( $url, 's.w.org' );
            } );
        }
        return $urls;
    }, 10, 2 );

    // 2. Remove bloat meta tags from <head>
    remove_action( 'wp_head', 'wp_generator' );
    remove_action( 'wp_head', 'rsd_link' );
    remove_action( 'wp_head', 'wlwmanifest_link' );
    remove_action( 'wp_head', 'wp_shortlink_wp_head', 10, 0 );
    remove_action( 'template_redirect', 'wp_shortlink_header', 11, 0 );

    // 3. Remove oEmbed discovery links
    remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
    remove_action( 'wp_head', 'wp_oembed_add_host_js' );
    remove_action( 'template_redirect', 'rest_output_link_header', 11, 0 );

    // 4. Remove X-Pingback & X-Powered-By HTTP headers
    add_filter( 'pings_open', '__return_false', 20 );
    add_filter( 'wp_headers', function( $headers ) {
        unset( $headers['X-Pingback'], $headers['x-pingback'] );
        return $headers;
    } );
    if ( function_exists( 'header_remove' ) ) {
        @header_remove( 'X-Powered-By' );
        @header_remove( 'X-Pingback' );
    }

    // 5. Remove 'hentry' post class (avoids missing author/updated Google schema warnings)
    add_filter( 'post_class', function( $classes ) {
        return array_diff( $classes, array( 'hentry' ) );
    } );

    // 6. Clean /?replytocom spam links in comments
    add_filter( 'comment_reply_link', function( $link ) {
        return preg_replace( '/href=[\'"][^\'"]*[\?&]replytocom=(\d+)#?[^\'"]*[\'"]/', 'href="#comment-$1"', (string) $link );
    } );
} );

// ─────────────────────────────────────────────
// 8. 301 REDIRECT FOR JUNK ARCHIVES (Author, Date, Attachments)
// ─────────────────────────────────────────────

add_action( 'template_redirect', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_redirect_archives'] ) ) {
        return;
    }

    if ( is_author() || is_date() ) {
        wp_safe_redirect( home_url( '/' ), 301 );
        exit;
    }

    if ( is_attachment() ) {
        $parent_id = wp_get_post_parent_id( get_queried_object_id() );
        $target    = $parent_id ? get_permalink( $parent_id ) : home_url( '/' );
        wp_safe_redirect( $target, 301 );
        exit;
    }
} );

// ─────────────────────────────────────────────
// 9. AUTOMATED IMAGE SEO (Sanitization & Auto-Alt)
// ─────────────────────────────────────────────

// 1. Sanitize file name upon upload (UTF-8 slug, lowercase, remove accents and special characters)
add_filter( 'sanitize_file_name', function( $filename ) {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_image_seo'] ) ) {
        return $filename;
    }

    $info = pathinfo( $filename );
    $ext  = empty( $info['extension'] ) ? '' : '.' . $info['extension'];
    $name = $info['filename'];

    // Transliterate & remove accents
    if ( function_exists( 'remove_accents' ) ) {
        $name = remove_accents( $name );
    }

    // Convert to lowercase and clean symbols
    $name = strtolower( $name );
    $name = preg_replace( '/[^a-z0-9_-]/', '-', $name );
    $name = preg_replace( '/-+/', '-', $name );
    $name = trim( $name, '-' );

    return ( $name ?: 'media' ) . strtolower( $ext );
}, 10, 1 );

// 2. Automatically generate Alt text upon media upload from cleaned file name
add_action( 'add_attachment', function( $post_id ) {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_image_seo'] ) ) {
        return;
    }

    $existing_alt = get_post_meta( $post_id, '_wp_attachment_image_alt', true );
    if ( empty( $existing_alt ) ) {
        $file = get_attached_file( $post_id );
        $name = pathinfo( (string) $file, PATHINFO_FILENAME );
        $alt  = ucwords( trim( str_replace( array( '-', '_' ), ' ', $name ) ) );
        if ( ! empty( $alt ) ) {
            update_post_meta( $post_id, '_wp_attachment_image_alt', sanitize_text_field( $alt ) );
        }
    }
} );

// 3. Frontend Fallback Alt: inject target keywords or post title into empty alt tags
add_filter( 'the_content', function( $content ) {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_image_seo'] ) || ! is_singular() ) {
        return $content;
    }

    $post_id = get_queried_object_id();
    if ( ! $post_id ) {
        return $content;
    }

    $fallback_alt = get_post_meta( $post_id, '_wsm_keywords', true )
                 ?: get_post_meta( $post_id, '_seopress_analysis_target_kw', true )
                 ?: get_the_title( $post_id );

    if ( empty( $fallback_alt ) ) {
        return $content;
    }

    return preg_replace_callback( '/<img\s+([^>]*?)>/i', function( $matches ) use ( $fallback_alt ) {
        $img = $matches[0];
        if ( preg_match( '/alt=[\'"]\s*[\'"]/i', $img ) ) {
            return preg_replace( '/alt=[\'"]\s*[\'"]/i', 'alt="' . esc_attr( $fallback_alt ) . '"', $img );
        } elseif ( ! preg_match( '/alt=/i', $img ) ) {
            return '<img alt="' . esc_attr( $fallback_alt ) . '" ' . $matches[1] . '>';
        }
        return $img;
    }, $content );
}, 20 );

// ─────────────────────────────────────────────
// 10. NATIVE XML SITEMAP ENGINE (/sitemap.xml & /sitemaps.xml)
// ─────────────────────────────────────────────

add_action( 'init', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_sitemap'] ) ) {
        return;
    }

    $uri  = isset( $_SERVER['REQUEST_URI'] ) ? (string) wp_unslash( $_SERVER['REQUEST_URI'] ) : '';
    $path = strtolower( trim( (string) wp_parse_url( $uri, PHP_URL_PATH ), '/' ) );

    if ( ! in_array( $path, array( 'sitemap.xml', 'sitemaps.xml', 'sitemap_index.xml' ), true ) ) {
        return;
    }

    header( 'Content-Type: application/xml; charset=utf-8' );
    header( 'X-Robots-Tag: noindex, follow', true );

    $cached = get_transient( '_wsm_sitemap' );
    if ( is_string( $cached ) && '' !== $cached ) {
        echo $cached; // phpcs:ignore WordPress.Security.EscapeOutput
        exit;
    }

    $include_images = ! empty( $settings['enable_sitemap_images'] );

    ob_start();
    echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
    if ( $include_images ) {
        echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">' . "\n";
    } else {
        echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n";
    }

    // 1. Homepage
    echo '  <url><loc>' . esc_url( home_url( '/' ) ) . '</loc><changefreq>daily</changefreq><priority>1.0</priority></url>' . "\n";

    // 2. Posts, Pages, Products
    $post_types = array( 'post', 'page' );
    if ( post_type_exists( 'product' ) ) {
        $post_types[] = 'product';
    }

    $posts = get_posts( array(
        'post_type'        => $post_types,
        'posts_per_page'   => 2500,
        'post_status'      => 'publish',
        'orderby'          => 'modified',
        'order'            => 'DESC',
        'suppress_filters' => true,
    ) );

    foreach ( $posts as $p ) {
        $date = get_the_modified_date( 'c', $p->ID );
        $prio = ( 'page' === $p->post_type ) ? '0.8' : ( ( 'product' === $p->post_type ) ? '0.9' : '0.7' );
        $img_xml = '';

        if ( $include_images && has_post_thumbnail( $p->ID ) ) {
            $img_url = get_the_post_thumbnail_url( $p->ID, 'full' );
            if ( $img_url ) {
                $img_title = get_the_title( $p->ID );
                $img_xml = '<image:image><image:loc>' . esc_url( $img_url ) . '</image:loc><image:title>' . esc_xml( $img_title ) . '</image:title></image:image>';
            }
        }

        echo '  <url><loc>' . esc_url( get_permalink( $p->ID ) ) . '</loc><lastmod>' . esc_xml( $date ) . '</lastmod><changefreq>weekly</changefreq><priority>' . $prio . '</priority>' . $img_xml . '</url>' . "\n";
    }

    // 3. Categories & Taxonomies
    $taxonomies = array( 'category' );
    if ( taxonomy_exists( 'product_cat' ) ) {
        $taxonomies[] = 'product_cat';
    }
    if ( taxonomy_exists( 'brand' ) ) {
        $taxonomies[] = 'brand';
    }

    $terms = get_terms( array(
        'taxonomy'   => $taxonomies,
        'hide_empty' => true,
    ) );

    if ( ! is_wp_error( $terms ) ) {
        foreach ( $terms as $t ) {
            echo '  <url><loc>' . esc_url( get_term_link( $t ) ) . '</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>' . "\n";
        }
    }

    echo '</urlset>';

    $xml = (string) ob_get_clean();
    set_transient( '_wsm_sitemap', $xml, 12 * HOUR_IN_SECONDS );

    echo $xml; // phpcs:ignore WordPress.Security.EscapeOutput
    exit;
} );

add_action( 'save_post', function() {
    delete_transient( '_wsm_sitemap' );
} );
add_action( 'edited_term', function() {
    delete_transient( '_wsm_sitemap' );
} );

// Robots.txt sitemap link
add_filter( 'robots_txt', function( $output, $public ) {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_sitemap'] ) || ! $public ) {
        return $output;
    }

    if ( false === strpos( $output, 'sitemap.xml' ) ) {
        $output .= "\nSitemap: " . home_url( '/sitemap.xml' ) . "\n";
    }

    return $output;
}, 10, 2 );

// ─────────────────────────────────────────────
// 11. POST METABOX
// ─────────────────────────────────────────────

add_action( 'add_meta_boxes', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_metabox'] ) ) {
        return;
    }

    $post_types = array( 'post', 'page' );
    if ( post_type_exists( 'product' ) ) {
        $post_types[] = 'product';
    }

    add_meta_box( 'wsm_seo', 'SEO (VladiMIR+AI✅)', function( $post ) {
        wp_nonce_field( 'wsm_save', 'wsm_nonce' );
        $title    = esc_attr( get_post_meta( $post->ID, '_wsm_title', true ) ?: get_post_meta( $post->ID, '_seopress_titles_title', true ) );
        $desc     = esc_textarea( get_post_meta( $post->ID, '_wsm_desc', true ) ?: get_post_meta( $post->ID, '_seopress_titles_desc', true ) );
        $keywords = esc_attr( get_post_meta( $post->ID, '_wsm_keywords', true ) ?: get_post_meta( $post->ID, '_seopress_analysis_target_kw', true ) ?: get_post_meta( $post->ID, '_yoast_wpseo_focuskw', true ) );

        echo '<p><label><strong>SEO Title:</strong><br><input type="text" name="wsm_title" value="' . $title . '" style="width:100%" maxlength="70" placeholder="' . esc_attr( get_the_title( $post->ID ) . ' > ' . get_bloginfo( 'name' ) ) . '"></label></p>';
        echo '<p><label><strong>Meta Description:</strong><br><textarea name="wsm_desc" rows="3" style="width:100%" maxlength="160" placeholder="Short snippet text for search results...">' . $desc . '</textarea></label></p>';
        echo '<p><label><strong>Meta Keywords (comma separated):</strong><br><input type="text" name="wsm_keywords" value="' . $keywords . '" style="width:100%" placeholder="Leave empty to reuse tags and categories"></label></p>';
    }, $post_types, 'normal', 'high' );
} );

add_action( 'save_post', function( $post_id ) {
    if ( ! isset( $_POST['wsm_nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['wsm_nonce'] ) ), 'wsm_save' ) ) {
        return;
    }
    if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
        return;
    }
    if ( wp_is_post_revision( $post_id ) ) {
        return;
    }
    if ( ! current_user_can( 'edit_post', $post_id ) ) {
        return;
    }

    if ( isset( $_POST['wsm_title'] ) ) {
        update_post_meta( $post_id, '_wsm_title', sanitize_text_field( wp_unslash( $_POST['wsm_title'] ) ) );
    }
    if ( isset( $_POST['wsm_desc'] ) ) {
        update_post_meta( $post_id, '_wsm_desc', sanitize_textarea_field( wp_unslash( $_POST['wsm_desc'] ) ) );
    }
    if ( isset( $_POST['wsm_keywords'] ) ) {
        update_post_meta( $post_id, '_wsm_keywords', sanitize_text_field( wp_unslash( $_POST['wsm_keywords'] ) ) );
    }
} );
