<?php
/**
 * Plugin Name: WP SEO Micro (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-seo-micro
 * Description: Ultra-lightweight complete SEO engine: Smart Title, Meta Description & Keywords, Open Graph & Twitter Cards, canonical URLs, granular robots control, XML sitemap with images & custom post types (/sitemap.xml & /sitemaps.xml), automated Image SEO (filename sanitation & auto-alt), head & HTTP speed cleaners, custom tracking scripts (Head/Body/Footer), webmaster verifications (Google, Yandex, Seznam.cz, Bing), and clean 404 handling for thin archives. Zero database bloat.
 * Version:     2026-09__1.41
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

// ─────────────────────────────────────────────
// 0. SELF-CONTAINED GITHUB RELEASE AUTO-UPDATER
// ─────────────────────────────────────────────

add_filter( 'update_plugins_vladimir-ai.updates', 'vladimir_seo_update_check', 20, 3 );

function vladimir_seo_update_check( $update, $plugin_data, $plugin_file ) {
    if ( 'wp-seo-micro/wp-seo-micro.php' !== $plugin_file || ! empty( $update ) ) {
        return $update;
    }

    $manifest_url = add_query_arg(
        'ts',
        time(),
        'https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/WordPress/Plugins/updates.json'
    );
    $response = wp_remote_get(
        $manifest_url,
        array(
            'timeout'     => 10,
            'redirection' => 3,
            'headers'     => array(
                'Accept'     => 'application/json',
                'User-Agent' => 'WP-SEO-Micro-Updater',
            ),
        )
    );

    if ( is_wp_error( $response ) || 200 !== (int) wp_remote_retrieve_response_code( $response ) ) {
        return $update;
    }

    $manifest = json_decode( wp_remote_retrieve_body( $response ), true );
    $entry    = isset( $manifest['plugins']['wp-seo-micro'] ) ? $manifest['plugins']['wp-seo-micro'] : array();
    $version  = isset( $entry['version'] ) ? (string) $entry['version'] : '';
    $package  = isset( $entry['package'] ) ? (string) $entry['package'] : '';
    $current  = isset( $plugin_data['Version'] ) ? (string) $plugin_data['Version'] : '0';

    $is_valid_package = ( 0 === strpos( $package, 'https://raw.githubusercontent.com/GinCz/' ) )
                     || ( 0 === strpos( $package, 'https://github.com/GinCz/' ) );

    if ( '' === $version || '' === $package || ! $is_valid_package || ! version_compare( $version, $current, '>' ) ) {
        return $update;
    }

    return array(
        'id'           => 'https://vladimir-ai.updates/wp-seo-micro',
        'slug'         => 'wp-seo-micro',
        'plugin'       => $plugin_file,
        'version'      => $version,
        'new_version'  => $version,
        'url'          => isset( $entry['url'] ) ? (string) $entry['url'] : 'https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/Plugins/wp-seo-micro',
        'package'      => $package,
        'tested'       => isset( $entry['tested'] ) ? (string) $entry['tested'] : '6.8',
        'requires'     => isset( $entry['requires'] ) ? (string) $entry['requires'] : '6.0',
        'requires_php' => isset( $entry['requires_php'] ) ? (string) $entry['requires_php'] : '7.4',
    );
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_seo_get_settings() {
    $defaults = array(
        // Title & Meta
        'title_separator'            => '>',
        'home_title'                 => '',
        'home_description'           => '',
        'home_keywords'              => '',
        'append_sitename'            => 1,
        'enable_keywords'            => 1,
        'enable_og_tags'             => 1,
        'enable_twitter_cards'       => 1,
        'enable_canonical'           => 1,
        'enable_metabox'             => 0,

        // Robots & Indexation Controls
        'enable_smart_robots'        => 1,
        'noindex_search'             => 1,
        'noindex_404'                => 1,
        'noindex_paged'              => 1,
        'noindex_author'             => 1,
        'noindex_date'               => 1,
        'noindex_tags'               => 1,
        'noindex_attachments'        => 1,
        'google_snippet_directives'  => 1,
        'noindex_builders'           => 1,

        // Archives & Anti-Soft 404
        'enable_404_author'          => 1,
        'enable_404_date'            => 1,
        'enable_attachment_redirect' => 1,

        // XML Sitemap
        'enable_sitemap'             => 1,
        'enable_sitemap_images'      => 1,
        'sitemap_include_posts'      => 1,
        'sitemap_include_pages'      => 1,
        'sitemap_include_products'   => 1,
        'sitemap_include_cats'       => 1,
        'sitemap_include_product_cats'=> 1,
        'sitemap_include_brands'     => 1,

        // Image SEO
        'enable_image_seo'           => 1,
        'enable_auto_alt'            => 1,
        'enable_frontend_fallback_alt'=> 1,

        // Speed & Head Cleaner
        'enable_head_cleaner'        => 1,
        'clean_emojis'               => 1,
        'clean_generator'            => 1,
        'clean_rsd_wlw'              => 1,
        'clean_shortlink'            => 1,
        'clean_oembed'               => 1,
        'clean_hentry'               => 1,
        'clean_replytocom'           => 1,
        'clean_headers'              => 1,

        // Webmaster Verifications
        'google_verify'              => '',
        'bing_verify'                => '',
        'yandex_verify'              => '',
        'seznam_verify'              => '',
        'pinterest_verify'           => '',
        'baidu_verify'               => '',
        'facebook_verify'            => '',

        // Custom Code / Tracking
        'custom_head_code'           => '',
        'custom_body_open_code'      => '',
        'custom_footer_code'         => '',
    );
    $saved = get_option( '_vladimir_seo_settings', array() );
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
// 3. SETTINGS PAGE (Single-Page Dashboard in Settings)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'WP SEO Micro (VladiMIR+AI✅)',
        '🚀 WP SEO Micro',
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
        $txt_title    = 'WP SEO Micro: Панель поисковой оптимизации';
        $txt_subtitle = 'Полный набор инструментов SEO без тормозов: мета-теги, robots, XML карта сайта с картинками, очистка кода, авто-Alt и верификация.';
        $txt_saved    = 'Все настройки SEO успешно сохранены!';
        $txt_save_btn = 'Сохранить все настройки SEO';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'WP SEO Micro: Správa vyhledávačů (SEO)';
        $txt_subtitle = 'Kompletní sada SEO nástrojů bez zpomalení: meta tagy, robots, XML mapa stránek s obrázky, čištění kódu, auto-Alt a ověření.';
        $txt_saved    = 'Všechna SEO nastavení byla úspěšně uložena!';
        $txt_save_btn = 'Uložit všechna SEO nastavení';
    } else {
        $txt_title    = 'WP SEO Micro: Search Engine Optimization';
        $txt_subtitle = 'Ultra-lightweight complete SEO engine: Titles, Descriptions, Robots, XML Sitemap with Images, Image SEO, Code Cleaners, and Webmaster Verification.';
        $txt_saved    = 'All SEO settings successfully saved!';
        $txt_save_btn = 'Save All SEO Settings';
    }
    ?>
    <div class="wrap" style="max-width:920px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen,Ubuntu,Cantarell,sans-serif;">
        <h1 style="display:flex;align-items:center;gap:10px;margin-bottom:6px;">
            <span>🚀 <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 9px;border-radius:12px;font-weight:600;">(VladiMIR+AI✅)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;border-left-color:#10b981;">
                <p><strong>✅ <?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <!-- Sitemap Quick Access Box -->
        <div style="background:#f8fafc;border:1px solid #cbd5e1;padding:16px 20px;border-radius:8px;margin-bottom:24px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;">
                <div>
                    <h3 style="margin:0 0 4px 0;font-size:15px;display:flex;align-items:center;gap:8px;color:#0f172a;">
                        <span>🗺️ XML Карта сайта (Sitemap + Images)</span>
                        <span style="font-size:11px;background:#10b981;color:#fff;padding:2px 8px;border-radius:10px;font-weight:600;">Active 24/7</span>
                    </h3>
                    <p style="margin:0;color:#475569;font-size:13px;">
                        Генерируется на лету без нагрузки на MySQL, включает картинки и отдается по обоим стандартным адресам:
                    </p>
                </div>
                <div style="display:flex;gap:10px;flex-wrap:wrap;">
                    <a href="<?php echo esc_url( home_url( '/sitemap.xml' ) ); ?>" target="_blank" class="button button-primary" style="display:inline-flex;align-items:center;gap:6px;font-weight:600;">
                        <span>🌐 /sitemap.xml ↗</span>
                    </a>
                    <a href="<?php echo esc_url( home_url( '/sitemaps.xml' ) ); ?>" target="_blank" class="button button-secondary" style="display:inline-flex;align-items:center;gap:6px;">
                        <span>🌐 /sitemaps.xml ↗</span>
                    </a>
                </div>
            </div>
        </div>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
            <?php wp_nonce_field( 'vladimir_save_seo_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_seo_settings">

            <style>
                .vladimir-seo-card {
                    background: #fff;
                    border: 1px solid #e2e8f0;
                    border-radius: 8px;
                    padding: 20px 24px;
                    margin-bottom: 22px;
                    box-shadow: 0 1px 3px rgba(0,0,0,.03);
                }
                .vladimir-seo-card h2 {
                    margin-top: 0;
                    margin-bottom: 14px;
                    font-size: 16px;
                    color: #0f172a;
                    border-bottom: 1px solid #f1f5f9;
                    padding-bottom: 10px;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                .vladimir-opt-group {
                    display: flex;
                    flex-direction: column;
                    gap: 12px;
                    margin-top: 10px;
                }
                .vladimir-opt-group label {
                    font-weight: 600;
                    color: #1e293b;
                    font-size: 13.5px;
                }
                .vladimir-opt-group .desc {
                    margin-left: 24px;
                    margin-top: 2px;
                    color: #64748b;
                    font-size: 12.5px;
                    line-height: 1.4;
                }
                .vladimir-sub-opt {
                    margin-left: 24px;
                    padding-left: 12px;
                    border-left: 2px solid #e2e8f0;
                }
            </style>

            <!-- 1. Заголовки и мета-описания (Titles & Meta) -->
            <div class="vladimir-seo-card">
                <h2>🏷️ 1. Заголовки и основные мета-теги (Titles & Meta)</h2>
                
                <table class="form-table" role="presentation" style="margin-top:0;">
                    <tr>
                        <th scope="row" style="width:230px;"><label for="title_separator">Разделитель Title</label></th>
                        <td>
                            <input type="text" name="title_separator" id="title_separator" value="<?php echo esc_attr( $settings['title_separator'] ); ?>" style="width:60px;text-align:center;font-weight:bold;">
                            <span class="description" style="margin-left:8px;">Символ между названием страницы и именем сайта (по умолчанию: <code>&gt;</code> или <code>|</code>).</span>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="home_title">Custom Title главной</label></th>
                        <td>
                            <input type="text" name="home_title" id="home_title" value="<?php echo esc_attr( $settings['home_title'] ); ?>" class="large-text" placeholder="<?php echo esc_attr( get_bloginfo( 'name' ) ); ?>">
                            <p class="description">Если пусто — используется стандартное название сайта и описание.</p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="home_description">Meta Description главной</label></th>
                        <td>
                            <textarea name="home_description" id="home_description" rows="2" class="large-text"><?php echo esc_textarea( $settings['home_description'] ); ?></textarea>
                            <p class="description">Краткое описание для поисковиков Яндекс и Google (до 160 символов).</p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="home_keywords">Meta Keywords главной</label></th>
                        <td>
                            <input type="text" name="home_keywords" id="home_keywords" value="<?php echo esc_attr( $settings['home_keywords'] ); ?>" class="large-text" placeholder="шапки оптом, головные уборы, палантины">
                            <p class="description">Список ключевых фраз через запятую.</p>
                        </td>
                    </tr>
                </table>

                <div class="vladimir-opt-group">
                    <div>
                        <label><input type="checkbox" name="append_sitename" value="1" <?php checked( $settings['append_sitename'], 1 ); ?>> Добавлять название сайта к заголовкам (<code>Заголовок &gt; Название сайта</code>)</label>
                        <div class="desc">Автоматически формирует правильную иерархию сниппета для всех записей, страниц и товаров.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_keywords" value="1" <?php checked( $settings['enable_keywords'], 1 ); ?>> Генерировать метатег Keywords (<code>&lt;meta name="keywords"&gt;</code>)</label>
                        <div class="desc">Автоматически выводит ключевые слова из меток товара, рубрик или персонального SEO-поля.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_canonical" value="1" <?php checked( $settings['enable_canonical'], 1 ); ?>> Генерировать канонические ссылки (<code>&lt;link rel="canonical"&gt;</code>)</label>
                        <div class="desc">Защищает сайт от санкций за дублированный контент из-за GET-параметров и фильтров.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_og_tags" value="1" <?php checked( $settings['enable_og_tags'], 1 ); ?>> Open Graph разметка (<code>og:title, og:image, og:description</code>)</label>
                        <div class="desc">Красивые карточки при отправке ссылок в Telegram, WhatsApp, Facebook и ВК.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_twitter_cards" value="1" <?php checked( $settings['enable_twitter_cards'], 1 ); ?>> Twitter Card теги (<code>twitter:card, twitter:title</code>)</label>
                        <div class="desc">Разметка для превью ссылок на платформе X / Twitter.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_metabox" value="1" <?php checked( $settings['enable_metabox'], 1 ); ?>> Отображать SEO-метабокс в редакторе записей, страниц и товаров</label>
                        <div class="desc">Позволяет индивидуально настраивать Title, Description, Keywords и Noindex для любого материала.</div>
                    </div>
                </div>
            </div>

            <!-- 2. XML Карта сайта (XML Sitemap) -->
            <div class="vladimir-seo-card">
                <h2>🗺️ 2. Нативная XML Карта сайта (XML Sitemap Engine)</h2>
                
                <div class="vladimir-opt-group">
                    <div>
                        <label><input type="checkbox" name="enable_sitemap" value="1" <?php checked( $settings['enable_sitemap'], 1 ); ?>> Включить XML Карту Сайта (<code>/sitemap.xml</code> и <code>/sitemaps.xml</code>)</label>
                        <div class="desc">Главный переключатель встроенного движка XML sitemap со встроенным кэшированием в transients (12 часов).</div>
                    </div>

                    <div class="vladimir-sub-opt">
                        <label><input type="checkbox" name="enable_sitemap_images" value="1" <?php checked( $settings['enable_sitemap_images'], 1 ); ?>> Включать изображения в карту сайта (<code>&lt;image:image&gt;</code>)</label>
                        <div class="desc">Добавляет теги картинок для быстрой индексации в Google Images и Яндекс Картинках.</div>
                    </div>

                    <div class="vladimir-sub-opt">
                        <div style="font-weight:600;margin-bottom:6px;font-size:13px;color:#334155;">Включать типы записей и таксономии:</div>
                        <div style="display:grid;grid-template-columns:repeat(auto-fill, minmax(200px, 1fr));gap:8px;">
                            <label><input type="checkbox" name="sitemap_include_posts" value="1" <?php checked( $settings['sitemap_include_posts'], 1 ); ?>> Записи блога (<code>post</code>)</label>
                            <label><input type="checkbox" name="sitemap_include_pages" value="1" <?php checked( $settings['sitemap_include_pages'], 1 ); ?>> Страницы (<code>page</code>)</label>
                            <label><input type="checkbox" name="sitemap_include_products" value="1" <?php checked( $settings['sitemap_include_products'], 1 ); ?>> Товары (<code>product</code>)</label>
                            <label><input type="checkbox" name="sitemap_include_cats" value="1" <?php checked( $settings['sitemap_include_cats'], 1 ); ?>> Рубрики (<code>category</code>)</label>
                            <label><input type="checkbox" name="sitemap_include_product_cats" value="1" <?php checked( $settings['sitemap_include_product_cats'], 1 ); ?>> Категории товаров</label>
                            <label><input type="checkbox" name="sitemap_include_brands" value="1" <?php checked( $settings['sitemap_include_brands'], 1 ); ?>> Бренды товаров</label>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 3. Индексация и Robots (Advanced Robots & Crawl Budget) -->
            <div class="vladimir-seo-card">
                <h2>🤖 3. Управление индексацией и Robots (Crawl Budget Protection)</h2>
                
                <div class="vladimir-opt-group">
                    <div>
                        <label><input type="checkbox" name="enable_smart_robots" value="1" <?php checked( $settings['enable_smart_robots'], 1 ); ?>> Включить умное управление Robots мета-тегами</label>
                        <div class="desc">Автоматически защищает краулинговый бюджет от растраты на мусорные, дублирующие и служебные URL.</div>
                    </div>

                    <div class="vladimir-sub-opt">
                        <div style="font-weight:600;margin-bottom:6px;font-size:13px;color:#334155;">Ставить <code>noindex, follow</code> на страницы:</div>
                        <div style="display:grid;grid-template-columns:repeat(auto-fill, minmax(240px, 1fr));gap:8px;">
                            <label><input type="checkbox" name="noindex_search" value="1" <?php checked( $settings['noindex_search'], 1 ); ?>> Результаты поиска (<code>is_search</code>)</label>
                            <label><input type="checkbox" name="noindex_404" value="1" <?php checked( $settings['noindex_404'], 1 ); ?>> Страницы 404 (<code>is_404</code>)</label>
                            <label><input type="checkbox" name="noindex_paged" value="1" <?php checked( $settings['noindex_paged'], 1 ); ?>> Пагинация архивов (<code>/page/2/</code>)</label>
                            <label><input type="checkbox" name="noindex_author" value="1" <?php checked( $settings['noindex_author'], 1 ); ?>> Архивы авторов (<code>is_author</code>)</label>
                            <label><input type="checkbox" name="noindex_date" value="1" <?php checked( $settings['noindex_date'], 1 ); ?>> Архивы по датам (<code>is_date</code>)</label>
                            <label><input type="checkbox" name="noindex_tags" value="1" <?php checked( $settings['noindex_tags'], 1 ); ?>> Метки и теги (<code>is_tag</code>)</label>
                            <label><input type="checkbox" name="noindex_attachments" value="1" <?php checked( $settings['noindex_attachments'], 1 ); ?>> Медиавложения (<code>attachment</code>)</label>
                            <label><input type="checkbox" name="noindex_builders" value="1" <?php checked( $settings['noindex_builders'], 1 ); ?>> Шаблоны блоков (UX / Elementor)</label>
                        </div>
                    </div>

                    <div class="vladimir-sub-opt">
                        <label><input type="checkbox" name="google_snippet_directives" value="1" <?php checked( $settings['google_snippet_directives'], 1 ); ?>> Добавлять директивы расширенного сниппета (<code>max-image-preview:large, max-snippet:-1</code>)</label>
                        <div class="desc">Разрешает поисковикам показывать большие изображения в результатах Google Discover и выдаче.</div>
                    </div>
                </div>
            </div>

            <!-- 4. Тонкие архивы и честный 404 (Anti-Soft 404) -->
            <div class="vladimir-seo-card">
                <h2>🔀 4. Обработка мусорных архивов и Anti-Soft 404</h2>
                
                <div class="vladimir-opt-group">
                    <div>
                        <label><input type="checkbox" name="enable_404_author" value="1" <?php checked( $settings['enable_404_author'], 1 ); ?>> Честный HTTP 404 для архивов авторов (<code>/author/username/</code>)</label>
                        <div class="desc">Отдает истинный статус 404 Not Found для поисковых ботов, предотвращая предупреждения Google о Soft 404.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_404_date" value="1" <?php checked( $settings['enable_404_date'], 1 ); ?>> Честный HTTP 404 для архивов дат (<code>/2026/09/</code>)</label>
                        <div class="desc">Исключает дублирование записей по датам без надобности редиректить бота на главную.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_attachment_redirect" value="1" <?php checked( $settings['enable_attachment_redirect'], 1 ); ?>> Редирект вложений (attachments) на родительский пост, либо 404</label>
                        <div class="desc">Если у файла есть статья-родитель — 301 редирект на неё, если файл сирота — честный статус 404.</div>
                    </div>
                </div>
            </div>

            <!-- 5. SEO для изображений (Image SEO) -->
            <div class="vladimir-seo-card">
                <h2>🖼️ 5. SEO для изображений (Image SEO & Auto-Alt)</h2>
                
                <div class="vladimir-opt-group">
                    <div>
                        <label><input type="checkbox" name="enable_image_seo" value="1" <?php checked( $settings['enable_image_seo'], 1 ); ?>> Санитизация и транслитерация имен файлов при загрузке</label>
                        <div class="desc">Удаляет диакритику, спецсимволы и пробелы, переводя в чистый латинский URL-slug (<code>kvetina 01 (копия).jpg</code> ➔ <code>kvetina-01-kopiya.jpg</code>).</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_auto_alt" value="1" <?php checked( $settings['enable_auto_alt'], 1 ); ?>> Автозаполнение Alt-текста из имени файла при загрузке</label>
                        <div class="desc">Автоматически генерирует аккуратный читаемый Alt при добавлении картинок в Медиабиблиотеку.</div>
                    </div>
                    <div>
                        <label><input type="checkbox" name="enable_frontend_fallback_alt" value="1" <?php checked( $settings['enable_frontend_fallback_alt'], 1 ); ?>> Фронтенд Fallback Alt для пустых картинок</label>
                        <div class="desc">Если в коде статьи картинка не имеет <code>alt=""</code>, на лету подставляет фокусное ключевое слово или заголовок статьи.</div>
                    </div>
                </div>
            </div>

            <!-- 6. Очистка исходного кода и ускорение (Speed Cleaner) -->
            <div class="vladimir-seo-card">
                <h2>⚡ 6. Очистка исходного кода и ускорение (Head & Speed Cleaner)</h2>
                
                <div class="vladimir-opt-group">
                    <div>
                        <label><input type="checkbox" name="enable_head_cleaner" value="1" <?php checked( $settings['enable_head_cleaner'], 1 ); ?>> Включить модуль оптимизации исходного кода и заголовков</label>
                        <div class="desc">Удаляет лишние служебные теги WordPress, снижает размер HTML и защищает от сканеров уязвимостей.</div>
                    </div>

                    <div class="vladimir-sub-opt">
                        <div style="display:grid;grid-template-columns:repeat(auto-fill, minmax(260px, 1fr));gap:8px;">
                            <label><input type="checkbox" name="clean_emojis" value="1" <?php checked( $settings['clean_emojis'], 1 ); ?>> Удалить Emoji скрипты и стили</label>
                            <label><input type="checkbox" name="clean_generator" value="1" <?php checked( $settings['clean_generator'], 1 ); ?>> Удалить тег <code>wp_generator</code></label>
                            <label><input type="checkbox" name="clean_rsd_wlw" value="1" <?php checked( $settings['clean_rsd_wlw'], 1 ); ?>> Удалить RSD и WLW Manifest ссылки</label>
                            <label><input type="checkbox" name="clean_shortlink" value="1" <?php checked( $settings['clean_shortlink'], 1 ); ?>> Удалить Shortlink из Head и Header</label>
                            <label><input type="checkbox" name="clean_oembed" value="1" <?php checked( $settings['clean_oembed'], 1 ); ?>> Удалить oEmbed discovery ссылки</label>
                            <label><input type="checkbox" name="clean_hentry" value="1" <?php checked( $settings['clean_hentry'], 1 ); ?>> Удалить класс <code>hentry</code> (Search Console)</label>
                            <label><input type="checkbox" name="clean_replytocom" value="1" <?php checked( $settings['clean_replytocom'], 1 ); ?>> Очистить <code>?replytocom</code> в комментариях</label>
                            <label><input type="checkbox" name="clean_headers" value="1" <?php checked( $settings['clean_headers'], 1 ); ?>> Удалить заголовки <code>X-Pingback</code> и <code>X-Powered-By</code></label>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 7. Верификация вебмастеров (Webmaster Verification) -->
            <div class="vladimir-seo-card">
                <h2>🌐 7. Верификация вебмастеров (Search Engine Meta Tags)</h2>
                <p style="color:#64748b;font-size:13px;margin-top:0;">Введите только код верификации (содержимое атрибута <code>content</code>) или целый мета-тег целиком — движок очистит его автоматически:</p>

                <table class="form-table" role="presentation" style="margin-top:0;">
                    <tr>
                        <th scope="row" style="width:230px;"><label for="google_verify">Google Search Console</label></th>
                        <td><input type="text" name="google_verify" id="google_verify" value="<?php echo esc_attr( $settings['google_verify'] ); ?>" class="large-text" placeholder="e.g. AbCdEfGhIjKlMnOpQrStUvWxYz123456789"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="yandex_verify">Яндекс Вебмастер</label></th>
                        <td><input type="text" name="yandex_verify" id="yandex_verify" value="<?php echo esc_attr( $settings['yandex_verify'] ); ?>" class="large-text" placeholder="e.g. 7a8b9c0d1e2f3a4b"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="seznam_verify">Seznam.cz Webmaster</label></th>
                        <td><input type="text" name="seznam_verify" id="seznam_verify" value="<?php echo esc_attr( $settings['seznam_verify'] ); ?>" class="large-text" placeholder="e.g. f9a8b7c6d5e4f3a2"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="bing_verify">Bing Webmaster (msvalidate.01)</label></th>
                        <td><input type="text" name="bing_verify" id="bing_verify" value="<?php echo esc_attr( $settings['bing_verify'] ); ?>" class="large-text" placeholder="e.g. 1234567890ABCDEF1234567890ABCDEF"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="pinterest_verify">Pinterest Domain Verify</label></th>
                        <td><input type="text" name="pinterest_verify" id="pinterest_verify" value="<?php echo esc_attr( $settings['pinterest_verify'] ); ?>" class="large-text" placeholder="e.g. abcdef1234567890abcdef1234567890"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="baidu_verify">Baidu Webmaster</label></th>
                        <td><input type="text" name="baidu_verify" id="baidu_verify" value="<?php echo esc_attr( $settings['baidu_verify'] ); ?>" class="large-text" placeholder="e.g. code-xxxxxx"></td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="facebook_verify">Facebook Domain Verification</label></th>
                        <td><input type="text" name="facebook_verify" id="facebook_verify" value="<?php echo esc_attr( $settings['facebook_verify'] ); ?>" class="large-text" placeholder="e.g. 1234567890abcdef"></td>
                    </tr>
                </table>
            </div>

            <!-- 8. Пользовательский код / Скрипты (Tracking Code) -->
            <div class="vladimir-seo-card">
                <h2>📊 8. Пользовательский код и счетчики (Analytics / GTM / Tracking)</h2>
                <p style="color:#64748b;font-size:13px;margin-top:0;">Позволяет подключать Google Analytics, GTM, Яндекс.Метрику или пиксели напрямую без сторонних тяжелых плагинов:</p>

                <table class="form-table" role="presentation" style="margin-top:0;">
                    <tr>
                        <th scope="row" style="width:230px;"><label for="custom_head_code">Код внутри <code>&lt;head&gt;</code></label></th>
                        <td>
                            <textarea name="custom_head_code" id="custom_head_code" rows="3" class="large-text" style="font-family:monospace;font-size:12px;" placeholder="&lt;!-- Google tag (gtag.js) or GTM head code --&gt;"><?php echo esc_textarea( $settings['custom_head_code'] ); ?></textarea>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="custom_body_open_code">Код сразу после <code>&lt;body&gt;</code></label></th>
                        <td>
                            <textarea name="custom_body_open_code" id="custom_body_open_code" rows="2" class="large-text" style="font-family:monospace;font-size:12px;" placeholder="&lt;!-- Google Tag Manager (noscript) --&gt;"><?php echo esc_textarea( $settings['custom_body_open_code'] ); ?></textarea>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="custom_footer_code">Код перед закрытием <code>&lt;/body&gt;</code></label></th>
                        <td>
                            <textarea name="custom_footer_code" id="custom_footer_code" rows="2" class="large-text" style="font-family:monospace;font-size:12px;" placeholder="&lt;!-- Custom footer tracking / chat scripts --&gt;"><?php echo esc_textarea( $settings['custom_footer_code'] ); ?></textarea>
                        </td>
                    </tr>
                </table>
            </div>

            <p class="submit" style="margin-top:20px;">
                <input type="submit" name="submit" id="submit" class="button button-primary button-large" value="<?php echo esc_attr( $txt_save_btn ); ?>" style="font-weight:600;padding:6px 24px;font-size:15px;height:auto;">
            </p>
        </form>
    </div>
    <?php
}

// ─────────────────────────────────────────────
// 4. SETTINGS SAVE HANDLER
// ─────────────────────────────────────────────

add_action( 'admin_post_vladimir_save_seo_settings', function() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }
    check_admin_referer( 'vladimir_save_seo_settings', 'vladimir_nonce' );

    $clean_verify = function( $val ) {
        $val = trim( (string) $val );
        if ( preg_match( '/content=[\'"]([^\'"]+)[\'"]/i', $val, $m ) ) {
            return trim( $m[1] );
        }
        return sanitize_text_field( $val );
    };

    $updated = array(
        // Title & Meta
        'title_separator'            => sanitize_text_field( (string) ( $_POST['title_separator'] ?? '>' ) ),
        'home_title'                 => sanitize_text_field( (string) ( $_POST['home_title'] ?? '' ) ),
        'home_description'           => sanitize_textarea_field( (string) ( $_POST['home_description'] ?? '' ) ),
        'home_keywords'              => sanitize_text_field( (string) ( $_POST['home_keywords'] ?? '' ) ),
        'append_sitename'            => isset( $_POST['append_sitename'] ) ? 1 : 0,
        'enable_keywords'            => isset( $_POST['enable_keywords'] ) ? 1 : 0,
        'enable_og_tags'             => isset( $_POST['enable_og_tags'] ) ? 1 : 0,
        'enable_twitter_cards'       => isset( $_POST['enable_twitter_cards'] ) ? 1 : 0,
        'enable_canonical'           => isset( $_POST['enable_canonical'] ) ? 1 : 0,
        'enable_metabox'             => isset( $_POST['enable_metabox'] ) ? 1 : 0,

        // Robots & Indexation Controls
        'enable_smart_robots'        => isset( $_POST['enable_smart_robots'] ) ? 1 : 0,
        'noindex_search'             => isset( $_POST['noindex_search'] ) ? 1 : 0,
        'noindex_404'                => isset( $_POST['noindex_404'] ) ? 1 : 0,
        'noindex_paged'              => isset( $_POST['noindex_paged'] ) ? 1 : 0,
        'noindex_author'             => isset( $_POST['noindex_author'] ) ? 1 : 0,
        'noindex_date'               => isset( $_POST['noindex_date'] ) ? 1 : 0,
        'noindex_tags'               => isset( $_POST['noindex_tags'] ) ? 1 : 0,
        'noindex_attachments'        => isset( $_POST['noindex_attachments'] ) ? 1 : 0,
        'google_snippet_directives'  => isset( $_POST['google_snippet_directives'] ) ? 1 : 0,
        'noindex_builders'           => isset( $_POST['noindex_builders'] ) ? 1 : 0,

        // Archives & Anti-Soft 404
        'enable_404_author'          => isset( $_POST['enable_404_author'] ) ? 1 : 0,
        'enable_404_date'            => isset( $_POST['enable_404_date'] ) ? 1 : 0,
        'enable_attachment_redirect' => isset( $_POST['enable_attachment_redirect'] ) ? 1 : 0,

        // XML Sitemap
        'enable_sitemap'             => isset( $_POST['enable_sitemap'] ) ? 1 : 0,
        'enable_sitemap_images'      => isset( $_POST['enable_sitemap_images'] ) ? 1 : 0,
        'sitemap_include_posts'      => isset( $_POST['sitemap_include_posts'] ) ? 1 : 0,
        'sitemap_include_pages'      => isset( $_POST['sitemap_include_pages'] ) ? 1 : 0,
        'sitemap_include_products'   => isset( $_POST['sitemap_include_products'] ) ? 1 : 0,
        'sitemap_include_cats'       => isset( $_POST['sitemap_include_cats'] ) ? 1 : 0,
        'sitemap_include_product_cats'=> isset( $_POST['sitemap_include_product_cats'] ) ? 1 : 0,
        'sitemap_include_brands'     => isset( $_POST['sitemap_include_brands'] ) ? 1 : 0,

        // Image SEO
        'enable_image_seo'           => isset( $_POST['enable_image_seo'] ) ? 1 : 0,
        'enable_auto_alt'            => isset( $_POST['enable_auto_alt'] ) ? 1 : 0,
        'enable_frontend_fallback_alt'=> isset( $_POST['enable_frontend_fallback_alt'] ) ? 1 : 0,

        // Speed & Head Cleaner
        'enable_head_cleaner'        => isset( $_POST['enable_head_cleaner'] ) ? 1 : 0,
        'clean_emojis'               => isset( $_POST['clean_emojis'] ) ? 1 : 0,
        'clean_generator'            => isset( $_POST['clean_generator'] ) ? 1 : 0,
        'clean_rsd_wlw'              => isset( $_POST['clean_rsd_wlw'] ) ? 1 : 0,
        'clean_shortlink'            => isset( $_POST['clean_shortlink'] ) ? 1 : 0,
        'clean_oembed'               => isset( $_POST['clean_oembed'] ) ? 1 : 0,
        'clean_hentry'               => isset( $_POST['clean_hentry'] ) ? 1 : 0,
        'clean_replytocom'           => isset( $_POST['clean_replytocom'] ) ? 1 : 0,
        'clean_headers'              => isset( $_POST['clean_headers'] ) ? 1 : 0,

        // Webmaster Verifications
        'google_verify'              => $clean_verify( $_POST['google_verify'] ?? '' ),
        'bing_verify'                => $clean_verify( $_POST['bing_verify'] ?? '' ),
        'yandex_verify'              => $clean_verify( $_POST['yandex_verify'] ?? '' ),
        'seznam_verify'              => $clean_verify( $_POST['seznam_verify'] ?? '' ),
        'pinterest_verify'           => $clean_verify( $_POST['pinterest_verify'] ?? '' ),
        'baidu_verify'               => $clean_verify( $_POST['baidu_verify'] ?? '' ),
        'facebook_verify'            => $clean_verify( $_POST['facebook_verify'] ?? '' ),

        // Custom Code / Tracking (raw html/js allowed for admin)
        'custom_head_code'           => (string) ( $_POST['custom_head_code'] ?? '' ),
        'custom_body_open_code'      => (string) ( $_POST['custom_body_open_code'] ?? '' ),
        'custom_footer_code'         => (string) ( $_POST['custom_footer_code'] ?? '' ),
    );

    update_option( '_vladimir_seo_settings', $updated );
    delete_transient( '_wsm_sitemap' );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-seo-micro-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 5. TITLE TAG GENERATION
// ─────────────────────────────────────────────

add_filter( 'pre_get_document_title', function( $title ) {
    $settings  = vladimir_seo_get_settings();
    $sep       = ' ' . trim( $settings['title_separator'] ?: '>' ) . ' ';
    $site_name = get_bloginfo( 'name' );

    if ( is_front_page() || is_home() ) {
        if ( ! empty( $settings['home_title'] ) ) {
            return $settings['home_title'];
        }
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
                    array( $site_name, trim( $settings['title_separator'] ), get_bloginfo( 'description' ), get_the_title( $obj->ID ) ),
                    $custom_title
                ) );
            }

            $post_title = get_the_title( $obj->ID );
            return ! empty( $settings['append_sitename'] ) ? ( $post_title . $sep . $site_name ) : $post_title;
        }
    }

    if ( is_category() || is_tag() || is_tax() ) {
        $obj = get_queried_object();
        if ( $obj && ! empty( $obj->name ) ) {
            return ! empty( $settings['append_sitename'] ) ? ( $obj->name . $sep . $site_name ) : $obj->name;
        }
    }

    if ( is_404() ) {
        return ! empty( $settings['append_sitename'] ) ? ( '404' . $sep . $site_name ) : '404';
    }

    if ( is_search() ) {
        $locale = get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        $label  = ( 'ru' === $lang ) ? 'Поиск' : ( ( 'cs' === $lang ) ? 'Vyhledávání' : 'Search' );

        $search_title = $label . ': ' . get_search_query();
        return ! empty( $settings['append_sitename'] ) ? ( $search_title . $sep . $site_name ) : $search_title;
    }

    return $title;
}, 20 );

// ─────────────────────────────────────────────
// 6. ROBOTS META CONTROL
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

    if ( is_search() && ! empty( $settings['noindex_search'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_404() && ! empty( $settings['noindex_404'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_paged() && ! empty( $settings['noindex_paged'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_author() && ! empty( $settings['noindex_author'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_date() && ! empty( $settings['noindex_date'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( ( is_tag() || is_tax( 'product_tag' ) ) && ! empty( $settings['noindex_tags'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_attachment() && ! empty( $settings['noindex_attachments'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_singular( array( 'ux_block', 'wp_block', 'elementor_library' ) ) && ! empty( $settings['noindex_builders'] ) ) {
        echo "<meta name=\"robots\" content=\"noindex,nofollow\">\n";
        return;
    }

    // Clean indexable pages
    if ( is_front_page() || is_home() || is_singular( array( 'post', 'page', 'product' ) ) || is_category() || is_tax( 'product_cat' ) || is_tax( 'brand' ) || is_tax( 'product_brand' ) ) {
        $directives = ! empty( $settings['google_snippet_directives'] ) ? ',max-image-preview:large,max-snippet:-1,max-video-preview:-1' : '';
        echo "<meta name=\"robots\" content=\"index,follow" . esc_attr( $directives ) . "\">\n";
    }
}, 1 );

// ─────────────────────────────────────────────
// 7. META DESCRIPTION, KEYWORDS, CANONICAL, OPEN GRAPH, TWITTER & VERIFICATION
// ─────────────────────────────────────────────

add_action( 'wp_head', function() {
    $settings = vladimir_seo_get_settings();

    // 1. Webmaster Verifications
    $verifications = array(
        'google-site-verification'    => $settings['google_verify'] ?? '',
        'msvalidate.01'               => $settings['bing_verify'] ?? '',
        'yandex-verification'         => $settings['yandex_verify'] ?? '',
        'seznam-wmt'                  => $settings['seznam_verify'] ?? '',
        'p:domain_verify'             => $settings['pinterest_verify'] ?? '',
        'baidu-site-verification'     => $settings['baidu_verify'] ?? '',
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
        $title     = ! empty( $settings['home_title'] ) ? $settings['home_title'] : get_bloginfo( 'name' );
        $permalink = home_url( '/' );
    } elseif ( is_singular() ) {
        $obj = get_queried_object();
        if ( $obj ) {
            $title     = get_the_title( $obj->ID );
            $permalink = get_permalink( $obj->ID );
            $og_type   = is_single() ? 'article' : ( ( 'product' === $obj->post_type ) ? 'product' : 'website' );

            $custom_desc = get_post_meta( $obj->ID, '_wsm_description', true )
                        ?: get_post_meta( $obj->ID, '_seopress_titles_desc', true )
                        ?: get_post_meta( $obj->ID, '_yoast_wpseo_metadesc', true );

            if ( ! empty( $custom_desc ) ) {
                $desc = $custom_desc;
            } elseif ( ! empty( $obj->post_excerpt ) ) {
                $desc = wp_strip_all_tags( $obj->post_excerpt );
            } else {
                $desc = wp_trim_words( wp_strip_all_tags( $obj->post_content ), 28, '...' );
            }

            $custom_kw = get_post_meta( $obj->ID, '_wsm_keywords', true )
                      ?: get_post_meta( $obj->ID, '_seopress_analysis_target_kw', true )
                      ?: get_post_meta( $obj->ID, '_yoast_wpseo_focuskw', true );

            if ( ! empty( $custom_kw ) ) {
                $keywords = $custom_kw;
            } else {
                $tags = get_the_tags( $obj->ID );
                if ( ! empty( $tags ) && ! is_wp_error( $tags ) ) {
                    $keywords = implode( ', ', wp_list_pluck( $tags, 'name' ) );
                }
            }

            if ( has_post_thumbnail( $obj->ID ) ) {
                $og_img = get_the_post_thumbnail_url( $obj->ID, 'large' );
            }
        }
    } elseif ( is_category() || is_tag() || is_tax() ) {
        $obj = get_queried_object();
        if ( $obj ) {
            $title     = $obj->name;
            $permalink = get_term_link( $obj );
            $desc      = ! empty( $obj->description ) ? wp_strip_all_tags( $obj->description ) : '';
            $keywords  = $obj->name;
        }
    }

    $desc = trim( preg_replace( '/\s+/', ' ', (string) $desc ) );

    if ( ! empty( $desc ) ) {
        echo '<meta name="description" content="' . esc_attr( $desc ) . "\">\n";
    }

    if ( ! empty( $settings['enable_keywords'] ) && ! empty( $keywords ) ) {
        echo '<meta name="keywords" content="' . esc_attr( trim( (string) $keywords ) ) . "\">\n";
    }

    if ( ! empty( $settings['enable_canonical'] ) && ! empty( $permalink ) ) {
        echo '<link rel="canonical" href="' . esc_url( $permalink ) . "\">\n";
    }

    if ( ! empty( $settings['enable_og_tags'] ) ) {
        echo '<meta property="og:locale" content="' . esc_attr( get_locale() ) . "\">\n";
        echo '<meta property="og:type" content="' . esc_attr( $og_type ) . "\">\n";
        echo '<meta property="og:site_name" content="' . esc_attr( get_bloginfo( 'name' ) ) . "\">\n";
        if ( ! empty( $title ) ) {
            echo '<meta property="og:title" content="' . esc_attr( $title ) . "\">\n";
        }
        if ( ! empty( $desc ) ) {
            echo '<meta property="og:description" content="' . esc_attr( $desc ) . "\">\n";
        }
        if ( ! empty( $permalink ) ) {
            echo '<meta property="og:url" content="' . esc_url( $permalink ) . "\">\n";
        }
        if ( ! empty( $og_img ) ) {
            echo '<meta property="og:image" content="' . esc_url( $og_img ) . "\">\n";
        }
    }

    if ( ! empty( $settings['enable_twitter_cards'] ) ) {
        echo '<meta name="twitter:card" content="summary_large_image">' . "\n";
        if ( ! empty( $title ) ) {
            echo '<meta name="twitter:title" content="' . esc_attr( $title ) . "\">\n";
        }
        if ( ! empty( $desc ) ) {
            echo '<meta name="twitter:description" content="' . esc_attr( $desc ) . "\">\n";
        }
        if ( ! empty( $og_img ) ) {
            echo '<meta name="twitter:image" content="' . esc_url( $og_img ) . "\">\n";
        }
    }

    // Custom Head Code Injection
    if ( ! empty( $settings['custom_head_code'] ) ) {
        echo $settings['custom_head_code'] . "\n"; // phpcs:ignore WordPress.Security.EscapeOutput
    }
}, 2 );

// Body Open & Footer Code Injection
add_action( 'wp_body_open', function() {
    $settings = vladimir_seo_get_settings();
    if ( ! empty( $settings['custom_body_open_code'] ) ) {
        echo $settings['custom_body_open_code'] . "\n"; // phpcs:ignore WordPress.Security.EscapeOutput
    }
} );

add_action( 'wp_footer', function() {
    $settings = vladimir_seo_get_settings();
    if ( ! empty( $settings['custom_footer_code'] ) ) {
        echo $settings['custom_footer_code'] . "\n"; // phpcs:ignore WordPress.Security.EscapeOutput
    }
}, 99 );

// ─────────────────────────────────────────────
// 8. CODE & HEAD SPEED CLEANER
// ─────────────────────────────────────────────

add_action( 'init', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_head_cleaner'] ) ) {
        return;
    }

    // 1. Emoji cleaner
    if ( ! empty( $settings['clean_emojis'] ) ) {
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
    }

    // 2. Generator, RSD, WLW, Shortlink
    if ( ! empty( $settings['clean_generator'] ) ) {
        remove_action( 'wp_head', 'wp_generator' );
    }
    if ( ! empty( $settings['clean_rsd_wlw'] ) ) {
        remove_action( 'wp_head', 'rsd_link' );
        remove_action( 'wp_head', 'wlwmanifest_link' );
    }
    if ( ! empty( $settings['clean_shortlink'] ) ) {
        remove_action( 'wp_shortlink_wp_head', 10, 0 );
        remove_action( 'template_redirect', 'wp_shortlink_header', 11, 0 );
    }

    // 3. oEmbed discovery
    if ( ! empty( $settings['clean_oembed'] ) ) {
        remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
        remove_action( 'wp_head', 'wp_oembed_add_host_js' );
    }

    // 4. Clean ?replytocom query parameters
    if ( ! empty( $settings['clean_replytocom'] ) ) {
        add_filter( 'comment_reply_link', function( $link ) {
            return preg_replace( '/href=[\'"][^\'"]*[\?&]replytocom=(\d+)#([^\'"]*)[\'"]/', 'href="#$2"', $link );
        } );
    }
} );

// 5. Remove 'hentry' post class
add_filter( 'post_class', function( $classes ) {
    $settings = vladimir_seo_get_settings();
    if ( ! empty( $settings['enable_head_cleaner'] ) && ! empty( $settings['clean_hentry'] ) ) {
        $classes = array_diff( $classes, array( 'hentry' ) );
    }
    return $classes;
} );

// 6. Clean HTTP Headers
add_action( 'send_headers', function() {
    $settings = vladimir_seo_get_settings();
    if ( ! empty( $settings['enable_head_cleaner'] ) && ! empty( $settings['clean_headers'] ) ) {
        if ( function_exists( 'header_remove' ) ) {
            header_remove( 'X-Pingback' );
            header_remove( 'X-Powered-By' );
        }
    }
} );

// ─────────────────────────────────────────────
// 9. ARCHIVES & THIN CONTENT (Anti-Soft 404)
// ─────────────────────────────────────────────

add_action( 'template_redirect', function() {
    global $wp_query;
    $settings = vladimir_seo_get_settings();

    if ( is_author() && ! empty( $settings['enable_404_author'] ) ) {
        $wp_query->set_404();
        status_header( 404 );
        nocache_headers();
        return;
    }

    if ( is_date() && ! empty( $settings['enable_404_date'] ) ) {
        $wp_query->set_404();
        status_header( 404 );
        nocache_headers();
        return;
    }

    if ( is_attachment() && ! empty( $settings['enable_attachment_redirect'] ) ) {
        $parent_id = wp_get_post_parent_id( get_queried_object_id() );
        if ( $parent_id ) {
            wp_safe_redirect( get_permalink( $parent_id ), 301 );
            exit;
        }
        $wp_query->set_404();
        status_header( 404 );
        nocache_headers();
    }
} );

// ─────────────────────────────────────────────
// 10. AUTOMATED IMAGE SEO (Sanitization & Auto-Alt)
// ─────────────────────────────────────────────

// 1. Sanitize file name upon upload
add_filter( 'sanitize_file_name', function( $filename ) {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_image_seo'] ) ) {
        return $filename;
    }

    $info = pathinfo( $filename );
    $ext  = empty( $info['extension'] ) ? '' : '.' . $info['extension'];
    $name = $info['filename'];

    if ( function_exists( 'remove_accents' ) ) {
        $name = remove_accents( $name );
    }

    $name = strtolower( $name );
    $name = preg_replace( '/[^a-z0-9_-]/', '-', $name );
    $name = preg_replace( '/-+/', '-', $name );
    $name = trim( $name, '-' );

    return ( $name ?: 'media' ) . strtolower( $ext );
}, 10, 1 );

// 2. Automatically generate Alt text upon media upload
add_action( 'add_attachment', function( $post_id ) {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_image_seo'] ) || empty( $settings['enable_auto_alt'] ) ) {
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

// 3. Frontend Fallback Alt
add_filter( 'the_content', function( $content ) {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_image_seo'] ) || empty( $settings['enable_frontend_fallback_alt'] ) || ! is_singular() ) {
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
// 11. NATIVE XML SITEMAP ENGINE (/sitemap.xml & /sitemaps.xml)
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

    // 2. Custom Post Types
    $post_types = array();
    if ( ! empty( $settings['sitemap_include_posts'] ) ) {
        $post_types[] = 'post';
    }
    if ( ! empty( $settings['sitemap_include_pages'] ) ) {
        $post_types[] = 'page';
    }
    if ( ! empty( $settings['sitemap_include_products'] ) && post_type_exists( 'product' ) ) {
        $post_types[] = 'product';
    }

    if ( ! empty( $post_types ) ) {
        $posts = get_posts( array(
            'post_type'        => $post_types,
            'posts_per_page'   => 3000,
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
    }

    // 3. Taxonomies
    $taxonomies = array();
    if ( ! empty( $settings['sitemap_include_cats'] ) ) {
        $taxonomies[] = 'category';
    }
    if ( ! empty( $settings['sitemap_include_product_cats'] ) && taxonomy_exists( 'product_cat' ) ) {
        $taxonomies[] = 'product_cat';
    }
    if ( ! empty( $settings['sitemap_include_brands'] ) ) {
        if ( taxonomy_exists( 'brand' ) ) {
            $taxonomies[] = 'brand';
        }
        if ( taxonomy_exists( 'product_brand' ) ) {
            $taxonomies[] = 'product_brand';
        }
    }

    if ( ! empty( $taxonomies ) ) {
        $terms = get_terms( array(
            'taxonomy'   => $taxonomies,
            'hide_empty' => true,
        ) );

        if ( ! is_wp_error( $terms ) ) {
            foreach ( $terms as $t ) {
                echo '  <url><loc>' . esc_url( get_term_link( $t ) ) . '</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>' . "\n";
            }
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

// robots.txt Sitemap injection
add_filter( 'robots_txt', function( $output, $public ) {
    $settings = vladimir_seo_get_settings();
    if ( ! empty( $settings['enable_sitemap'] ) ) {
        $sitemap_url = home_url( '/sitemap.xml' );
        if ( false === strpos( $output, $sitemap_url ) ) {
            $output = trim( $output ) . "\n\nSitemap: " . esc_url( $sitemap_url ) . "\n";
        }
    }
    return $output;
}, 20, 2 );

// ─────────────────────────────────────────────
// 12. SEO METABOX FOR EDITORS (Classic & Gutenberg)
// ─────────────────────────────────────────────

add_action( 'add_meta_boxes', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_metabox'] ) ) {
        return;
    }

    $screens = array( 'post', 'page' );
    if ( post_type_exists( 'product' ) ) {
        $screens[] = 'product';
    }

    foreach ( $screens as $screen ) {
        add_meta_box(
            'vladimir_seo_metabox',
            '🚀 WP SEO Micro (VladiMIR+AI✅)',
            'vladimir_seo_render_metabox',
            $screen,
            'normal',
            'high'
        );
    }
} );

function vladimir_seo_render_metabox( $post ) {
    wp_nonce_field( 'vladimir_seo_metabox_save', 'vladimir_seo_metabox_nonce' );

    $title       = get_post_meta( $post->ID, '_wsm_title', true ) ?: get_post_meta( $post->ID, '_seopress_titles_title', true );
    $description = get_post_meta( $post->ID, '_wsm_description', true ) ?: get_post_meta( $post->ID, '_seopress_titles_desc', true );
    $keywords    = get_post_meta( $post->ID, '_wsm_keywords', true ) ?: get_post_meta( $post->ID, '_seopress_analysis_target_kw', true );
    $noindex     = get_post_meta( $post->ID, '_wsm_noindex', true ) ?: ( get_post_meta( $post->ID, '_seopress_robots_index', true ) === 'yes' ? '1' : '0' );
    ?>
    <div style="display:flex;flex-direction:column;gap:12px;padding:8px 0;">
        <div>
            <label for="wsm_title" style="font-weight:600;display:block;margin-bottom:4px;">SEO Title (Заголовок в выдаче):</label>
            <input type="text" name="wsm_title" id="wsm_title" value="<?php echo esc_attr( $title ); ?>" style="width:100%;" placeholder="Оставьте пустым для автогенерации (%%post_title%% &gt; %%sitename%%)">
        </div>

        <div>
            <label for="wsm_description" style="font-weight:600;display:block;margin-bottom:4px;">Meta Description (Описание для сниппета):</label>
            <textarea name="wsm_description" id="wsm_description" rows="2" style="width:100%;" placeholder="До 160 символов. Если пусто — формируется из цитаты или текста."><?php echo esc_textarea( $description ); ?></textarea>
        </div>

        <div>
            <label for="wsm_keywords" style="font-weight:600;display:block;margin-bottom:4px;">Meta Keywords (Фокусные ключевые слова):</label>
            <input type="text" name="wsm_keywords" id="wsm_keywords" value="<?php echo esc_attr( $keywords ); ?>" style="width:100%;" placeholder="ключевые слова через запятую (также используются для Alt картинок)">
        </div>

        <div>
            <label style="font-weight:600;cursor:pointer;">
                <input type="checkbox" name="wsm_noindex" value="1" <?php checked( $noindex, '1' ); ?>>
                Закрыть эту страницу от индексации поисковиками (<code>noindex, follow</code>)
            </label>
        </div>
    </div>
    <?php
}

add_action( 'save_post', function( $post_id ) {
    if ( ! isset( $_POST['vladimir_seo_metabox_nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['vladimir_seo_metabox_nonce'] ) ), 'vladimir_seo_metabox_save' ) ) {
        return;
    }
    if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
        return;
    }
    if ( ! current_user_can( 'edit_post', $post_id ) ) {
        return;
    }

    if ( isset( $_POST['wsm_title'] ) ) {
        update_post_meta( $post_id, '_wsm_title', sanitize_text_field( wp_unslash( $_POST['wsm_title'] ) ) );
    }
    if ( isset( $_POST['wsm_description'] ) ) {
        update_post_meta( $post_id, '_wsm_description', sanitize_textarea_field( wp_unslash( $_POST['wsm_description'] ) ) );
    }
    if ( isset( $_POST['wsm_keywords'] ) ) {
        update_post_meta( $post_id, '_wsm_keywords', sanitize_text_field( wp_unslash( $_POST['wsm_keywords'] ) ) );
    }

    $noindex = ! empty( $_POST['wsm_noindex'] ) ? '1' : '0';
    update_post_meta( $post_id, '_wsm_noindex', $noindex );
} );
