<?php
/**
 * Plugin Name: Classic Editor - TinyMCE (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/classic-editor-tinymce
 * Description: All-in-one classic visual editor: disables Gutenberg and block widgets, restores familiar Visual/Text tabs, keeps the 2nd formatting toolbar row open by default with Word-like controls (fonts, sizes, colors, tables, paste-as-text, clear format).
 * Version:     2026.09.13
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  false
 * Text Domain: classic-editor-tinymce
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// ─────────────────────────────────────────────
// 1. DEFAULT SETTINGS & HELPERS
// ─────────────────────────────────────────────

function vladimir_cet_get_settings() {
     = array(
        'disable_gutenberg'   => 1,
        'disable_widgets'     => 1,
        'dequeue_block_css'   => 1,
        'open_second_row'     => 1,
        'fontsize_formats'    => '11px 12px 13px 14px 15px 16px 18px 20px 24px 28px 32px 36px 48px',
        'enable_colors'       => 1,
        'enable_tables'       => 1,
        'enable_paste_text'   => 1,
        'enable_clear_format' => 1,
        'enable_sub_super'    => 1,
        'allow_extended_tags' => 1,
    );
     = get_option( '_vladimir_cet_settings', array() );
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

     = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-cet-settings' ) ) . '"><strong>' . esc_html(  ) . '</strong></a>';
         = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/classic-editor-tinymce" target="_blank">' . esc_html(  ) . '</a>';

    array_unshift( , ,  );
    return ;
} );

// ─────────────────────────────────────────────
// 3. SETTINGS PAGE (Single-Page Dashboard)
// ─────────────────────────────────────────────

add_action( 'admin_menu', function() {
    add_options_page(
        'Classic Editor - TinyMCE (VladiMIR+AI)',
        'Classic Editor - TinyMCE',
        'manage_options',
        'vladimir-cet-settings',
        'vladimir_cet_render_settings_page'
    );
} );

function vladimir_cet_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

       = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
         = strtolower( substr( , 0, 2 ) );
     = vladimir_cet_get_settings();
      = isset( ['settings-updated'] ) && 'true' === ['settings-updated'];

    if ( 'ru' ===  ) {
               = 'Classic Editor - TinyMCE: Настройки редактора';
                = 'Единое управление классическим редактором: отключение Gutenberg, панель форматирования Word и оптимизация стилей.';
               = 'Настройки успешно сохранены!';
               = 'Отключить блочный редактор Gutenberg для записей и страниц';
          = 'Возвращает стандартный классический редактор с вкладками «Визуально» и «Текст (код)».';
                = 'Отключить блочные виджеты в админке';
           = 'Возвращает привычный экран управления виджетами WordPress.';
                 = 'Удалять стили блоков Gutenberg на сайте';
            = 'Отключает загрузку wp-block-library.css во фронтенде (ускоряет открытие страниц).';
                = 'Вторая строка инструментов всегда открыта по умолчанию';
           = 'Вторая строка панели кнопок (шрифты, цвета, таблицы) раскрыта сразу при открытии записи.';
               = 'Размеры шрифта в выпадающем меню';
          = 'Список размеров в px/pt через пробел.';
              = 'Кнопки цвета текста и цвета фона (выделение маркером)';
              = 'Кнопка вставки и управления Таблицами (Table)';
               = 'Кнопка «Вставить как обычный текст» (очистка стилей из Word/браузера)';
               = 'Кнопка «Очистить форматирование»';
                 = 'Кнопки верхнего и нижнего индексов (x² / H₂O)';
                = 'Разрешить расширенные HTML-теги и встроенные стили (style="", div)';
            = 'Сохранить настройки';
    } elseif ( 'cs' ===  ) {
               = 'Classic Editor - TinyMCE: Nastavení editoru';
                = 'Kompletní správa klasického editoru: vypnutí Gutenbergu a rozšířená lišta tlačítek jako ve Wordu.';
               = 'Nastavení bylo úspěšně uloženo!';
               = 'Vypnout Gutenberg pro příspěvky a stránky';
          = 'Aktivuje standardní editor se záložkami „Vizuálně“ a „Text“.';
                = 'Vypnout blokové widgety v administraci';
           = 'Vrátí klasickou obrazovku správy widgetů.';
                 = 'Odstranit blokové CSS styly na webu';
            = 'Zrychlí načítání stránek vyřazením wp-block-library.css.';
                = 'Druhý řádek lišty vždy otevřený';
           = 'Druhý řádek tlačítek je otevřen automaticky.';
               = 'Velikosti písma';
          = 'Seznam velikostí oddělených mezerou.';
              = 'Tlačítka barvy textu a zvýraznění pozadí';
              = 'Tlačítko vložení a správy tabulek';
               = 'Tlačítko „Vložit jako text“';
               = 'Tlačítko „Vymazat formát“';
                 = 'Horní a dolní index';
                = 'Povolit inline styly a rozšířené HTML tagy';
            = 'Uložit nastavení';
    } else {
               = 'Classic Editor - TinyMCE: Editor Settings';
                = 'Unified Classic Editor suite: disables Gutenberg, activates Word-like formatting toolbar row.';
               = 'Settings successfully saved!';
               = 'Disable Gutenberg Block Editor for Posts and Pages';
          = 'Restores traditional editor with Visual and Text tabs.';
                = 'Disable Block Widgets in Admin';
           = 'Restores classic widget management screen.';
                 = 'Dequeue Block Library CSS on Frontend';
            = 'Prevents wp-block-library.css from loading on frontend for speed.';
                = 'Keep 2nd Toolbar Row Open by Default';
           = 'Second toolbar row is expanded by default.';
               = 'Font Size Formats';
          = 'Space-separated list of font sizes available in dropdown.';
              = 'Text Color & Background Highlight Buttons';
              = 'Table Management Button';
               = 'Paste as Plain Text Button';
               = 'Clear Formatting Button';
                 = 'Subscript & Superscript Buttons';
                = 'Allow Extended HTML Tags & Inline Styles';
            = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>✍️ <?php echo esc_html(  ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p class="description" style="font-size:14px;margin-bottom:15px;"><?php echo esc_html(  ); ?></p>

        <?php if (  ) : ?>
            <div class="notice notice-success is-dismissible"><p><strong><?php echo esc_html(  ); ?></strong></p></div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:20px 25px;border:1px solid #c3c4c7;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.05);">
            <?php wp_nonce_field( 'vladimir_save_cet_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_cet_settings">

            <h3 style="margin-top:0;"><?php echo ( 'ru' ===  ) ? '1. Режим редактора и производительность' : '1. Editor Mode & Performance'; ?></h3>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row">Gutenberg</th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_gutenberg" value="1" <?php checked( ['disable_gutenberg'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Виджеты</th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_widgets" value="1" <?php checked( ['disable_widgets'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Стили сайта</th>
                    <td>
                        <label>
                            <input type="checkbox" name="dequeue_block_css" value="1" <?php checked( ['dequeue_block_css'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
            </table>

            <h3 style="margin-top:25px;border-top:1px solid #e2e8f0;padding-top:15px;"><?php echo ( 'ru' ===  ) ? '2. Панель инструментов Word (TinyMCE)' : '2. Word-like Toolbar (TinyMCE)'; ?></h3>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row">Вторая строка</th>
                    <td>
                        <label>
                            <input type="checkbox" name="open_second_row" value="1" <?php checked( ['open_second_row'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="fontsize_formats"><?php echo esc_html(  ); ?></label></th>
                    <td>
                        <input type="text" name="fontsize_formats" id="fontsize_formats" value="<?php echo esc_attr( ['fontsize_formats'] ); ?>" class="large-text">
                        <p class="description"><?php echo esc_html(  ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row">Кнопки форматирования</th>
                    <td>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_colors" value="1" <?php checked( ['enable_colors'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_tables" value="1" <?php checked( ['enable_tables'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_paste_text" value="1" <?php checked( ['enable_paste_text'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <label style="display:block;margin-bottom:8px;">
                            <input type="checkbox" name="enable_clear_format" value="1" <?php checked( ['enable_clear_format'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                        <label style="display:block;">
                            <input type="checkbox" name="enable_sub_super" value="1" <?php checked( ['enable_sub_super'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
                        </label>
                    </td>
                </tr>
                <tr>
                    <th scope="row">HTML-разметка</th>
                    <td>
                        <label>
                            <input type="checkbox" name="allow_extended_tags" value="1" <?php checked( ['allow_extended_tags'], 1 ); ?>>
                            <?php echo esc_html(  ); ?>
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
            <a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/classic-editor-tinymce" target="_blank" style="text-decoration:none;">GitHub Docs ↗</a>
        </p>
    </div>
    <?php
}

add_action( 'admin_post_vladimir_save_cet_settings', function() {
    check_admin_referer( 'vladimir_save_cet_settings', 'vladimir_nonce' );

    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( 'Unauthorized' );
    }

     = array(
        'disable_gutenberg'   => isset( ['disable_gutenberg'] ) ? 1 : 0,
        'disable_widgets'     => isset( ['disable_widgets'] ) ? 1 : 0,
        'dequeue_block_css'   => isset( ['dequeue_block_css'] ) ? 1 : 0,
        'open_second_row'     => isset( ['open_second_row'] ) ? 1 : 0,
        'fontsize_formats'    => sanitize_text_field( (string) ( ['fontsize_formats'] ?? '' ) ),
        'enable_colors'       => isset( ['enable_colors'] ) ? 1 : 0,
        'enable_tables'       => isset( ['enable_tables'] ) ? 1 : 0,
        'enable_paste_text'   => isset( ['enable_paste_text'] ) ? 1 : 0,
        'enable_clear_format' => isset( ['enable_clear_format'] ) ? 1 : 0,
        'enable_sub_super'    => isset( ['enable_sub_super'] ) ? 1 : 0,
        'allow_extended_tags' => isset( ['allow_extended_tags'] ) ? 1 : 0,
    );

    update_option( '_vladimir_cet_settings',  );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-cet-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. EDITOR ENGINE & TOOLBAR HOOKS
// ─────────────────────────────────────────────

 = vladimir_cet_get_settings();

// 1. Disable Gutenberg
if ( ! empty( ['disable_gutenberg'] ) ) {
    add_filter( 'use_block_editor_for_post', '__return_false', 100 );
    add_filter( 'use_block_editor_for_post_type', '__return_false', 100 );
}

// 2. Disable block widgets
if ( ! empty( ['disable_widgets'] ) ) {
    add_filter( 'use_widgets_block_editor', '__return_false' );
}

// 3. Dequeue block library CSS
if ( ! empty( ['dequeue_block_css'] ) ) {
    add_action( 'wp_enqueue_scripts', function() {
        wp_dequeue_style( 'wp-block-library' );
        wp_dequeue_style( 'wp-block-library-theme' );
        wp_dequeue_style( 'global-styles' );
    }, 100 );
}

// 4. Row 1 buttons
add_filter( 'mce_buttons', function(  ) {
    return array(
        'bold', 'italic', 'underline', 'strikethrough', '|',
        'bullist', 'numlist', '|',
        'blockquote', 'hr', '|',
        'alignleft', 'aligncenter', 'alignright', 'alignjustify', '|',
        'link', 'unlink', '|',
        'wp_adv'
    );
} );

// 5. Row 2 buttons
add_filter( 'mce_buttons_2', function( $buttons ) {
    $settings = vladimir_cet_get_settings();
    $row2     = array( 'formatselect', 'fontsizeselect' );

    if ( ! empty( $settings['enable_colors'] ) ) {
        $row2[] = 'forecolor';
        $row2[] = 'backcolor';
    }
    $row2[] = '|';

    if ( ! empty( $settings['enable_tables'] ) ) {
        $row2[] = 'table';
    }
    if ( ! empty( $settings['enable_paste_text'] ) ) {
        $row2[] = 'pastetext';
    }
    if ( ! empty( $settings['enable_clear_format'] ) ) {
        $row2[] = 'removeformat';
    }
    $row2[] = '|';

    $row2[] = 'charmap';

    if ( ! empty( $settings['enable_sub_super'] ) ) {
        $row2[] = 'superscript';
        $row2[] = 'subscript';
    }
    $row2[] = '|';
    $row2[] = 'outdent';
    $row2[] = 'indent';
    $row2[] = '|';
    $row2[] = 'undo';
    $row2[] = 'redo';

    // Remove wp_help (question mark shortcut button) and deduplicate buttons while preserving separators
    $cleaned = array();
    $seen    = array();
    foreach ( $row2 as $btn ) {
        if ( 'wp_help' === $btn ) {
            continue;
        }
        if ( '|' === $btn ) {
            if ( ! empty( $cleaned ) && end( $cleaned ) !== '|' ) {
                $cleaned[] = '|';
            }
            continue;
        }
        if ( ! isset( $seen[ $btn ] ) ) {
            $seen[ $btn ] = true;
            $cleaned[]    = $btn;
        }
    }
    if ( ! empty( $cleaned ) && end( $cleaned ) === '|' ) {
        array_pop( $cleaned );
    }

    return $cleaned;
}, 999 );

// 6. TinyMCE before init
add_filter( 'tiny_mce_before_init', function(  ) {
     = vladimir_cet_get_settings();

    if ( ! empty( ['open_second_row'] ) ) {
        ['wordpress_adv_hidden'] = false;
    }

    if ( ! empty( ['fontsize_formats'] ) ) {
        ['fontsize_formats'] = ['fontsize_formats'];
    }

    if ( ! empty( ['allow_extended_tags'] ) ) {
        ['extended_valid_elements'] = '*[*]';
        ['valid_children']          = '+body[style],+div[style]';
    }

    return ;
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
            [  ]['Name']        = 'Classic Editor - TinyMCE (VladiMIR+AI)';
            [  ]['Description'] = 'Единый классический редактор: отключает Gutenberg и блочные виджеты, включает классический редактор и всегда открытую 2-ю строчку тулбара Word-форматирования (шрифты, цвета, таблицы, очистка стилей). Включает страницу настроек.';
        } elseif ( 'cs' ===  ) {
            [  ]['Name']        = 'Classic Editor - TinyMCE (VladiMIR+AI)';
            [  ]['Description'] = 'Kompletní klasický editor: vypíná Gutenberg i blokové widgety, aktivuje lištu formátování jako ve Wordu a přehlednou stránku nastavení na jednom místě.';
        }
    }
    return ;
} );

