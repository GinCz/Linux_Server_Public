<?php
/**
 * Plugin Name: WP SEO Micro (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-seo-micro
 * Description: Ultra-lightweight SEO engine: Smart Title, Meta Description & Keywords, Open Graph social tags, canonical URLs, full robots indexation control, native XML sitemap (/sitemap.xml & /sitemaps.xml), and seamless backward compatibility with SEOPress metadata. Zero database bloat.
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: wp-seo-micro
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_seo_get_settings() {
    $defaults = array(
        'title_separator'     => '>',
        'enable_og_tags'      => 1,
        'enable_canonical'    => 1,
        'enable_smart_robots' => 1,
        'enable_sitemap'      => 1,
        'enable_keywords'     => 1,
        'enable_metabox'      => 1,
        'home_description'    => '',
        'home_keywords'       => '',
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-seo-micro-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-seo-micro" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'WP SEO Micro (VladiMIR+AI)',
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
        $txt_subtitle = 'Управление Title, Description, Keywords, Open Graph, robots и XML Sitemap с поддержкой старых данных SEOPress.';
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
        $txt_rob_desc = 'Закрывает от индексации страницы поиска, архивы дат, авторов, вложения и пагинацию.';
        $txt_map      = 'Включить нативную XML Карту Сайта (/sitemap.xml и /sitemaps.xml)';
        $txt_map_desc = 'Быстрая карта сайта для поисковиков: ' . home_url( '/sitemap.xml' ) . ' (и поддержка /sitemaps.xml).';
        $txt_kw_en    = 'Генерировать метатег Keywords (<meta name="keywords">)';
        $txt_kw_desc  = 'Автоматически выводит ключевые слова из меток товара, рубрик или персонального SEO-поля.';
        $txt_box      = 'Отображать SEO Метабокс в редакторе записей и товаров';
        $txt_box_desc = 'Позволяет задавать персональный Title, Meta Description и Keywords при редактировании страницы.';
        $txt_save     = 'Сохранить настройки';
        $txt_legacy   = '🛡️ <strong>Совместимость с SEOPress:</strong> Плагин автоматически подхватывает Title, Description, Keywords, Canonical URL и Noindex из полей SEOPress (_seopress_*), гарантируя нулевую потерю позиций при отключении тяжелого плагина SEOPress.';
    } elseif ( 'cs' === $lang ) {
        $txt_title    = 'WP SEO Micro: Nastavení vyhledávačů (SEO)';
        $txt_subtitle = 'Správa titulků, meta popisků, klíčových slov, Open Graph tagů, robots a XML mapy stránek s podporou starých dat SEOPress.';
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
        $txt_rob_desc = 'Zakazuje indexaci vyhledávání, archivů a stránkování.';
        $txt_map      = 'Povolit nativní XML mapu stránek (/sitemap.xml)';
        $txt_map_desc = 'Rychlá mapa stránek pro vyhledávače: ' . home_url( '/sitemap.xml' ) . '.';
        $txt_kw_en    = 'Generovat meta tag Keywords';
        $txt_kw_desc  = 'Automaticky doplňuje klíčová slova ze štítků a kategorií.';
        $txt_box      = 'Zobrazovat SEO pole v editoru příspěvků a produktů';
        $txt_box_desc = 'Umožňuje upravit Title, Description a Keywords každé stránky.';
        $txt_save     = 'Uložit nastavení';
        $txt_legacy   = '🛡️ <strong>Kompatibilita se SEOPress:</strong> Plugin automaticky načítá dříve uložené titulky i popisky ze SEOPressu.';
    } else {
        $txt_title    = 'WP SEO Micro: Search Engine Optimization Settings';
        $txt_subtitle = 'Smart Titles, Meta Descriptions, Keywords, Open Graph tags, canonical URLs, robots control, and native XML sitemap with SEOPress backward compatibility.';
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
        $txt_rob_desc = 'Adds noindex to search results, author archives, date archives, and pagination.';
        $txt_map      = 'Enable Native XML Sitemap (/sitemap.xml & /sitemaps.xml)';
        $txt_map_desc = 'High-performance sitemap at: ' . home_url( '/sitemap.xml' ) . '.';
        $txt_kw_en    = 'Generate Meta Keywords tag (<meta name="keywords">)';
        $txt_kw_desc  = 'Pulls keywords from product tags, categories, or custom fields.';
        $txt_box      = 'Display SEO Meta Box in Post & Product Editors';
        $txt_box_desc = 'Allows setting custom Title, Meta Description, and Keywords per item.';
        $txt_save     = 'Save Settings';
        $txt_legacy   = '🛡️ <strong>SEOPress Compatibility:</strong> Automatically reads historical _seopress_* title, description, keywords, and canonical metadata.';
    }
    ?>
    <div class="wrap" style="max-width:850px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🚀 <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
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
                <span>🗺️ Карта сайта (XML Sitemap)</span>
                <span style="font-size:11px;background:#10b981;color:#fff;padding:2px 8px;border-radius:10px;font-weight:600;">Активна 24/7</span>
            </h3>
            <p style="margin-bottom:14px;color:#475569;font-size:13px;line-height:1.5;">
                Карта сайта формируется на лету без лишней нагрузки на базу данных и доступна сразу по обоим стандартным адресам для роботов Яндекс и Google:
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
                    <th scope="row"><strong>Опции SEO</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:10px;">
                            <label>
                                <input type="checkbox" name="enable_og_tags" value="1" <?php checked( $settings['enable_og_tags'], 1 ); ?>>
                                <?php echo esc_html( $txt_og ); ?>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-6px;"><?php echo esc_html( $txt_og_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_canonical" value="1" <?php checked( $settings['enable_canonical'], 1 ); ?>>
                                <?php echo esc_html( $txt_can ); ?>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-6px;"><?php echo esc_html( $txt_can_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_smart_robots" value="1" <?php checked( $settings['enable_smart_robots'], 1 ); ?>>
                                <?php echo esc_html( $txt_rob ); ?>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-6px;"><?php echo esc_html( $txt_rob_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_sitemap" value="1" <?php checked( $settings['enable_sitemap'], 1 ); ?>>
                                <?php echo esc_html( $txt_map ); ?>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-6px;"><?php echo esc_html( $txt_map_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_keywords" value="1" <?php checked( $settings['enable_keywords'], 1 ); ?>>
                                <?php echo esc_html( $txt_kw_en ); ?>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-6px;"><?php echo esc_html( $txt_kw_desc ); ?></p>

                            <label>
                                <input type="checkbox" name="enable_metabox" value="1" <?php checked( $settings['enable_metabox'], 1 ); ?>>
                                <?php echo esc_html( $txt_box ); ?>
                            </label>
                            <p class="description" style="margin-left:24px;margin-top:-6px;"><?php echo esc_html( $txt_box_desc ); ?></p>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save, 'primary', 'submit', false ); ?>
            </div>
        </form>

        <p style="margin-top:15px;color:#64748b;font-size:12px;">
            ⚡ <strong>VladiMIR+AI WordPress Suite</strong> &bull;
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-seo-micro" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_seo_settings', function() {
    check_admin_referer( 'vladimir_save_seo_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

    $updated = array(
        'title_separator'     => sanitize_text_field( (string) ( $_POST['title_separator'] ?? '>' ) ),
        'enable_og_tags'      => isset( $_POST['enable_og_tags'] ) ? 1 : 0,
        'enable_canonical'    => isset( $_POST['enable_canonical'] ) ? 1 : 0,
        'enable_smart_robots' => isset( $_POST['enable_smart_robots'] ) ? 1 : 0,
        'enable_sitemap'      => isset( $_POST['enable_sitemap'] ) ? 1 : 0,
        'enable_keywords'     => isset( $_POST['enable_keywords'] ) ? 1 : 0,
        'enable_metabox'      => isset( $_POST['enable_metabox'] ) ? 1 : 0,
        'home_description'    => sanitize_textarea_field( (string) ( $_POST['home_description'] ?? '' ) ),
        'home_keywords'       => sanitize_text_field( (string) ( $_POST['home_keywords'] ?? '' ) ),
    );

    update_option( '_vladimir_seo_settings', $updated );

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

    if ( is_category() || is_tax( 'product_cat' ) ) {
        $obj = get_queried_object();
        if ( $obj ) {
            return $obj->name . $sep . $site_name;
        }
    }

    if ( is_tag() || is_tax() ) {
        $obj = get_queried_object();
        if ( $obj ) {
            return $obj->name . $sep . $site_name;
        }
    }

    if ( is_404() ) {
        return '404' . $sep . $site_name;
    }

    if ( is_search() ) {
        return sprintf( 'Поиск: %s', get_search_query() ) . $sep . $site_name;
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

    if ( is_search() || is_404() || is_author() || is_date() || is_attachment() || is_tag() || is_tax( 'product_tag' ) || is_tax( 'post_format' ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_paged() ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
    }

    if ( is_singular( array( 'ux_block', 'wp_block', 'elementor_library' ) ) ) {
        echo "<meta name=\"robots\" content=\"noindex,nofollow\">\n";
        return;
    }

    if ( is_front_page() || is_home() || is_singular( array( 'post', 'page', 'product' ) ) || is_category() || is_tax( 'product_cat' ) ) {
        echo "<meta name=\"robots\" content=\"index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1\">\n";
    }
}, 1 );

// ─────────────────────────────────────────────
// 6. META DESCRIPTION, KEYWORDS, CANONICAL & OPEN GRAPH
// ─────────────────────────────────────────────

add_action( 'wp_head', function() {
    $settings = vladimir_seo_get_settings();

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
                $raw  = wp_strip_all_tags( $obj->post_excerpt ?: $obj->post_content );
                $desc = mb_substr( preg_replace( '/\s+/', ' ', $raw ), 0, 160 );
            }

            // Keywords resolution: custom metabox -> SEOPress target keywords -> Yoast focus kw -> auto tags/categories
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
    } elseif ( is_category() || is_tax( 'product_cat' ) ) {
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
// 7. NATIVE XML SITEMAP ENGINE (/sitemap.xml & /sitemaps.xml)
// ─────────────────────────────────────────────

add_action( 'init', function() {
    $settings = vladimir_seo_get_settings();
    if ( empty( $settings['enable_sitemap'] ) ) {
        return;
    }

    $uri = isset( $_SERVER['REQUEST_URI'] ) ? (string) $_SERVER['REQUEST_URI'] : '';
    if ( ! preg_match( '/\b(sitemap|sitemaps|sitemap_index)\.xml\b/i', $uri ) ) {
        return;
    }

    header( 'Content-Type: application/xml; charset=utf-8' );
    echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n";

    // Homepage
    echo '  <url><loc>' . esc_url( home_url( '/' ) ) . '</loc><changefreq>daily</changefreq><priority>1.0</priority></url>' . "\n";

    // Posts, Pages, Products
    $post_types = array( 'post', 'page' );
    if ( post_type_exists( 'product' ) ) {
        $post_types[] = 'product';
    }

    $posts = get_posts( array(
        'post_type'        => $post_types,
        'posts_per_page'   => 2000,
        'post_status'      => 'publish',
        'orderby'          => 'modified',
        'order'            => 'DESC',
        'suppress_filters' => true,
    ) );

    foreach ( $posts as $p ) {
        $date = get_the_modified_date( 'c', $p->ID );
        $prio = ( 'page' === $p->post_type ) ? '0.8' : ( ( 'product' === $p->post_type ) ? '0.9' : '0.7' );
        echo '  <url><loc>' . esc_url( get_permalink( $p->ID ) ) . '</loc><lastmod>' . esc_xml( $date ) . '</lastmod><changefreq>weekly</changefreq><priority>' . $prio . '</priority></url>' . "\n";
    }

    // Categories
    $taxonomies = array( 'category' );
    if ( taxonomy_exists( 'product_cat' ) ) {
        $taxonomies[] = 'product_cat';
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
    exit;
} );

// ─────────────────────────────────────────────
// 8. POST METABOX
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

    add_meta_box( 'wsm_seo', 'SEO (VladiMIR+AI)', function( $post ) {
        wp_nonce_field( 'wsm_save', 'wsm_nonce' );
        $title    = esc_attr( get_post_meta( $post->ID, '_wsm_title', true ) ?: get_post_meta( $post->ID, '_seopress_titles_title', true ) );
        $desc     = esc_textarea( get_post_meta( $post->ID, '_wsm_desc', true ) ?: get_post_meta( $post->ID, '_seopress_titles_desc', true ) );
        $keywords = esc_attr( get_post_meta( $post->ID, '_wsm_keywords', true ) ?: get_post_meta( $post->ID, '_seopress_analysis_target_kw', true ) ?: get_post_meta( $post->ID, '_yoast_wpseo_focuskw', true ) );

        echo '<p><label><strong>SEO Title:</strong><br><input type="text" name="wsm_title" value="' . $title . '" style="width:100%" maxlength="70" placeholder="' . esc_attr( get_the_title( $post->ID ) . ' > ' . get_bloginfo( 'name' ) ) . '"></label></p>';
        echo '<p><label><strong>Meta Description:</strong><br><textarea name="wsm_desc" rows="3" style="width:100%" maxlength="160" placeholder="Краткое описание страницы для сниппета в поисковике...">' . $desc . '</textarea></label></p>';
        echo '<p><label><strong>Meta Keywords (Ключевые слова через запятую):</strong><br><input type="text" name="wsm_keywords" value="' . $keywords . '" style="width:100%" placeholder="шапки оптом, головные уборы, купить шапки (если пусто — берутся метки и рубрики)"></label></p>';
    }, $post_types, 'normal', 'high' );
} );

add_action( 'save_post', function( $post_id ) {
    if ( ! isset( $_POST['wsm_nonce'] ) || ! wp_verify_nonce( $_POST['wsm_nonce'], 'wsm_save' ) ) {
        return;
    }
    if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
        return;
    }
    if ( ! current_user_can( 'edit_post', $post_id ) ) {
        return;
    }

    if ( isset( $_POST['wsm_title'] ) ) {
        update_post_meta( $post_id, '_wsm_title', sanitize_text_field( $_POST['wsm_title'] ) );
    }
    if ( isset( $_POST['wsm_desc'] ) ) {
        update_post_meta( $post_id, '_wsm_desc', sanitize_textarea_field( $_POST['wsm_desc'] ) );
    }
    if ( isset( $_POST['wsm_keywords'] ) ) {
        update_post_meta( $post_id, '_wsm_keywords', sanitize_text_field( $_POST['wsm_keywords'] ) );
    }
} );

// ─────────────────────────────────────────────
// 9. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function( $plugins ) {
    $plugin_key = plugin_basename( __FILE__ );
    if ( isset( $plugins[ $plugin_key ] ) ) {
        $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
        $lang   = strtolower( substr( $locale, 0, 2 ) );
        if ( 'ru' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP SEO Micro (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Сверхлегкий SEO-движок: умные Title, Description и Keywords, Open Graph разметка, канонические URL, XML Sitemap (/sitemap.xml и /sitemaps.xml), поддержка старых метатегов SEOPress без потери позиций.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'WP SEO Micro (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Ultra lehký SEO modul: titulky, meta popisy, klíčová slova, Open Graph, canonical, XML mapa stránek a plná kompatibilita se SEOPress.';
        }
    }
    return $plugins;
} );
