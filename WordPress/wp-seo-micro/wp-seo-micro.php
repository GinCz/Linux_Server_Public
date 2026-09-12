<?php
/**
 * Plugin Name: WP SEO Micro (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-seo-micro
 * Description: Ultra-lightweight SEO engine: Smart Title & Meta Description, Open Graph social tags, canonical URLs, full robots indexation control, and native XML sitemap (posts, pages, products, categories). Zero database bloat.
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
     = array(
        'title_separator'     => '>',
        'enable_og_tags'      => 1,
        'enable_canonical'    => 1,
        'enable_smart_robots' => 1,
        'enable_sitemap'      => 1,
        'enable_metabox'      => 1,
        'home_description'    => '',
    );
     = get_option( '_vladimir_seo_settings', array() );
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

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-seo-micro-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/wp-seo-micro" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
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

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_seo_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'WP SEO Micro: Настройки поисковой оптимизации';
                = 'Управление генерацией тегов Title, метаописаний, разметки Open Graph, robots и XML Sitemap.';
               = 'Настройки успешно сохранены!';
                 = 'Разделитель в теге Title';
            = 'Символ между названием страницы и именем сайта (по умолчанию: &gt;).';
           = 'Meta Description главной страницы';
           = 'Краткое описание сайта для поисковой выдачи Яндекс и Google (до 160 символов).';
                  = 'Включить разметку Open Graph (og:title, og:image, og:description)';
             = 'Формирует привлекательные сниппеты ссылок при публикации в соцсетях и мессенджерах.';
           = 'Генерировать канонические ссылки (canonical URL)';
          = 'Защищает от дублей страниц в индексе поисковых систем.';
              = 'Умное управление индексацией Robots (noindex на мусорные страницы)';
            = 'Закрывает от индексации страницы поиска, архивы дат, авторов, вложения и пагинацию.';
             = 'Включить нативную XML Карту Сайта (/sitemap.xml)';
            = 'Быстрая карта сайта для поисковиков: ' . home_url( '/sitemap.xml' ) . ' (0 лишних таблиц).';
             = 'Отображать SEO Метабокс в редакторе записей и товаров';
           = 'Позволяет задавать персональный Title и Meta Description при редактировании страницы.';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'WP SEO Micro: Nastavení vyhledávačů (SEO)';
                = 'Správa titulků, meta popisků, Open Graph tagů, robots a XML mapy stránek.';
               = 'Nastavení bylo úspěšně uloženo!';
                 = 'Oddělovač v titulku (Title)';
            = 'Znak mezi názvem stránky a webu (výchozí: &gt;).';
           = 'Meta Description hlavní stránky';
           = 'Popis webu pro zobrazení ve výsledcích vyhledávání Google a Seznam.';
                  = 'Povolit Open Graph tagy pro sociální sítě';
             = 'Vytváří náhledy odkazů při sdílení.';
           = 'Generovat kanonická URL (canonical)';
          = 'Chrání před duplicitním obsahem.';
              = 'Chytrá správa robots (noindex pro zbytečné archivy)';
            = 'Uzavírá vyhledávání a archivy před indexací.';
             = 'Povolit nativní XML Sitemap (/sitemap.xml)';
            = 'Rychlá mapa stránek pro vyhledávače: ' . home_url( '/sitemap.xml' );
             = 'Zobrazit SEO panel při editaci příspěvků a produktů';
           = 'Umožňuje upravit Title a Description přímo v editoru.';
            = 'Uložit nastavení';
    } else {
               = 'WP SEO Micro: Search Engine Optimization Settings';
                = 'Manage smart titles, meta descriptions, Open Graph, robots rules, and XML sitemaps.';
               = 'Settings successfully saved!';
                 = 'Title Separator';
            = 'Character between post title and site name (default: &gt;).';
           = 'Homepage Meta Description';
           = 'Summary snippet displayed in Google search results (up to 160 characters).';
                  = 'Enable Open Graph Social Tags (og:title, og:image, og:desc)';
             = 'Generates rich link previews for messengers and social platforms.';
           = 'Generate Canonical Link Tags';
          = 'Eliminates duplicate content issues across URL variations.';
              = 'Smart Robots Meta Control (noindex on junk archives)';
            = 'Adds noindex to search results, date archives, author archives, and paged feeds.';
             = 'Enable Native XML Sitemap (/sitemap.xml)';
            = 'Fast sitemap for search bots: ' . home_url( '/sitemap.xml' );
             = 'Show SEO Metabox in Post and Product Editors';
           = 'Allows setting custom Title and Meta Description per entry.';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>🚀 <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_seo_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_seo_settings">

            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><label for="title_separator"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="text" name="title_separator" id="title_separator" value="<?php echo esc_attr( ['title_separator'] ); ?>" class="small-text" style="text-align:center;">
                        <span style="margin-left:10px;color:#64748b;">(Например: &gt; &bull; | &bull; - &bull; •)</span>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="home_description"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <textarea name="home_description" id="home_description" rows="3" class="large-text" maxlength="170" placeholder="Краткое описание сайта для сниппета в поисковиках..."><?php echo esc_textarea( ['home_description'] ); ?></textarea>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Open Graph</th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_og_tags" value="1" <?php checked( ['enable_og_tags'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Canonical</th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_canonical" value="1" <?php checked( ['enable_canonical'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Robots Meta</th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_smart_robots" value="1" <?php checked( ['enable_smart_robots'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">XML Sitemap</th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_sitemap" value="1" <?php checked( ['enable_sitemap'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo ; ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Редактор записей</th>
                    <td>
                        <label>
                            <input type="checkbox" name="enable_metabox" value="1" <?php checked( ['enable_metabox'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( , 'primary', 'submit', false ); ?>
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

     = array(
        'title_separator'     => sanitize_text_field( (string) ( ['title_separator'] ?? '>' ) ),
        'home_description'    => sanitize_textarea_field( (string) ( ['home_description'] ?? '' ) ),
        'enable_og_tags'      => isset( ['enable_og_tags'] ) ? 1 : 0,
        'enable_canonical'    => isset( ['enable_canonical'] ) ? 1 : 0,
        'enable_smart_robots' => isset( ['enable_smart_robots'] ) ? 1 : 0,
        'enable_sitemap'      => isset( ['enable_sitemap'] ) ? 1 : 0,
        'enable_metabox'      => isset( ['enable_metabox'] ) ? 1 : 0,
    );

    update_option( '_vladimir_seo_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-seo-micro-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. DOCUMENT TITLE & SEPARATOR
// ─────────────────────────────────────────────

add_filter( 'document_title_separator', function(  ) {
     = vladimir_seo_get_settings();
    return ! empty( ['title_separator'] ) ? ['title_separator'] : '>';
} );

add_filter( 'pre_get_document_title', function(  ) {
      = vladimir_seo_get_settings();
           = ' ' . ( ! empty( ['title_separator'] ) ? ['title_separator'] : '>' ) . ' ';
     = get_bloginfo( 'name' );

    if ( is_front_page() || is_home() ) {
         = ! empty( ['home_description'] ) ? ['home_description'] : get_bloginfo( 'description' );
        return  ? (  .  .  ) : ;
    }

    if ( is_singular() ) {
         = get_queried_object();
        if (  ) {
             = get_post_meta( ->ID, '_wsm_title', true )
                         ?: get_post_meta( ->ID, '_seopress_titles_title', true )
                         ?: get_post_meta( ->ID, '_yoast_wpseo_title', true );

            if ( ! empty(  ) ) {
                return esc_html( str_replace(
                    array( '%%sitename%%', '%%sep%%', '%%sitedesc%%', '%%post_title%%' ),
                    array( , , get_bloginfo( 'description' ), get_the_title( ->ID ) ),
                    
                ) );
            }

            return get_the_title( ->ID ) .  . ;
        }
    }

    if ( is_category() || is_tax( 'product_cat' ) ) {
         = get_queried_object();
        if (  ) {
            return ->name .  . ;
        }
    }

    if ( is_tag() || is_tax() ) {
         = get_queried_object();
        if (  ) {
            return ->name .  . ;
        }
    }

    if ( is_404() ) {
        return '404' .  . ;
    }

    if ( is_search() ) {
        return sprintf( 'Поиск: %s', get_search_query() ) .  . ;
    }

    return ;
}, 20 );

// ─────────────────────────────────────────────
// 5. ROBOTS META CONTROL
// ─────────────────────────────────────────────

add_action( 'wp_head', function() {
     = vladimir_seo_get_settings();
    if ( empty( ['enable_smart_robots'] ) ) {
        return;
    }

        if ( is_singular() && ( get_post_meta( get_queried_object_id(), '_seopress_robots_index', true ) === 'yes' || get_post_meta( get_queried_object_id(), '_wsm_noindex', true ) === '1' ) ) {
        echo "<meta name=\"robots\" content=\"noindex,follow\">\n";
        return;
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
// 6. META DESCRIPTION, CANONICAL & OPEN GRAPH
// ─────────────────────────────────────────────

add_action( 'wp_head', function() {
     = vladimir_seo_get_settings();

      = '';
     = '';
       = '';
     = '';
      = 'website';

    if ( is_front_page() || is_home() ) {
          = ! empty( ['home_description'] ) ? ['home_description'] : get_bloginfo( 'description' );
         = get_bloginfo( 'name' );
           = home_url( '/' );
    } elseif ( is_singular() ) {
         = get_queried_object();
        if (  ) {
             = get_post_meta( ->ID, '_wsm_desc', true )
                 ?: get_post_meta( ->ID, '_seopress_titles_desc', true )
                 ?: get_post_meta( ->ID, '_yoast_wpseo_metadesc', true );

            if ( empty(  ) ) {
                 = wp_strip_all_tags( ->post_excerpt ?: ->post_content );
                 = mb_substr( preg_replace( '/\s+/', ' ',  ), 0, 160 );
            }

             = get_the_title( ->ID );
               = get_permalink( ->ID );
              = 'article';

            if ( has_post_thumbnail( ->ID ) ) {
                 = get_the_post_thumbnail_url( ->ID, 'large' );
            }
        }
    } elseif ( is_category() || is_tax( 'product_cat' ) ) {
         = get_queried_object();
        if (  ) {
              = wp_strip_all_tags( term_description( ->term_id ) );
             = ->name;
               = get_term_link(  );
        }
    }

    if ( ! empty(  ) ) {
        echo '<meta name="description" content="' . esc_attr( trim(  ) ) . "\">\n";
    }

    if ( ! empty( ['enable_canonical'] ) && ! empty(  ) ) {
        echo '<link rel="canonical" href="' . esc_url(  ) . "\">\n";
    }

    if ( ! empty( ['enable_og_tags'] ) && ! empty(  ) ) {
        echo '<meta property="og:type" content="' . esc_attr(  ) . "\">\n";
        echo '<meta property="og:site_name" content="' . esc_attr( get_bloginfo( 'name' ) ) . "\">\n";
        echo '<meta property="og:title" content="' . esc_attr(  ?: get_bloginfo( 'name' ) ) . "\">\n";
        echo '<meta property="og:url" content="' . esc_url(  ) . "\">\n";
        if ( ! empty(  ) ) {
            echo '<meta property="og:description" content="' . esc_attr( trim(  ) ) . "\">\n";
        }
        if ( ! empty(  ) ) {
            echo '<meta property="og:image" content="' . esc_url(  ) . "\">\n";
        }
    }
}, 2 );

// ─────────────────────────────────────────────
// 7. NATIVE XML SITEMAP ENGINE
// ─────────────────────────────────────────────

add_action( 'init', function() {
     = vladimir_seo_get_settings();
    if ( empty( ['enable_sitemap'] ) ) {
        return;
    }

     = isset( ['REQUEST_URI'] ) ? (string) ['REQUEST_URI'] : '';
    if ( false === strpos( , 'sitemap.xml' ) ) {
        return;
    }

    header( 'Content-Type: application/xml; charset=utf-8' );
    echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n";

    // Homepage
    echo '  <url><loc>' . esc_url( home_url( '/' ) ) . '</loc><changefreq>daily</changefreq><priority>1.0</priority></url>' . "\n";

    // Posts, Pages, Products
     = array( 'post', 'page' );
    if ( post_type_exists( 'product' ) ) {
        [] = 'product';
    }

     = get_posts( array(
        'post_type'        => ,
        'posts_per_page'   => 2000,
        'post_status'      => 'publish',
        'orderby'          => 'modified',
        'order'            => 'DESC',
        'suppress_filters' => true,
    ) );

    foreach (  as  ) {
         = get_the_modified_date( 'c', ->ID );
         = ( 'page' === ->post_type ) ? '0.8' : ( ( 'product' === ->post_type ) ? '0.9' : '0.7' );
        echo '  <url><loc>' . esc_url( get_permalink( ->ID ) ) . '</loc><lastmod>' . esc_xml(  ) . '</lastmod><changefreq>weekly</changefreq><priority>' .  . '</priority></url>' . "\n";
    }

    // Categories
     = array( 'category' );
    if ( taxonomy_exists( 'product_cat' ) ) {
        [] = 'product_cat';
    }

     = get_terms( array(
        'taxonomy'   => ,
        'hide_empty' => true,
    ) );

    if ( ! is_wp_error(  ) ) {
        foreach (  as  ) {
            echo '  <url><loc>' . esc_url( get_term_link(  ) ) . '</loc><changefreq>weekly</changefreq><priority>0.8</priority></url>' . "\n";
        }
    }

    echo '</urlset>';
    exit;
} );

// ─────────────────────────────────────────────
// 8. POST METABOX
// ─────────────────────────────────────────────

add_action( 'add_meta_boxes', function() {
     = vladimir_seo_get_settings();
    if ( empty( ['enable_metabox'] ) ) {
        return;
    }

     = array( 'post', 'page' );
    if ( post_type_exists( 'product' ) ) {
        [] = 'product';
    }

    add_meta_box( 'wsm_seo', 'SEO (VladiMIR+AI)', function(  ) {
        wp_nonce_field( 'wsm_save', 'wsm_nonce' );
         = esc_attr( get_post_meta( ->ID, '_wsm_title', true ) ?: get_post_meta( ->ID, '_seopress_titles_title', true ) );
         = esc_textarea( get_post_meta( ->ID, '_wsm_desc', true ) ?: get_post_meta( ->ID, '_seopress_titles_desc', true ) );
        echo '<p><label><strong>SEO Title:</strong><br><input type="text" name="wsm_title" value="' .  . '" style="width:100%" maxlength="70" placeholder="' . esc_attr( get_the_title( ->ID ) . ' > ' . get_bloginfo( 'name' ) ) . '"></label></p>
              <p><label><strong>Meta Description:</strong><br><textarea name="wsm_desc" rows="3" style="width:100%" maxlength="160" placeholder="Краткое описание страницы для сниппета в поисковиках...">' .  . '</textarea></label></p>';
    }, , 'normal', 'high' );
} );

add_action( 'save_post', function(  ) {
    if ( ! isset( ['wsm_nonce'] ) || ! wp_verify_nonce( ['wsm_nonce'], 'wsm_save' ) ) {
        return;
    }
    if ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) {
        return;
    }
    update_post_meta( , '_wsm_title', sanitize_text_field( (string) ( ['wsm_title'] ?? '' ) ) );
    update_post_meta( , '_wsm_desc',  sanitize_textarea_field( (string) ( ['wsm_desc'] ?? '' ) ) );
} );

// ─────────────────────────────────────────────
// 9. MULTILINGUAL METADATA (EN / CS / RU)
// ─────────────────────────────────────────────

add_filter( 'all_plugins', function(  ) {
     = plugin_basename( __FILE__ );
    if ( isset( [  ] ) ) {
         = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
           = strtolower( substr( , 0, 2 ) );
        if ( 'ru' ===  ) {
            [  ]['Name']        = 'WP SEO Micro (VladiMIR+AI)';
            [  ]['Description'] = 'Сверхлегкий SEO модуль: title, meta description, Open Graph теги, canonical URL, умное управление robots и нативный XML-sitemap. Включает единую страницу настроек.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'WP SEO Micro (VladiMIR+AI)';
            [  ]['Description'] = 'Ultralehký SEO plugin: titulky, meta popisky, Open Graph tagy, canonical URL, robots a XML sitemap s přehlednou stránkou nastavení na jednom místě.';
        }
    }
    return ;
} );


