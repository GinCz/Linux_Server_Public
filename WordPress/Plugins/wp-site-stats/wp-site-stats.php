<?php
/**
 * Plugin Name: Site Traffic & Visitor Analytics (VladiMIR+AI✅)
 * Plugin URI:  https://github.com/GinCz/plugins/tree/main/wp-site-stats
 * Description: Ultra-lightweight, privacy-friendly, self-hosted web analytics dashboard. Zero cookies, zero third-party tracking, zero bloat. Dedicated admin-only statistics.
 * Version:     2026-11__1.01
 * Author:      VladiMIR (GinCz) + AI
 * Author URI:  https://github.com/GinCz
 * License:     GPL-2.0-or-later
 * Update URI:  https://vladimir-ai.updates/wp-site-stats
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Text Domain: wp-site-stats
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

if ( file_exists( __DIR__ . '/vladimir-ai-updater.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-updater.php';
}

if ( file_exists( __DIR__ . '/vladimir-ai-i18n.php' ) ) {
    require_once __DIR__ . '/vladimir-ai-i18n.php';
}

// ─────────────────────────────────────────────
// 0. NATIVE MULTILINGUAL ENGINE (9 LANGUAGES)
// ─────────────────────────────────────────────

function vladimir_ss_t( $key, $lang = null ) {
    static $dict = null;
    if ( null === $dict ) {
        $dict = array(
            'menu_title' => array(
                'en' => 'Site Stats',
                'ru' => 'Статистика',
                'uk' => 'Статистика',
                'cs' => 'Statistika',
                'de' => 'Statistik',
                'fr' => 'Statistiques',
                'es' => 'Estadísticas',
                'it' => 'Statistiche',
                'pl' => 'Statystyki',
            ),
            'page_title' => array(
                'en' => 'Site Traffic & Visitor Analytics (VladiMIR+AI)',
                'ru' => 'Статистика посещаемости (VladiMIR+AI)',
                'uk' => 'Статистика відвідуваності (VladiMIR+AI)',
                'cs' => 'Statistika návštěvnosti (VladiMIR+AI)',
                'de' => 'Besucher- & Traffic-Statistiken (VladiMIR+AI)',
                'fr' => 'Statistiques de trafic et visites (VladiMIR+AI)',
                'es' => 'Estadísticas de tráfico y visitas (VladiMIR+AI)',
                'it' => 'Statistiche di traffico e visite (VladiMIR+AI)',
                'pl' => 'Statystyki ruchu i odwiedzin (VladiMIR+AI)',
            ),
            'desc' => array(
                'en' => 'Ultra-lightweight, privacy-friendly analytics without cookies or third-party tracking. Admin-only access.',
                'ru' => 'Легковесная, конфиденциальная аналитика без cookies и сторонних серверов. Доступно только администраторам.',
                'uk' => 'Легковажна, конфіденційна аналітика без cookies та сторонніх серверів. Доступно тільки адміністраторам.',
                'cs' => 'Ultralehká, diskrétní analytika bez cookies a externích služeb. Přístup pouze pro administrátory.',
                'de' => 'Ultraschlanke, datenschutzfreundliche Analyse ohne Cookies oder Drittanbieter. Nur für Administratoren.',
                'fr' => 'Analytique ultra-légère et respectueuse de la vie privée sans cookies ni traceurs tiers. Réservé aux administrateurs.',
                'es' => 'Analítica ultraligera y respetuosa con la privacidad sin cookies ni seguimiento externo. Solo para administradores.',
                'it' => 'Analisi ultraleggera e rispettosa della privacy senza cookie né tracciamento esterno. Solo per amministratori.',
                'pl' => 'Ultralekka, bezpieczna analityka bez plików cookie i zewnętrznych trackerów. Dostęp wyłącznie dla administratorów.',
            ),
            'today' => array(
                'en' => 'Today',
                'ru' => 'Сегодня',
                'uk' => 'Сьогодні',
                'cs' => 'Dnes',
                'de' => 'Heute',
                'fr' => "Aujourd'hui",
                'es' => 'Hoy',
                'it' => 'Oggi',
                'pl' => 'Dzisiaj',
            ),
            'yesterday' => array(
                'en' => 'Yesterday',
                'ru' => 'Вчера',
                'uk' => 'Вчора',
                'cs' => 'Včera',
                'de' => 'Gestern',
                'fr' => 'Hier',
                'es' => 'Ayer',
                'it' => 'Ieri',
                'pl' => 'Wczoraj',
            ),
            '7d' => array(
                'en' => '7 days',
                'ru' => '7 дней',
                'uk' => '7 днів',
                'cs' => '7 dní',
                'de' => '7 Tage',
                'fr' => '7 jours',
                'es' => '7 días',
                'it' => '7 giorni',
                'pl' => '7 dni',
            ),
            '30d' => array(
                'en' => '30 days',
                'ru' => '30 дней',
                'uk' => '30 днів',
                'cs' => '30 dní',
                'de' => '30 Tage',
                'fr' => '30 jours',
                'es' => '30 días',
                'it' => '30 giorni',
                'pl' => '30 dni',
            ),
            'last_7_days' => array(
                'en' => 'Last 7 days',
                'ru' => 'Последние 7 дней',
                'uk' => 'Останні 7 днів',
                'cs' => 'Posledních 7 dní',
                'de' => 'Letzte 7 Tage',
                'fr' => '7 derniers jours',
                'es' => 'Últimos 7 días',
                'it' => 'Ultimi 7 giorni',
                'pl' => 'Ostatnie 7 dni',
            ),
            'last_30_days' => array(
                'en' => 'Last 30 days',
                'ru' => 'Последние 30 дней',
                'uk' => 'Останні 30 днів',
                'cs' => 'Posledních 30 dní',
                'de' => 'Letzte 30 Tage',
                'fr' => '30 derniers jours',
                'es' => 'Últimos 30 días',
                'it' => 'Ultimi 30 giorni',
                'pl' => 'Ostatnie 30 dni',
            ),
            'unique_visitors' => array(
                'en' => '👥 Unique Visitors',
                'ru' => '👥 Уникальные посетители',
                'uk' => '👥 Унікальні відвідувачі',
                'cs' => '👥 Unikátní návštěvníci',
                'de' => '👥 Eindeutige Besucher',
                'fr' => '👥 Visiteurs uniques',
                'es' => '👥 Visitantes únicos',
                'it' => '👥 Visitatori unici',
                'pl' => '👥 Unikalni użytkownicy',
            ),
            'page_views' => array(
                'en' => '👁️ Pageviews',
                'ru' => '👁️ Просмотры страниц',
                'uk' => '👁️ Перегляди сторінок',
                'cs' => '👁️ Zobrazení stránek',
                'de' => '👁️ Seitenaufrufe',
                'fr' => '👁️ Pages vues',
                'es' => '👁️ Páginas vistas',
                'it' => '👁️ Pagine viste',
                'pl' => '👁️ Odsłony stron',
            ),
            'depth' => array(
                'en' => '📄 Depth (pages/visit)',
                'ru' => '📄 Глубина (стр./посетитель)',
                'uk' => '📄 Глибина (стор./відвідувач)',
                'cs' => '📄 Hloubka (str./návštěva)',
                'de' => '📄 Tiefe (Seiten/Besuch)',
                'fr' => '📄 Profondeur (pages/visite)',
                'es' => '📄 Profundidad (págs./visita)',
                'it' => '📄 Profondità (pag./visita)',
                'pl' => '📄 Głębokość (str./odwiedziny)',
            ),
            'top_source' => array(
                'en' => '🚀 Top Source',
                'ru' => '🚀 Главный источник',
                'uk' => '🚀 Головне джерело',
                'cs' => '🚀 Hlavní zdroj',
                'de' => '🚀 Top-Quelle',
                'fr' => '🚀 Source principale',
                'es' => '🚀 Fuente principal',
                'it' => '🚀 Fonte principale',
                'pl' => '🚀 Główne źródło',
            ),
            'direct' => array(
                'en' => 'Direct Traffic',
                'ru' => 'Прямые заходы',
                'uk' => 'Прямі заходи',
                'cs' => 'Přímé návštěvy',
                'de' => 'Direkter Traffic',
                'fr' => 'Trafic direct',
                'es' => 'Tráfico directo',
                'it' => 'Traffico diretto',
                'pl' => 'Ruch bezpośredni',
            ),
            'transitions' => array(
                'en' => 'visits',
                'ru' => 'переходов',
                'uk' => 'переходів',
                'cs' => 'přechodů',
                'de' => 'Besuche',
                'fr' => 'visites',
                'es' => 'visitas',
                'it' => 'visite',
                'pl' => 'przejść',
            ),
            'avg_engagement' => array(
                'en' => 'Average engagement',
                'ru' => 'Среднее вовлечение',
                'uk' => 'Середнє залучення',
                'cs' => 'Průměrné zapojení',
                'de' => 'Durchschnittliches Engagement',
                'fr' => 'Engagement moyen',
                'es' => 'Compromiso medio',
                'it' => 'Coinvolgimento medio',
                'pl' => 'Średnie zaangażowanie',
            ),
            'traffic_trend' => array(
                'en' => '📈 Traffic Trend',
                'ru' => '📈 Динамика трафика',
                'uk' => '📈 Динаміка трафіку',
                'cs' => '📈 Vývoj návštěvnosti',
                'de' => '📈 Traffic-Verlauf',
                'fr' => '📈 Évolution du trafic',
                'es' => '📈 Evolución del tráfico',
                'it' => '📈 Andamento del traffico',
                'pl' => '📈 Dynamika ruchu',
            ),
            'views_legend' => array(
                'en' => 'Pageviews',
                'ru' => 'Просмотры',
                'uk' => 'Перегляди',
                'cs' => 'Zobrazení',
                'de' => 'Seitenaufrufe',
                'fr' => 'Pages vues',
                'es' => 'Vistas',
                'it' => 'Pagine viste',
                'pl' => 'Odsłony',
            ),
            'visitors_legend' => array(
                'en' => 'Unique Visitors',
                'ru' => 'Посетители',
                'uk' => 'Відвідувачі',
                'cs' => 'Návštěvníci',
                'de' => 'Besucher',
                'fr' => 'Visiteurs',
                'es' => 'Visitantes',
                'it' => 'Visitatori',
                'pl' => 'Użytkownicy',
            ),
            'top_pages' => array(
                'en' => '📄 Top Pages',
                'ru' => '📄 Популярные страницы',
                'uk' => '📄 Популярні сторінки',
                'cs' => '📄 Oblíbené stránky',
                'de' => '📄 Beliebteste Seiten',
                'fr' => '📄 Pages populaires',
                'es' => '📄 Páginas populares',
                'it' => '📄 Pagine più visitate',
                'pl' => '📄 Najpopularniejsze strony',
            ),
            'page' => array(
                'en' => 'Page',
                'ru' => 'Страница',
                'uk' => 'Сторінка',
                'cs' => 'Stránka',
                'de' => 'Seite',
                'fr' => 'Page',
                'es' => 'Página',
                'it' => 'Pagina',
                'pl' => 'Strona',
            ),
            'hits' => array(
                'en' => 'Hits',
                'ru' => 'Хиты',
                'uk' => 'Хіти',
                'cs' => 'Zobrazení',
                'de' => 'Aufrufe',
                'fr' => 'Vues',
                'es' => 'Vistas',
                'it' => 'Viste',
                'pl' => 'Wyświetlenia',
            ),
            'uniques' => array(
                'en' => 'Uniques',
                'ru' => 'Уники',
                'uk' => 'Унікальні',
                'cs' => 'Unikáty',
                'de' => 'Eindeutig',
                'fr' => 'Uniques',
                'es' => 'Únicos',
                'it' => 'Unici',
                'pl' => 'Unikalne',
            ),
            'referrers' => array(
                'en' => '🔗 Traffic Sources (Referrers)',
                'ru' => '🔗 Источники трафика (Referrers)',
                'uk' => '🔗 Джерела трафіку (Referrers)',
                'cs' => '🔗 Zdroje návštěvnosti (Referrers)',
                'de' => '🔗 Traffic-Quellen (Referrer)',
                'fr' => '🔗 Sources de trafic (Référents)',
                'es' => '🔗 Fuentes de tráfico (Referentes)',
                'it' => '🔗 Fonti di traffico (Referrer)',
                'pl' => '🔗 Źródła ruchu (Referrers)',
            ),
            'source' => array(
                'en' => 'Source',
                'ru' => 'Источник',
                'uk' => 'Джерело',
                'cs' => 'Zdroj',
                'de' => 'Quelle',
                'fr' => 'Source',
                'es' => 'Fuente',
                'it' => 'Fonte',
                'pl' => 'Źródło',
            ),
            'geography' => array(
                'en' => '🌍 Visitor Geography',
                'ru' => '🌍 География посетителей',
                'uk' => '🌍 Географія відвідувачів',
                'cs' => '🌍 Geografie návštěvníků',
                'de' => '🌍 Besucher-Geografie',
                'fr' => '🌍 Géographie des visiteurs',
                'es' => '🌍 Geografía de visitantes',
                'it' => '🌍 Geografia dei visitatori',
                'pl' => '🌍 Geografia odwiedzających',
            ),
            'country' => array(
                'en' => 'Country',
                'ru' => 'Страна',
                'uk' => 'Країна',
                'cs' => 'Země',
                'de' => 'Land',
                'fr' => 'Pays',
                'es' => 'País',
                'it' => 'Paese',
                'pl' => 'Kraj',
            ),
            'views' => array(
                'en' => 'Views',
                'ru' => 'Просмотры',
                'uk' => 'Перегляди',
                'cs' => 'Zobrazení',
                'de' => 'Aufrufe',
                'fr' => 'Vues',
                'es' => 'Vistas',
                'it' => 'Viste',
                'pl' => 'Odsłony',
            ),
            'devices_browsers' => array(
                'en' => '📱 Devices & Browsers',
                'ru' => '📱 Устройства и браузеры',
                'uk' => '📱 Пристрої та браузери',
                'cs' => '📱 Zařízení a prohlížeče',
                'de' => '📱 Geräte & Browser',
                'fr' => '📱 Appareils & Navigateurs',
                'es' => '📱 Dispositivos y navegadores',
                'it' => '📱 Dispositivi e browser',
                'pl' => '📱 Urządzenia i przeglądarki',
            ),
            'devices' => array(
                'en' => 'Devices:',
                'ru' => 'Устройства:',
                'uk' => 'Пристрої:',
                'cs' => 'Zařízení:',
                'de' => 'Geräte:',
                'fr' => 'Appareils :',
                'es' => 'Dispositivos:',
                'it' => 'Dispositivi:',
                'pl' => 'Urządzenia:',
            ),
            'browsers' => array(
                'en' => 'Browsers:',
                'ru' => 'Браузеры:',
                'uk' => 'Браузери:',
                'cs' => 'Prohlížeče:',
                'de' => 'Browser:',
                'fr' => 'Navigateurs :',
                'es' => 'Navegadores:',
                'it' => 'Browser:',
                'pl' => 'Przeglądarki:',
            ),
            'no_data_period' => array(
                'en' => 'No pageviews recorded for this period yet.',
                'ru' => 'Пока нет зафиксированных переходов за выбранный период.',
                'uk' => 'Поки що немає зафіксованих переходів за вибраний період.',
                'cs' => 'Za vybrané období zatím nebyly zaznamenány žádné návštěvy.',
                'de' => 'Für diesen Zeitraum wurden noch keine Aufrufe erfasst.',
                'fr' => 'Aucune visite enregistrée pour cette période pour le moment.',
                'es' => 'Aún no se han registrado visitas para este período.',
                'it' => 'Nessuna visita registrata per questo periodo al momento.',
                'pl' => 'Brak zarejestrowanych odwiedzin w wybranym okresie.',
            ),
            'no_referrers' => array(
                'en' => 'No external referrers recorded yet (Direct / Internal traffic).',
                'ru' => 'Внешних рефереров пока не зафиксировано (прямой трафик / Direct).',
                'uk' => 'Зовнішніх реферерів поки що не зафіксовано (прямий трафік / Direct).',
                'cs' => 'Zatím nebyly zaznamenány žádné externí zdroje (přímý provoz / Direct).',
                'de' => 'Bisher wurden keine externen Referrer erfasst (Direkter Traffic).',
                'fr' => 'Aucun référent externe enregistré pour le moment (Trafic direct).',
                'es' => 'Aún no se han registrado referentes externos (Tráfico directo).',
                'it' => 'Nessun referrer esterno registrato al momento (Traffico diretto).',
                'pl' => 'Brak zewnętrznych źródeł odsyłających (ruch bezpośredni / Direct).',
            ),
            'no_countries' => array(
                'en' => 'No country data available yet.',
                'ru' => 'Данных о странах пока нет.',
                'uk' => 'Даних про країни поки що немає.',
                'cs' => 'Zatím nejsou k dispozici žádná data o zemích.',
                'de' => 'Noch keine Länderdaten verfügbar.',
                'fr' => 'Aucune donnée de pays disponible pour le moment.',
                'es' => 'Aún no hay datos de países disponibles.',
                'it' => 'Nessun dato sul paese ancora disponibile.',
                'pl' => 'Brak danych o krajach.',
            ),
            'no_data' => array(
                'en' => 'No data.',
                'ru' => 'Нет данных.',
                'uk' => 'Немає даних.',
                'cs' => 'Žádná data.',
                'de' => 'Keine Daten.',
                'fr' => 'Aucune donnée.',
                'es' => 'Sin datos.',
                'it' => 'Nessun dato.',
                'pl' => 'Brak danych.',
            ),
            'reset_btn' => array(
                'en' => '🗑️ Reset All Statistics',
                'ru' => '🗑️ Сбросить всю статистику',
                'uk' => '🗑️ Скинути всю статистику',
                'cs' => '🗑️ Resetovat veškeré statistiky',
                'de' => '🗑️ Alle Statistiken zurücksetzen',
                'fr' => '🗑️ Réinitialiser toutes les statistiques',
                'es' => '🗑️ Restablecer todas las estadísticas',
                'it' => '🗑️ Azzera tutte le statistiche',
                'pl' => '🗑️ Zresetuj wszystkie statystyki',
            ),
            'reset_confirm' => array(
                'en' => 'Are you sure you want to permanently clear all site statistics history?',
                'ru' => 'Вы уверены, что хотите полностью очистить всю историю статистики?',
                'uk' => 'Ви впевнені, що хочете повністю очистити всю історію статистики?',
                'cs' => 'Opravdu chcete trvale smazat celou historii statistik?',
                'de' => 'Sind Sie sicher, dass Sie den gesamten Statistikverlauf unwiderruflich löschen möchten?',
                'fr' => "Êtes-vous sûr de vouloir effacer définitivement tout l'historique des statistiques ?",
                'es' => '¿Está seguro de que desea eliminar permanentemente todo el historial de estadísticas?',
                'it' => 'Sei sicuro di voler cancellare definitivamente tutta la cronologia delle statistiche?',
                'pl' => 'Czy na pewno chcesz trwale wyczyścić całą historię statystyk?',
            ),
            'reset_success' => array(
                'en' => 'Statistics successfully reset.',
                'ru' => 'Статистика успешно сброшена.',
                'uk' => 'Статистику успішно скинуто.',
                'cs' => 'Statistika byla úspěšně resetována.',
                'de' => 'Statistiken erfolgreich zurückgesetzt.',
                'fr' => 'Statistiques réinitialisées avec succès.',
                'es' => 'Estadísticas restablecidas con éxito.',
                'it' => 'Statistiche azzerate con successo.',
                'pl' => 'Statystyki zostały pomyślnie zresetowane.',
            ),
            'access_denied' => array(
                'en' => 'Access restricted to administrators.',
                'ru' => 'Доступ ограничен администратором.',
                'uk' => 'Доступ обмежено адміністратором.',
                'cs' => 'Přístup omezen pouze pro administrátory.',
                'de' => 'Zugriff auf Administratoren beschränkt.',
                'fr' => 'Accès restreint aux administrateurs.',
                'es' => 'Acceso restringido a administradores.',
                'it' => 'Accesso riservato agli amministratori.',
                'pl' => 'Dostęp ograniczony do administratorów.',
            ),
            'footer' => array(
                'en' => 'Developed by: VladiMIR (GinCz) + AI | Retention: 90 days (auto-purge) | Cookieless GDPR',
                'ru' => 'Разработано: VladiMIR (GinCz) + AI | Хранение: 90 дней (автоочистка) | Cookieless GDPR',
                'uk' => 'Розроблено: VladiMIR (GinCz) + AI | Зберігання: 90 днів (автоочищення) | Cookieless GDPR',
                'cs' => 'Vyvinuto: VladiMIR (GinCz) + AI | Uchovávání: 90 dní (automatické čištění) | Cookieless GDPR',
                'de' => 'Entwickelt von: VladiMIR (GinCz) + AI | Speicherung: 90 Tage (Auto-Bereinigung) | Cookieless DSGVO',
                'fr' => 'Développé par : VladiMIR (GinCz) + AI | Rétention : 90 jours (purged auto) | RGPD sans cookies',
                'es' => 'Desarrollado por: VladiMIR (GinCz) + AI | Retención: 90 días (auto-limpieza) | RGPD sin cookies',
                'it' => 'Sviluppato da: VladiMIR (GinCz) + AI | Conservazione: 90 giorni (pulizia automatica) | GDPR senza cookie',
                'pl' => 'Opracowane przez: VladiMIR (GinCz) + AI | Przechowywanie: 90 dni (autoczyszczenie) | RODO bez plików cookie',
            ),
        );
    }

    if ( null === $lang ) {
        if ( function_exists( 'vladimir_ai_i18n_lang' ) ) {
            $lang = vladimir_ai_i18n_lang();
        } else {
            $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();
            $lang = strtolower( substr( (string) $locale, 0, 2 ) );
        }
    }

    if ( isset( $dict[$key][$lang] ) ) {
        return $dict[$key][$lang];
    }
    if ( isset( $dict[$key]['en'] ) ) {
        return $dict[$key]['en'];
    }
    return $key;
}

// ─────────────────────────────────────────────
// 1. ACTIVATION & DATABASE MIGRATION
// ─────────────────────────────────────────────

register_activation_hook( __FILE__, 'vladimir_ss_activate' );
function vladimir_ss_activate() {
    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';
    $charset_collate = $wpdb->get_charset_collate();

    $sql = "CREATE TABLE $table_name (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        hit_date DATE NOT NULL,
        hit_time INT UNSIGNED NOT NULL,
        page_url VARCHAR(255) NOT NULL,
        page_title VARCHAR(255) DEFAULT '',
        visitor_hash CHAR(32) NOT NULL,
        referrer VARCHAR(255) DEFAULT '',
        referrer_domain VARCHAR(100) DEFAULT '',
        device_type VARCHAR(20) NOT NULL DEFAULT 'desktop',
        browser VARCHAR(50) DEFAULT '',
        os VARCHAR(50) DEFAULT '',
        country CHAR(2) DEFAULT 'XX',
        PRIMARY KEY (id),
        KEY idx_date_page (hit_date, page_url(191)),
        KEY idx_date_visitor (hit_date, visitor_hash),
        KEY idx_hit_date (hit_date),
        KEY idx_referrer (referrer_domain)
    ) $charset_collate;";

    require_once ABSPATH . 'wp-admin/includes/upgrade.php';
    dbDelta( $sql );

    if ( ! wp_next_scheduled( 'vladimir_ss_daily_cleanup_cron' ) ) {
        wp_schedule_event( time() + 3600, 'daily', 'vladimir_ss_daily_cleanup_cron' );
    }
}

register_deactivation_hook( __FILE__, 'vladimir_ss_deactivate' );
function vladimir_ss_deactivate() {
    $timestamp = wp_next_scheduled( 'vladimir_ss_daily_cleanup_cron' );
    if ( $timestamp ) {
        wp_unschedule_event( $timestamp, 'vladimir_ss_daily_cleanup_cron' );
    }
}

// Daily retention purge (retain 90 days)
add_action( 'vladimir_ss_daily_cleanup_cron', 'vladimir_ss_purge_old_data' );
function vladimir_ss_purge_old_data() {
    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';
    $cutoff = gmdate( 'Y-m-d', strtotime( '-90 days' ) );
    $wpdb->query( $wpdb->prepare( "DELETE FROM $table_name WHERE hit_date < %s", $cutoff ) );
}

// ─────────────────────────────────────────────
// 2. FRONTEND TRACKING BEACON
// ─────────────────────────────────────────────

add_action( 'wp_footer', 'vladimir_ss_render_tracking_script', 999 );
function vladimir_ss_render_tracking_script() {
    // Exclude logged in admins from skewing traffic statistics
    if ( is_user_logged_in() && current_user_can( 'manage_options' ) ) {
        return;
    }

    $ajax_url = admin_url( 'admin-ajax.php?action=vladimir_ss_track' );
    $nonce    = wp_create_nonce( 'vladimir_ss_track_nonce' );
    ?>
    <script id="vladimir-ss-tracker">
    (function(){
        try {
            if (navigator.webdriver) return;
            var path = window.location.pathname + window.location.search;
            var ref  = document.referrer || '';
            var title = (document.title || '').substring(0, 150);
            var payload = JSON.stringify({
                action: 'vladimir_ss_track',
                nonce: '<?php echo esc_js( $nonce ); ?>',
                url: path,
                title: title,
                ref: ref,
                screen: (window.screen ? window.screen.width + 'x' + window.screen.height : '')
            });
            var endpoint = '<?php echo esc_url( $ajax_url ); ?>';
            if (navigator.sendBeacon) {
                var blob = new Blob([payload], {type: 'application/json'});
                navigator.sendBeacon(endpoint, blob);
            } else {
                var xhr = new XMLHttpRequest();
                xhr.open('POST', endpoint, true);
                xhr.setRequestHeader('Content-Type', 'application/json');
                xhr.send(payload);
            }
        } catch(e) {}
    })();
    </script>
    <?php
}

// ─────────────────────────────────────────────
// 3. TRACKING HANDLER (AJAX BEACON)
// ─────────────────────────────────────────────

add_action( 'wp_ajax_nopriv_vladimir_ss_track', 'vladimir_ss_handle_hit' );
add_action( 'wp_ajax_vladimir_ss_track', 'vladimir_ss_handle_hit' );

function vladimir_ss_handle_hit() {
    $raw = file_get_contents( 'php://input' );
    $data = json_decode( $raw, true );
    if ( ! is_array( $data ) ) {
        $data = $_POST;
    }

    $nonce = isset( $data['nonce'] ) ? sanitize_text_field( $data['nonce'] ) : '';
    if ( ! wp_verify_nonce( $nonce, 'vladimir_ss_track_nonce' ) ) {
        wp_send_json_error( 'invalid_nonce', 403 );
    }

    $ua = isset( $_SERVER['HTTP_USER_AGENT'] ) ? sanitize_text_field( $_SERVER['HTTP_USER_AGENT'] ) : '';

    // Filter out bots and crawlers
    if ( vladimir_ss_is_bot( $ua ) ) {
        wp_send_json_success( array( 'status' => 'bot_ignored' ) );
    }

    // IP Extraction (Cloudflare / Reverse Proxy aware)
    $ip = vladimir_ss_get_client_ip();

    // Rotating anonymized salt (GDPR cookieless identity)
    $salt = get_option( 'vladimir_ss_salt' );
    if ( ! $salt ) {
        $salt = wp_generate_password( 32, true, true );
        update_option( 'vladimir_ss_salt', $salt, false );
    }
    $visitor_hash = md5( $ip . $ua . gmdate('Y-m') . $salt );

    // Country extraction (Cloudflare / Server GeoIP)
    $country = 'XX';
    if ( ! empty( $_SERVER['HTTP_CF_IPCOUNTRY'] ) ) {
        $country = strtoupper( substr( sanitize_text_field( $_SERVER['HTTP_CF_IPCOUNTRY'] ), 0, 2 ) );
    } elseif ( ! empty( $_SERVER['GEOIP_COUNTRY_CODE'] ) ) {
        $country = strtoupper( substr( sanitize_text_field( $_SERVER['GEOIP_COUNTRY_CODE'] ), 0, 2 ) );
    }

    // Device, OS, Browser parsing
    $device  = vladimir_ss_detect_device( $ua );
    $browser = vladimir_ss_detect_browser( $ua );
    $os      = vladimir_ss_detect_os( $ua );

    // Page URL & Title
    $raw_url = isset( $data['url'] ) ? sanitize_text_field( $data['url'] ) : '/';
    $page_url = substr( $raw_url, 0, 255 );
    $page_title = isset( $data['title'] ) ? sanitize_text_field( substr( $data['title'], 0, 255 ) ) : '';

    // Referrer & Domain parsing
    $raw_ref = isset( $data['ref'] ) ? esc_url_raw( $data['ref'] ) : '';
    $ref_domain = '';
    if ( ! empty( $raw_ref ) ) {
        $parsed = parse_url( $raw_ref, PHP_URL_HOST );
        $ref_domain = $parsed ? preg_replace( '/^www\./i', '', strtolower( $parsed ) ) : '';
        $site_host  = parse_url( home_url(), PHP_URL_HOST );
        if ( $ref_domain === $site_host ) {
            $ref_domain = '';
        }
    }
    if ( empty( $ref_domain ) ) {
        $ref_domain = 'Direct / Internal';
    }

    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';
    $now = current_time( 'timestamp' );
    $today = gmdate( 'Y-m-d', $now );

    $wpdb->insert(
        $table_name,
        array(
            'hit_date'        => $today,
            'hit_time'        => $now,
            'page_url'        => $page_url,
            'page_title'      => $page_title,
            'visitor_hash'    => $visitor_hash,
            'referrer'        => substr( $raw_ref, 0, 255 ),
            'referrer_domain' => substr( $ref_domain, 0, 100 ),
            'device_type'     => $device,
            'browser'         => $browser,
            'os'              => $os,
            'country'         => $country,
        ),
        array( '%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s' )
    );

    wp_send_json_success( array( 'status' => 'tracked' ) );
}

function vladimir_ss_get_client_ip() {
    $headers = array(
        'HTTP_CF_CONNECTING_IP',
        'HTTP_X_REAL_IP',
        'HTTP_X_FORWARDED_FOR',
        'REMOTE_ADDR'
    );
    foreach ( $headers as $h ) {
        if ( ! empty( $_SERVER[$h] ) ) {
            $val = explode( ',', $_SERVER[$h] );
            $ip = trim( $val[0] );
            if ( filter_var( $ip, FILTER_VALIDATE_IP ) ) {
                return $ip;
            }
        }
    }
    return '127.0.0.1';
}

function vladimir_ss_is_bot( $ua ) {
    if ( empty( $ua ) ) return true;
    $bots = array(
        'bot', 'crawl', 'spider', 'slurp', 'yandex', 'googlebot', 'bingbot',
        'duckduckbot', 'baiduspider', 'facebookexternalhit', 'twitterbot',
        'telegrambot', 'whatsapp', 'semrush', 'ahrefs', 'mj12bot', 'dotbot',
        'uptime', 'curl', 'wget', 'python', 'headlesschrome', 'phantomjs'
    );
    $pattern = '/' . implode( '|', $bots ) . '/i';
    return (bool) preg_match( $pattern, $ua );
}

function vladimir_ss_detect_device( $ua ) {
    if ( preg_match( '/tablet|ipad/i', $ua ) ) return 'tablet';
    if ( preg_match( '/mobile|iphone|android|ipod|blackberry|iemobile|opera mini/i', $ua ) ) return 'mobile';
    return 'desktop';
}

function vladimir_ss_detect_browser( $ua ) {
    if ( preg_match( '/edg/i', $ua ) ) return 'Edge';
    if ( preg_match( '/opr|opera/i', $ua ) ) return 'Opera';
    if ( preg_match( '/chrome|crios/i', $ua ) ) return 'Chrome';
    if ( preg_match( '/firefox|fxios/i', $ua ) ) return 'Firefox';
    if ( preg_match( '/safari/i', $ua ) && ! preg_match( '/chrome|crios/i', $ua ) ) return 'Safari';
    if ( preg_match( '/msie|trident/i', $ua ) ) return 'IE';
    return 'Other';
}

function vladimir_ss_detect_os( $ua ) {
    if ( preg_match( '/windows nt 10/i', $ua ) ) return 'Windows 10/11';
    if ( preg_match( '/windows nt/i', $ua ) ) return 'Windows';
    if ( preg_match( '/iphone|ipad|ipod/i', $ua ) ) return 'iOS';
    if ( preg_match( '/android/i', $ua ) ) return 'Android';
    if ( preg_match( '/macintosh|mac os x/i', $ua ) ) return 'macOS';
    if ( preg_match( '/linux/i', $ua ) ) return 'Linux';
    return 'Other';
}

// ─────────────────────────────────────────────
// 4. ADMIN DASHBOARD & MENU
// ─────────────────────────────────────────────

add_action( 'admin_menu', 'vladimir_ss_add_admin_menu' );
function vladimir_ss_add_admin_menu() {
    add_menu_page(
        vladimir_ss_t( 'page_title' ),
        vladimir_ss_t( 'menu_title' ),
        'manage_options',
        'site-stats',
        'vladimir_ss_render_dashboard',
        'dashicons-chart-area',
        3
    );
}

function vladimir_ss_render_dashboard() {
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( esc_html( vladimir_ss_t( 'access_denied' ) ) );
    }

    global $wpdb;
    $table_name = $wpdb->prefix . 'site_stats';

    // Handle stats reset if requested
    if ( isset( $_POST['vladimir_ss_reset_action'] ) && check_admin_referer( 'vladimir_ss_reset_nonce' ) ) {
        $wpdb->query( "TRUNCATE TABLE $table_name" );
        echo '<div class="notice notice-success is-dismissible"><p>' . esc_html( vladimir_ss_t( 'reset_success' ) ) . '</p></div>';
    }

    $range = isset( $_GET['range'] ) ? sanitize_text_field( $_GET['range'] ) : '7d';
    $today = gmdate( 'Y-m-d', current_time( 'timestamp' ) );

    switch ( $range ) {
        case 'today':
            $start_date = $today;
            $range_title = vladimir_ss_t( 'today' ) . ' (' . date_i18n( 'j F Y' ) . ')';
            $days_count = 1;
            break;
        case 'yesterday':
            $start_date = gmdate( 'Y-m-d', strtotime( '-1 day', current_time( 'timestamp' ) ) );
            $today = $start_date;
            $range_title = vladimir_ss_t( 'yesterday' ) . ' (' . date_i18n( 'j F Y', strtotime( '-1 day' ) ) . ')';
            $days_count = 1;
            break;
        case '30d':
            $start_date = gmdate( 'Y-m-d', strtotime( '-29 days', current_time( 'timestamp' ) ) );
            $range_title = vladimir_ss_t( 'last_30_days' );
            $days_count = 30;
            break;
        case '7d':
        default:
            $range = '7d';
            $start_date = gmdate( 'Y-m-d', strtotime( '-6 days', current_time( 'timestamp' ) ) );
            $range_title = vladimir_ss_t( 'last_7_days' );
            $days_count = 7;
            break;
    }

    // High level metrics
    $total_views = (int) $wpdb->get_var( $wpdb->prepare(
        "SELECT COUNT(*) FROM $table_name WHERE hit_date >= %s AND hit_date <= %s",
        $start_date, $today
    ) );

    $unique_visitors = (int) $wpdb->get_var( $wpdb->prepare(
        "SELECT COUNT(DISTINCT visitor_hash) FROM $table_name WHERE hit_date >= %s AND hit_date <= %s",
        $start_date, $today
    ) );

    $pages_per_visit = $unique_visitors > 0 ? round( $total_views / $unique_visitors, 2 ) : 0;

    // Daily breakdown for SVG chart
    $daily_stats = $wpdb->get_results( $wpdb->prepare(
        "SELECT hit_date, COUNT(*) as views, COUNT(DISTINCT visitor_hash) as visitors
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY hit_date
         ORDER BY hit_date ASC",
        $start_date, $today
    ), ARRAY_A );

    $chart_map = array();
    if ( is_array( $daily_stats ) ) {
        foreach ( $daily_stats as $row ) {
            $chart_map[$row['hit_date']] = array(
                'views' => (int) $row['views'],
                'visitors' => (int) $row['visitors']
            );
        }
    }

    // Top Pages
    $top_pages = $wpdb->get_results( $wpdb->prepare(
        "SELECT page_url, page_title, COUNT(*) as views, COUNT(DISTINCT visitor_hash) as visitors
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY page_url
         ORDER BY views DESC
         LIMIT 10",
        $start_date, $today
    ), ARRAY_A );

    // Top Referrers
    $top_referrers = $wpdb->get_results( $wpdb->prepare(
        "SELECT referrer_domain, COUNT(*) as views
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s AND referrer_domain != '' AND referrer_domain != 'Direct / Internal'
         GROUP BY referrer_domain
         ORDER BY views DESC
         LIMIT 10",
        $start_date, $today
    ), ARRAY_A );

    // Top Countries
    $top_countries = $wpdb->get_results( $wpdb->prepare(
        "SELECT country, COUNT(*) as views, COUNT(DISTINCT visitor_hash) as visitors
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY country
         ORDER BY views DESC
         LIMIT 8",
        $start_date, $today
    ), ARRAY_A );

    // Devices & Browsers
    $devices = $wpdb->get_results( $wpdb->prepare(
        "SELECT device_type, COUNT(*) as count
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY device_type
         ORDER BY count DESC",
        $start_date, $today
    ), ARRAY_A );

    $browsers = $wpdb->get_results( $wpdb->prepare(
        "SELECT browser, COUNT(*) as count
         FROM $table_name
         WHERE hit_date >= %s AND hit_date <= %s
         GROUP BY browser
         ORDER BY count DESC
         LIMIT 5",
        $start_date, $today
    ), ARRAY_A );

    $flag_names = array(
        'CZ' => '🇨🇿 Czech Republic (Česko)',
        'SK' => '🇸🇰 Slovakia (Slovensko)',
        'DE' => '🇩🇪 Germany (Deutschland)',
        'UA' => '🇺🇦 Ukraine (Україна)',
        'PL' => '🇵🇱 Poland (Polska)',
        'AT' => '🇦🇹 Austria (Österreich)',
        'RU' => '🇷🇺 Russia (Россия)',
        'US' => '🇺🇸 United States',
        'GB' => '🇬🇧 United Kingdom',
        'FR' => '🇫🇷 France',
        'IT' => '🇮🇹 Italy (Italia)',
        'ES' => '🇪🇸 Spain (España)',
        'NL' => '🇳🇱 Netherlands',
        'CH' => '🇨🇭 Switzerland',
        'XX' => '🌐 Direct / Unknown'
    );
    ?>
    <div class="wrap vladimir-ss-wrap">
        <div class="vladimir-ss-header">
            <div class="vladimir-ss-header-title">
                <h1>📊 <?php echo esc_html( vladimir_ss_t( 'page_title' ) ); ?></h1>
                <p class="description"><?php echo esc_html( vladimir_ss_t( 'desc' ) ); ?></p>
            </div>
            <div class="vladimir-ss-range-nav">
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=today' ) ); ?>" class="button <?php echo $range === 'today' ? 'button-primary' : ''; ?>"><?php echo esc_html( vladimir_ss_t( 'today' ) ); ?></a>
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=yesterday' ) ); ?>" class="button <?php echo $range === 'yesterday' ? 'button-primary' : ''; ?>"><?php echo esc_html( vladimir_ss_t( 'yesterday' ) ); ?></a>
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=7d' ) ); ?>" class="button <?php echo $range === '7d' ? 'button-primary' : ''; ?>"><?php echo esc_html( vladimir_ss_t( '7d' ) ); ?></a>
                <a href="<?php echo esc_url( admin_url( 'admin.php?page=site-stats&range=30d' ) ); ?>" class="button <?php echo $range === '30d' ? 'button-primary' : ''; ?>"><?php echo esc_html( vladimir_ss_t( '30d' ) ); ?></a>
            </div>
        </div>

        <!-- KPI SUMMARY CARDS -->
        <div class="vladimir-ss-cards">
            <div class="vladimir-ss-card">
                <div class="card-label"><?php echo esc_html( vladimir_ss_t( 'unique_visitors' ) ); ?></div>
                <div class="card-val"><?php echo number_format_i18n( $unique_visitors ); ?></div>
                <div class="card-sub"><?php echo esc_html( $range_title ); ?></div>
            </div>
            <div class="vladimir-ss-card">
                <div class="card-label"><?php echo esc_html( vladimir_ss_t( 'page_views' ) ); ?></div>
                <div class="card-val"><?php echo number_format_i18n( $total_views ); ?></div>
                <div class="card-sub"><?php echo esc_html( $range_title ); ?></div>
            </div>
            <div class="vladimir-ss-card">
                <div class="card-label"><?php echo esc_html( vladimir_ss_t( 'depth' ) ); ?></div>
                <div class="card-val"><?php echo esc_html( $pages_per_visit ); ?></div>
                <div class="card-sub"><?php echo esc_html( vladimir_ss_t( 'avg_engagement' ) ); ?></div>
            </div>
            <div class="vladimir-ss-card">
                <div class="card-label"><?php echo esc_html( vladimir_ss_t( 'top_source' ) ); ?></div>
                <div class="card-val" style="font-size: 20px;">
                    <?php echo ! empty( $top_referrers[0]['referrer_domain'] ) ? esc_html( $top_referrers[0]['referrer_domain'] ) : esc_html( vladimir_ss_t( 'direct' ) ); ?>
                </div>
                <div class="card-sub"><?php echo ! empty( $top_referrers[0]['views'] ) ? esc_html( $top_referrers[0]['views'] . ' ' . vladimir_ss_t( 'transitions' ) ) : '100% Direct'; ?></div>
            </div>
        </div>

        <!-- TIMELINE CHART (SVG) -->
        <div class="vladimir-ss-box">
            <h2><?php echo esc_html( vladimir_ss_t( 'traffic_trend' ) ); ?> (<?php echo esc_html( $range_title ); ?>)</h2>
            <div class="vladimir-ss-chart-container">
                <?php
                // Generate chronological days list
                $chart_labels = array();
                $chart_views  = array();
                $chart_users  = array();
                $max_val = 1;

                for ( $i = $days_count - 1; $i >= 0; $i-- ) {
                    $d = gmdate( 'Y-m-d', strtotime( "-$i days", strtotime( $today ) ) );
                    $v = isset( $chart_map[$d] ) ? $chart_map[$d]['views'] : 0;
                    $u = isset( $chart_map[$d] ) ? $chart_map[$d]['visitors'] : 0;
                    $chart_labels[] = date_i18n( 'd.m', strtotime( $d ) );
                    $chart_views[]  = $v;
                    $chart_users[]  = $u;
                    if ( $v > $max_val ) $max_val = $v;
                    if ( $u > $max_val ) $max_val = $u;
                }

                $svg_w = 900;
                $svg_h = 220;
                $pad_l = 40;
                $pad_r = 20;
                $pad_t = 20;
                $pad_b = 35;
                $plot_w = $svg_w - $pad_l - $pad_r;
                $plot_h = $svg_h - $pad_t - $pad_b;
                $count = count( $chart_labels );
                $step_x = $count > 1 ? $plot_w / ( $count - 1 ) : $plot_w;

                $pts_views = array();
                $pts_users = array();
                for ( $idx = 0; $idx < $count; $idx++ ) {
                    $x = $pad_l + ( $idx * $step_x );
                    $y_v = $pad_t + $plot_h - ( ( $chart_views[$idx] / $max_val ) * $plot_h );
                    $y_u = $pad_t + $plot_h - ( ( $chart_users[$idx] / $max_val ) * $plot_h );
                    $pts_views[] = "$x,$y_v";
                    $pts_users[] = "$x,$y_u";
                }
                $polyline_views = implode( ' ', $pts_views );
                $polyline_users = implode( ' ', $pts_users );
                ?>
                <svg viewBox="0 0 <?php echo $svg_w; ?> <?php echo $svg_h; ?>" class="vladimir-ss-svg">
                    <!-- Grid Lines -->
                    <line x1="<?php echo $pad_l; ?>" y1="<?php echo $pad_t; ?>" x2="<?php echo $svg_w - $pad_r; ?>" y2="<?php echo $pad_t; ?>" stroke="#eee" stroke-dasharray="4"/>
                    <line x1="<?php echo $pad_l; ?>" y1="<?php echo $pad_t + ($plot_h/2); ?>" x2="<?php echo $svg_w - $pad_r; ?>" y2="<?php echo $pad_t + ($plot_h/2); ?>" stroke="#eee" stroke-dasharray="4"/>
                    <line x1="<?php echo $pad_l; ?>" y1="<?php echo $pad_t + $plot_h; ?>" x2="<?php echo $svg_w - $pad_r; ?>" y2="<?php echo $pad_t + $plot_h; ?>" stroke="#ccc"/>

                    <!-- Y-Axis labels -->
                    <text x="<?php echo $pad_l - 8; ?>" y="<?php echo $pad_t + 4; ?>" text-anchor="end" font-size="11" fill="#888"><?php echo $max_val; ?></text>
                    <text x="<?php echo $pad_l - 8; ?>" y="<?php echo $pad_t + ($plot_h/2) + 4; ?>" text-anchor="end" font-size="11" fill="#888"><?php echo round($max_val/2); ?></text>
                    <text x="<?php echo $pad_l - 8; ?>" y="<?php echo $pad_t + $plot_h + 4; ?>" text-anchor="end" font-size="11" fill="#888">0</text>

                    <!-- Views Polyline (Blue) -->
                    <polyline points="<?php echo $polyline_views; ?>" fill="none" stroke="#2271b1" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
                    <!-- Visitors Polyline (Green) -->
                    <polyline points="<?php echo $polyline_users; ?>" fill="none" stroke="#00a32a" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>

                    <!-- Data dots and X labels -->
                    <?php for ( $idx = 0; $idx < $count; $idx++ ):
                        $x = $pad_l + ( $idx * $step_x );
                        $y_v = $pad_t + $plot_h - ( ( $chart_views[$idx] / $max_val ) * $plot_h );
                        $y_u = $pad_t + $plot_h - ( ( $chart_users[$idx] / $max_val ) * $plot_h );
                    ?>
                        <circle cx="<?php echo $x; ?>" cy="<?php echo $y_v; ?>" r="4" fill="#2271b1"/>
                        <circle cx="<?php echo $x; ?>" cy="<?php echo $y_u; ?>" r="4" fill="#00a32a"/>
                        <text x="<?php echo $x; ?>" y="<?php echo $svg_h - 10; ?>" text-anchor="middle" font-size="11" fill="#666"><?php echo $chart_labels[$idx]; ?></text>
                    <?php endfor; ?>
                </svg>
                <div class="vladimir-ss-chart-legend">
                    <span class="legend-item"><span class="legend-color" style="background: #2271b1;"></span> <?php echo esc_html( vladimir_ss_t( 'views_legend' ) ); ?></span>
                    <span class="legend-item"><span class="legend-color" style="background: #00a32a;"></span> <?php echo esc_html( vladimir_ss_t( 'visitors_legend' ) ); ?></span>
                </div>
            </div>
        </div>

        <!-- DETAILS GRID -->
        <div class="vladimir-ss-grid">
            <!-- Top Pages -->
            <div class="vladimir-ss-box">
                <h2><?php echo esc_html( vladimir_ss_t( 'top_pages' ) ); ?></h2>
                <?php if ( empty( $top_pages ) ): ?>
                    <p class="description"><?php echo esc_html( vladimir_ss_t( 'no_data_period' ) ); ?></p>
                <?php else: ?>
                    <table class="widefat striped">
                        <thead>
                            <tr>
                                <th><?php echo esc_html( vladimir_ss_t( 'page' ) ); ?></th>
                                <th style="width: 90px; text-align: right;"><?php echo esc_html( vladimir_ss_t( 'hits' ) ); ?></th>
                                <th style="width: 90px; text-align: right;"><?php echo esc_html( vladimir_ss_t( 'uniques' ) ); ?></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ( $top_pages as $p ): ?>
                            <tr>
                                <td>
                                    <a href="<?php echo esc_url( home_url( $p['page_url'] ) ); ?>" target="_blank" style="font-weight: 500;">
                                        <?php echo esc_html( ! empty( $p['page_title'] ) ? $p['page_title'] : $p['page_url'] ); ?>
                                    </a>
                                    <div class="page-slug" style="font-size: 11px; color: #888;"><?php echo esc_html( $p['page_url'] ); ?></div>
                                </td>
                                <td style="text-align: right; font-weight: 600; color: #2271b1;"><?php echo number_format_i18n( $p['views'] ); ?></td>
                                <td style="text-align: right; color: #00a32a;"><?php echo number_format_i18n( $p['visitors'] ); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>

            <!-- Top Referrers -->
            <div class="vladimir-ss-box">
                <h2><?php echo esc_html( vladimir_ss_t( 'referrers' ) ); ?></h2>
                <?php if ( empty( $top_referrers ) ): ?>
                    <p class="description"><?php echo esc_html( vladimir_ss_t( 'no_referrers' ) ); ?></p>
                <?php else: ?>
                    <table class="widefat striped">
                        <thead>
                            <tr>
                                <th><?php echo esc_html( vladimir_ss_t( 'source' ) ); ?></th>
                                <th style="width: 100px; text-align: right;"><?php echo esc_html( vladimir_ss_t( 'views' ) ); ?></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ( $top_referrers as $r ): ?>
                            <tr>
                                <td><strong><?php echo esc_html( $r['referrer_domain'] ); ?></strong></td>
                                <td style="text-align: right; font-weight: 600; color: #2271b1;"><?php echo number_format_i18n( $r['views'] ); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>

            <!-- Countries -->
            <div class="vladimir-ss-box">
                <h2><?php echo esc_html( vladimir_ss_t( 'geography' ) ); ?></h2>
                <?php if ( empty( $top_countries ) ): ?>
                    <p class="description"><?php echo esc_html( vladimir_ss_t( 'no_countries' ) ); ?></p>
                <?php else: ?>
                    <table class="widefat striped">
                        <thead>
                            <tr>
                                <th><?php echo esc_html( vladimir_ss_t( 'country' ) ); ?></th>
                                <th style="width: 80px; text-align: right;"><?php echo esc_html( vladimir_ss_t( 'views' ) ); ?></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ( $top_countries as $c ):
                                $c_name = isset( $flag_names[$c['country']] ) ? $flag_names[$c['country']] : '🏳️ ' . $c['country'];
                            ?>
                            <tr>
                                <td><strong><?php echo esc_html( $c_name ); ?></strong></td>
                                <td style="text-align: right; font-weight: 600;"><?php echo number_format_i18n( $c['views'] ); ?></td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                <?php endif; ?>
            </div>

            <!-- Devices & Browsers -->
            <div class="vladimir-ss-box">
                <h2><?php echo esc_html( vladimir_ss_t( 'devices_browsers' ) ); ?></h2>
                <div style="margin-bottom: 15px;">
                    <h4 style="margin: 0 0 8px 0;"><?php echo esc_html( vladimir_ss_t( 'devices' ) ); ?></h4>
                    <?php if ( empty( $devices ) ): ?>
                        <p class="description"><?php echo esc_html( vladimir_ss_t( 'no_data' ) ); ?></p>
                    <?php else: ?>
                        <?php foreach ( $devices as $dev ):
                            $icon = $dev['device_type'] === 'mobile' ? '📱 Mobile' : ( $dev['device_type'] === 'tablet' ? '📟 Tablet' : '💻 Desktop' );
                        ?>
                            <div style="display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #f0f0f1;">
                                <span><?php echo esc_html( $icon ); ?></span>
                                <span style="font-weight: 600;"><?php echo number_format_i18n( $dev['count'] ); ?></span>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>

                <div>
                    <h4 style="margin: 15px 0 8px 0;"><?php echo esc_html( vladimir_ss_t( 'browsers' ) ); ?></h4>
                    <?php if ( empty( $browsers ) ): ?>
                        <p class="description"><?php echo esc_html( vladimir_ss_t( 'no_data' ) ); ?></p>
                    <?php else: ?>
                        <?php foreach ( $browsers as $b ): ?>
                            <div style="display: flex; justify-content: space-between; padding: 4px 0; border-bottom: 1px solid #f0f0f1;">
                                <span>🌐 <?php echo esc_html( $b['browser'] ); ?></span>
                                <span style="font-weight: 600;"><?php echo number_format_i18n( $b['count'] ); ?></span>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>
            </div>
        </div>

        <!-- MAINTENANCE & RESET -->
        <div class="vladimir-ss-footer">
            <form method="post" onsubmit="return confirm('<?php echo esc_js( vladimir_ss_t( 'reset_confirm' ) ); ?>');">
                <?php wp_nonce_field( 'vladimir_ss_reset_nonce' ); ?>
                <input type="hidden" name="vladimir_ss_reset_action" value="1">
                <button type="submit" class="button button-link-delete" style="color: #b32d2e; text-decoration: none;">
                    <?php echo esc_html( vladimir_ss_t( 'reset_btn' ) ); ?>
                </button>
            </form>
            <div style="font-size: 12px; color: #888;">
                <?php echo esc_html( vladimir_ss_t( 'footer' ) ); ?>
            </div>
        </div>
    </div>

    <style>
    .vladimir-ss-wrap { max-width: 1200px; margin-top: 20px; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif; }
    .vladimir-ss-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; flex-wrap: wrap; gap: 15px; }
    .vladimir-ss-header h1 { margin: 0 0 5px 0; font-size: 24px; font-weight: 700; color: #1d2327; }
    .vladimir-ss-range-nav .button { padding: 4px 14px; height: 34px; font-weight: 500; }
    .vladimir-ss-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 15px; margin-bottom: 25px; }
    .vladimir-ss-card { background: #fff; border: 1px solid #c3c4c7; border-radius: 8px; padding: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
    .vladimir-ss-card .card-label { font-size: 13px; color: #646970; font-weight: 600; margin-bottom: 8px; }
    .vladimir-ss-card .card-val { font-size: 32px; font-weight: 700; color: #1d2327; line-height: 1.1; margin-bottom: 6px; }
    .vladimir-ss-card .card-sub { font-size: 12px; color: #8c8f94; }
    .vladimir-ss-box { background: #fff; border: 1px solid #c3c4c7; border-radius: 8px; padding: 20px; margin-bottom: 25px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
    .vladimir-ss-box h2 { margin: 0 0 15px 0; font-size: 16px; font-weight: 600; color: #1d2327; border-bottom: 1px solid #f0f0f1; padding-bottom: 10px; }
    .vladimir-ss-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(380px, 1fr)); gap: 20px; }
    .vladimir-ss-chart-container { width: 100%; overflow-x: auto; }
    .vladimir-ss-svg { width: 100%; height: auto; max-height: 250px; }
    .vladimir-ss-chart-legend { display: flex; justify-content: center; gap: 25px; margin-top: 10px; font-size: 13px; font-weight: 500; }
    .vladimir-ss-chart-legend .legend-item { display: inline-flex; align-items: center; gap: 6px; }
    .vladimir-ss-chart-legend .legend-color { width: 12px; height: 12px; border-radius: 3px; display: inline-block; }
    .vladimir-ss-footer { display: flex; justify-content: space-between; align-items: center; padding: 15px 0; border-top: 1px solid #dcdcde; margin-top: 10px; }
    </style>
    <?php
}
