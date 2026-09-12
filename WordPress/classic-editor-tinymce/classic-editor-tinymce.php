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
    $defaults = array(
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
    $saved = get_option( '_vladimir_cet_settings', array() );
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

    $settings_link = '<a href="' . esc_url( admin_url( 'options-general.php?page=vladimir-cet-settings' ) ) . '"><strong>' . esc_html( $settings_label ) . '</strong></a>';
    $docs_link     = '<a href="https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress/classic-editor-tinymce" target="_blank">' . esc_html( $docs_label ) . '</a>';

    array_unshift( $links, $settings_link, $docs_link );
    return $links;
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

    $locale   = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
    $lang     = strtolower( substr( $locale, 0, 2 ) );
    $settings = vladimir_cet_get_settings();
    $updated  = isset( $_GET['settings-updated'] ) && 'true' === $_GET['settings-updated'];

    if ( 'ru' === $lang ) {
        $txt_title        = 'Classic Editor - TinyMCE: Настройки редактора';
        $txt_subtitle     = 'Единое управление классическим редактором: отключение Gutenberg, панель форматирования Word и оптимизация стилей.';
        $txt_saved        = 'Настройки успешно сохранены!';
        $txt_gut_label    = 'Отключить блочный редактор Gutenberg для записей и страниц';
        $txt_gut_desc     = 'Возвращает стандартный классический редактор с вкладками «Визуально» и «Текст (код)».';
        $txt_wid_label    = 'Отключить блочные виджеты в админке';
        $txt_wid_desc     = 'Возвращает привычный экран управления виджетами WordPress.';
        $txt_css_label    = 'Удалять стили блоков Gutenberg на сайте';
        $txt_css_desc     = 'Отключает загрузку wp-block-library.css во фронтенде (ускоряет открытие страниц).';
        $txt_row2_label   = 'Вторая строка инструментов всегда открыта по умолчанию';
        $txt_row2_desc    = 'Вторая строка панели кнопок (шрифты, цвета, таблицы) раскрыта сразу при открытии записи.';
        $txt_size_label   = 'Размеры шрифта в выпадающем меню';
        $txt_size_desc    = 'Список размеров в px/pt через пробел.';
        $txt_col_label    = 'Кнопки цвета текста и цвета фона (выделение маркером)';
        $txt_tbl_label    = 'Кнопка вставки и управления Таблицами (Table)';
        $txt_pst_label    = 'Кнопка «Вставить как обычный текст» (очистка стилей из Word/браузера)';
        $txt_clr_label    = 'Кнопка «Очистить форматирование»';
        $txt_sub_label    = 'Кнопки верхнего и нижнего индексов (x² / H₂O)';
        $txt_tag_label    = 'Разрешить расширенные HTML-теги и встроенные стили (style="", div)';
        $txt_save_btn     = 'Сохранить настройки';
    } elseif ( 'cs' === $lang ) {
        $txt_title        = 'Classic Editor - TinyMCE: Nastavení editoru';
        $txt_subtitle     = 'Kompletní správa klasického editoru: vypnutí Gutenbergu a rozšířená lišta tlačítek jako ve Wordu.';
        $txt_saved        = 'Nastavení bylo úspěšně uloženo!';
        $txt_gut_label    = 'Vypnout Gutenberg pro příspěvky a stránky';
        $txt_gut_desc     = 'Aktivuje standardní editor se záložkami „Vizuálně“ a „Text“.';
        $txt_wid_label    = 'Vypnout blokové widgety v administraci';
        $txt_wid_desc     = 'Vrátí klasickou obrazovku správy widgetů.';
        $txt_css_label    = 'Odstranit blokové CSS styly na webu';
        $txt_css_desc     = 'Zrychlí načítání stránek vyřazením wp-block-library.css.';
        $txt_row2_label   = 'Druhý řádek lišty vždy otevřený';
        $txt_row2_desc    = 'Druhý řádek tlačítek je otevřen automaticky.';
        $txt_size_label   = 'Velikosti písma';
        $txt_size_desc    = 'Seznam velikostí oddělených mezerou.';
        $txt_col_label    = 'Tlačítka barvy textu a zvýraznění pozadí';
        $txt_tbl_label    = 'Tlačítko vložení a správy tabulek';
        $txt_pst_label    = 'Tlačítko „Vložit jako text“';
        $txt_clr_label    = 'Tlačítko „Vymazat formát“';
        $txt_sub_label    = 'Horní a dolní index';
        $txt_tag_label    = 'Povolit inline styly a rozšířené HTML tagy';
        $txt_save_btn     = 'Uložit nastavení';
    } else {
        $txt_title        = 'Classic Editor - TinyMCE: Editor Settings';
        $txt_subtitle     = 'Unified Classic Editor suite: disables Gutenberg, activates Word-like formatting toolbar row.';
        $txt_saved        = 'Settings successfully saved!';
        $txt_gut_label    = 'Disable Gutenberg Block Editor for Posts and Pages';
        $txt_gut_desc     = 'Restores traditional editor with Visual and Text tabs.';
        $txt_wid_label    = 'Disable Block Widgets in Admin';
        $txt_wid_desc     = 'Restores classic widget management screen.';
        $txt_css_label    = 'Dequeue Block Library CSS on Frontend';
        $txt_css_desc     = 'Prevents wp-block-library.css from loading on frontend for speed.';
        $txt_row2_label   = 'Keep 2nd Toolbar Row Open by Default';
        $txt_row2_desc    = 'Second toolbar row is expanded by default.';
        $txt_size_label   = 'Font Size Formats';
        $txt_size_desc    = 'Space-separated list of font sizes available in dropdown.';
        $txt_col_label    = 'Text Color & Background Highlight Buttons';
        $txt_tbl_label    = 'Table Management Button';
        $txt_pst_label    = 'Paste as Plain Text Button';
        $txt_clr_label    = 'Clear Formatting Button';
        $txt_sub_label    = 'Subscript & Superscript Buttons';
        $txt_tag_label    = 'Allow Extended HTML Tags & Inline Styles';
        $txt_save_btn     = 'Save Settings';
    }
    ?>
    <div class="wrap" style="max-width:900px;">
        <h1 style="display:flex;align-items:center;gap:10px;">
            <span>✍️ <?php echo esc_html( $txt_title ); ?></span>
            <span style="font-size:12px;background:#2271b1;color:#fff;padding:3px 8px;border-radius:12px;font-weight:600;">(VladiMIR+AI)</span>
        </h1>
        <p style="color:#64748b;font-size:14px;margin-bottom:20px;"><?php echo esc_html( $txt_subtitle ); ?></p>

        <?php if ( $updated ) : ?>
            <div class="notice notice-success is-dismissible" style="margin-left:0;">
                <p><strong><?php echo esc_html( $txt_saved ); ?></strong></p>
            </div>
        <?php endif; ?>

        <form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="background:#fff;padding:24px;border:1px solid #ccd0d4;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.04);">
            <?php wp_nonce_field( 'vladimir_save_cet_settings', 'vladimir_nonce' ); ?>
            <input type="hidden" name="action" value="vladimir_save_cet_settings">

            <h2 style="font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-top:0;">1. Режим классического редактора</h2>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Gutenberg</strong></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_gutenberg" value="1" <?php checked( $settings['disable_gutenberg'], 1 ); ?>>
                            <?php echo esc_html( $txt_gut_label ); ?>
                        </label>
                        <p class="description"><?php echo esc_html( $txt_gut_desc ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><strong>Виджеты</strong></th>
                    <td>
                        <label>
                            <input type="checkbox" name="disable_widgets" value="1" <?php checked( $settings['disable_widgets'], 1 ); ?>>
                            <?php echo esc_html( $txt_wid_label ); ?>
                        </label>
                        <p class="description"><?php echo esc_html( $txt_wid_desc ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><strong>Оптимизация CSS</strong></th>
                    <td>
                        <label>
                            <input type="checkbox" name="dequeue_block_css" value="1" <?php checked( $settings['dequeue_block_css'], 1 ); ?>>
                            <?php echo esc_html( $txt_css_label ); ?>
                        </label>
                        <p class="description"><?php echo esc_html( $txt_css_desc ); ?></p>
                    </td>
                </tr>
            </table>

            <h2 style="font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-top:24px;">2. Панель инструментов TinyMCE (Word-форматирование)</h2>
            <table class="form-table" role="presentation">
                <tr>
                    <th scope="row"><strong>Вторая строка</strong></th>
                    <td>
                        <label>
                            <input type="checkbox" name="open_second_row" value="1" <?php checked( $settings['open_second_row'], 1 ); ?>>
                            <?php echo esc_html( $txt_row2_label ); ?>
                        </label>
                        <p class="description"><?php echo esc_html( $txt_row2_desc ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><label for="fontsize_formats"><strong><?php echo esc_html( $txt_size_label ); ?></strong></label></th>
                    <td>
                        <input type="text" name="fontsize_formats" id="fontsize_formats" value="<?php echo esc_attr( $settings['fontsize_formats'] ); ?>" class="regular-text" style="width:100%;">
                        <p class="description"><?php echo esc_html( $txt_size_desc ); ?></p>
                    </td>
                </tr>
                <tr>
                    <th scope="row"><strong>Кнопки форматирования</strong></th>
                    <td>
                        <fieldset style="display:flex;flex-direction:column;gap:8px;">
                            <label>
                                <input type="checkbox" name="enable_colors" value="1" <?php checked( $settings['enable_colors'], 1 ); ?>>
                                <?php echo esc_html( $txt_col_label ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_tables" value="1" <?php checked( $settings['enable_tables'], 1 ); ?>>
                                <?php echo esc_html( $txt_tbl_label ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_paste_text" value="1" <?php checked( $settings['enable_paste_text'], 1 ); ?>>
                                <?php echo esc_html( $txt_pst_label ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_clear_format" value="1" <?php checked( $settings['enable_clear_format'], 1 ); ?>>
                                <?php echo esc_html( $txt_clr_label ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="enable_sub_super" value="1" <?php checked( $settings['enable_sub_super'], 1 ); ?>>
                                <?php echo esc_html( $txt_sub_label ); ?>
                            </label>
                            <label>
                                <input type="checkbox" name="allow_extended_tags" value="1" <?php checked( $settings['allow_extended_tags'], 1 ); ?>>
                                <?php echo esc_html( $txt_tag_label ); ?>
                            </label>
                        </fieldset>
                    </td>
                </tr>
            </table>

            <div style="margin-top:20px;">
                <?php submit_button( $txt_save_btn, 'primary', 'submit', false ); ?>
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

    $updated = array(
        'disable_gutenberg'   => isset( $_POST['disable_gutenberg'] ) ? 1 : 0,
        'disable_widgets'     => isset( $_POST['disable_widgets'] ) ? 1 : 0,
        'dequeue_block_css'   => isset( $_POST['dequeue_block_css'] ) ? 1 : 0,
        'open_second_row'     => isset( $_POST['open_second_row'] ) ? 1 : 0,
        'fontsize_formats'    => sanitize_text_field( (string) ( $_POST['fontsize_formats'] ?? '' ) ),
        'enable_colors'       => isset( $_POST['enable_colors'] ) ? 1 : 0,
        'enable_tables'       => isset( $_POST['enable_tables'] ) ? 1 : 0,
        'enable_paste_text'   => isset( $_POST['enable_paste_text'] ) ? 1 : 0,
        'enable_clear_format' => isset( $_POST['enable_clear_format'] ) ? 1 : 0,
        'enable_sub_super'    => isset( $_POST['enable_sub_super'] ) ? 1 : 0,
        'allow_extended_tags' => isset( $_POST['allow_extended_tags'] ) ? 1 : 0,
    );

    update_option( '_vladimir_cet_settings', $updated );

    wp_safe_redirect( add_query_arg( array( 'page' => 'vladimir-cet-settings', 'settings-updated' => 'true' ), admin_url( 'options-general.php' ) ) );
    exit;
} );

// ─────────────────────────────────────────────
// 4. EDITOR ENGINE & TOOLBAR HOOKS
// ─────────────────────────────────────────────

$cet_cfg = vladimir_cet_get_settings();

// 1. Disable Gutenberg
if ( ! empty( $cet_cfg['disable_gutenberg'] ) ) {
    add_filter( 'use_block_editor_for_post', '__return_false', 100 );
    add_filter( 'use_block_editor_for_post_type', '__return_false', 100 );
}

// 2. Disable block widgets
if ( ! empty( $cet_cfg['disable_widgets'] ) ) {
    add_filter( 'use_widgets_block_editor', '__return_false' );
}

// 3. Dequeue block library CSS
if ( ! empty( $cet_cfg['dequeue_block_css'] ) ) {
    add_action( 'wp_enqueue_scripts', function() {
        wp_dequeue_style( 'wp-block-library' );
        wp_dequeue_style( 'wp-block-library-theme' );
        wp_dequeue_style( 'global-styles' );
    }, 100 );
}

// 4. Row 1 buttons
add_filter( 'mce_buttons', function( $buttons ) {
    return array(
        'bold', 'italic', 'underline', 'strikethrough', '|',
        'bullist', 'numlist', '|',
        'blockquote', 'hr', '|',
        'alignleft', 'aligncenter', 'alignright', 'alignjustify', '|',
        'link', 'unlink', '|',
        'wp_adv'
    );
}, 999 );

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

    // Remove wp_help (keyboard shortcuts / ? button) and deduplicate buttons while preserving separators
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
add_filter( 'tiny_mce_before_init', function( $init ) {
    $settings = vladimir_cet_get_settings();

    if ( ! empty( $settings['open_second_row'] ) ) {
        $init['wordpress_adv_hidden'] = false;
    }

    if ( ! empty( $settings['fontsize_formats'] ) ) {
        $init['fontsize_formats'] = $settings['fontsize_formats'];
    }

    if ( ! empty( $settings['allow_extended_tags'] ) ) {
        $init['extended_valid_elements'] = '*[*]';
        $init['valid_children']          = '+body[style],+div[style]';
    }

    return $init;
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
            $plugins[ $plugin_key ]['Name']        = 'Classic Editor - TinyMCE (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Единый классический редактор: отключает Gutenberg и блочные виджеты, включает классический редактор и всегда открытую 2-ю строчку тулбара Word-форматирования (шрифты, цвета, таблицы, очистка стилей). Включает страницу настроек.';
        } elseif ( 'cs' === $lang ) {
            $plugins[ $plugin_key ]['Name']        = 'Classic Editor - TinyMCE (VladiMIR+AI)';
            $plugins[ $plugin_key ]['Description'] = 'Kompletní klasický editor: vypíná Gutenberg i blokové widgety, aktivuje lištu formátování jako ve Wordu a přehlednou stránku nastavení na jednom místě.';
        }
    }
    return $plugins;
} );
