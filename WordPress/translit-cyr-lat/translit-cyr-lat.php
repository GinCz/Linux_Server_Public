<?php
/**
 * Plugin Name: Translit Cyr & Czech to Lat SEO (VladiMIR+AI)
 * Plugin URI:  https://github.com/GinCz
 * Description: High-performance SEO transliteration plugin converting Cyrillic (Russian, Ukrainian) and Czech/Slovak diacritic characters into clean Latin URL slugs. Zero database queries.
 * Version:     2026.09.04
 * Author:      VladiMIR (GinCz)
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

add_filter( 'sanitize_title', function( $title, $raw_title = '', $context = 'query' ) {
    if ( 'save' !== $context ) {
        return $title;
    }

    $source = $raw_title ? $raw_title : $title;

    $matrix = array(
        // Russian / Ukrainian
        'а' => 'a',   'б' => 'b',   'в' => 'v',   'г' => 'g',   'д' => 'd',
        'е' => 'e',   'ё' => 'yo',  'ж' => 'zh',  'з' => 'z',   'и' => 'i',
        'й' => 'y',   'к' => 'k',   'л' => 'l',   'м' => 'm',   'н' => 'n',
        'о' => 'o',   'п' => 'p',   'р' => 'r',   'с' => 's',   'т' => 't',
        'у' => 'u',   'ф' => 'f',   'х' => 'kh',  'ц' => 'ts',  'ч' => 'ch',
        'ш' => 'sh',  'щ' => 'shch','ъ' => '',   'ы' => 'y',   'ь' => '',
        'э' => 'e',   'ю' => 'yu',  'я' => 'ya',  'є' => 'ye',  'і' => 'i',
        'ї' => 'yi',  'ґ' => 'g',

        'А' => 'A',   'Б' => 'B',   'В' => 'V',   'Г' => 'G',   'Д' => 'D',
        'Е' => 'E',   'Ё' => 'Yo',  'Ж' => 'Zh',  'З' => 'Z',   'И' => 'I',
        'Й' => 'Y',   'К' => 'K',   'Л' => 'L',   'М' => 'M',   'Н' => 'N',
        'О' => 'O',   'П' => 'P',   'Р' => 'R',   'С' => 'S',   'Т' => 'T',
        'У' => 'U',   'Ф' => 'F',   'Х' => 'Kh',  'Ц' => 'Ts',  'Ч' => 'Ch',
        'Ш' => 'Sh',  'Щ' => 'Shch','Ъ' => '',   'Ы' => 'Y',   'Ь' => '',
        'Э' => 'E',   'Ю' => 'Yu',  'Я' => 'Ya',  'Є' => 'Ye',  'І' => 'I',
        'Ї' => 'Yi',  'Ґ' => 'G',

        // Czech / Slovak diacritics
        'á' => 'a',   'č' => 'c',   'ď' => 'd',   'é' => 'e',   'ě' => 'e',
        'í' => 'i',   'ň' => 'n',   'ó' => 'o',   'ř' => 'r',   'š' => 's',
        'ť' => 't',   'ú' => 'u',   'ů' => 'u',   'ý' => 'y',   'ž' => 'z',
        'ä' => 'a',   'ô' => 'o',   'ĺ' => 'l',   'ŕ' => 'r',

        'Á' => 'A',   'Č' => 'C',   'Ď' => 'D',   'É' => 'E',   'Ě' => 'E',
        'Í' => 'I',   'Ň' => 'N',   'Ó' => 'O',   'Ř' => 'R',   'Š' => 'S',
        'Ť' => 'T',   'Ú' => 'U',   'Ů' => 'U',   'Ý' => 'Y',   'Ž' => 'Z',
        'Ä' => 'A',   'Ô' => 'O',   'Ĺ' => 'L',   'Ŕ' => 'R'
    );

    $trans = strtr( $source, $matrix );
    return remove_accents( $trans );
}, 9, 3 );
