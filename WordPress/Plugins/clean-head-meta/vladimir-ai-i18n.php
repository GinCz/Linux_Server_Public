<?php
/**
 * VladiMIR+AI Suite - shared plugin-list translations (8 languages).
 *
 * Master copy: WordPress/_shared/vladimir-ai-i18n.php
 * A byte-identical copy ships inside every plugin folder. The first plugin loaded
 * registers the all_plugins filter, the rest short-circuit, so the whole suite is
 * translated by one table instead of one duplicated block per plugin.
 *
 * Mandatory languages (see WordPress/README.md): en, ru, cs, de, it, es, fr, pl.
 * English is the fallback and is taken from the plugin header, not from this table.
 *
 * Plugin NAMES are deliberately not translated: the name is the brand and must read
 * identically in every admin, including the (VladiMIR+AI) green-check tag.
 *
 * @package VladiMIR_AI_Suite
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Two independent guards, for the same reason as in vladimir-ai-updater.php: a constant
// check alone allowed a second copy of this file to redeclare its functions and kill the
// site with a fatal error. The function check cannot be fooled by a stale opcode cache.
if ( defined( 'VLADIMIR_AI_I18N_LOADED' ) || function_exists( 'vladimir_ai_i18n_table' ) ) {
    return;
}
define( 'VLADIMIR_AI_I18N_LOADED', '2026-09__1.23' );

/**
 * Description of every suite plugin, keyed by folder slug then by language code.
 *
 * @return array<string,array<string,string>>
 */
function vladimir_ai_i18n_table() {
    return array(
        '404-410-301' => array(
            'ru' => 'Отдаёт поисковикам честный HTTP 404/410 для быстрого удаления битых ссылок из индекса и плавно перенаправляет посетителя на главную по таймеру.',
            'cs' => 'Vrací vyhledávačům korektní HTTP 404/410 pro rychlé odstranění mrtvých odkazů z indexu a návštěvníka plynule přesměruje na úvodní stránku s odpočtem.',
            'de' => 'Liefert Suchmaschinen einen echten HTTP-404/410-Status zur schnellen Deindexierung toter Links und leitet Besucher per Countdown sanft zur Startseite weiter.',
            'it' => 'Restituisce ai motori di ricerca un vero stato HTTP 404/410 per la rapida deindicizzazione dei link morti e reindirizza i visitatori alla home con un conto alla rovescia.',
            'es' => 'Devuelve a los buscadores un estado HTTP 404/410 real para desindexar rápidamente los enlaces rotos y redirige a las visitas a la portada con una cuenta atrás.',
            'fr' => 'Renvoie aux moteurs de recherche un vrai statut HTTP 404/410 pour désindexer rapidement les liens morts et redirige les visiteurs vers l\'accueil avec un compte à rebours.',
            'pl' => 'Zwraca wyszukiwarkom prawdziwy status HTTP 404/410 w celu szybkiego usunięcia martwych linków z indeksu i płynnie przekierowuje odwiedzających na stronę główną z odliczaniem.',
        ),
        'classic-editor-tinymce' => array(
            'ru' => 'Возвращает классический редактор: отключает Gutenberg и блочные виджеты, держит открытой вторую строку панели форматирования (шрифты, цвета, таблицы, очистка стилей).',
            'cs' => 'Vrací klasický editor: vypíná Gutenberg i blokové widgety a nechává otevřenou druhou řádku formátovací lišty (písma, barvy, tabulky, čištění stylů).',
            'de' => 'Stellt den klassischen Editor wieder her: deaktiviert Gutenberg und Block-Widgets und hält die zweite Formatierungsleiste geöffnet (Schriften, Farben, Tabellen, Formatierung entfernen).',
            'it' => 'Ripristina l\'editor classico: disattiva Gutenberg e i widget a blocchi e mantiene aperta la seconda barra di formattazione (font, colori, tabelle, rimozione stili).',
            'es' => 'Restaura el editor clásico: desactiva Gutenberg y los widgets de bloques y mantiene abierta la segunda barra de formato (fuentes, colores, tablas, limpiar formato).',
            'fr' => 'Rétablit l\'éditeur classique : désactive Gutenberg et les widgets blocs et garde ouverte la deuxième barre de mise en forme (polices, couleurs, tableaux, effacer la mise en forme).',
            'pl' => 'Przywraca klasyczny edytor: wyłącza Gutenberga i widżety blokowe oraz trzyma otwarty drugi rząd paska formatowania (czcionki, kolory, tabele, czyszczenie stylów).',
        ),
        'clean-head-meta' => array(
            'ru' => 'Чистит мусор в <head>, скрывает номер версии WordPress, закрывает XML-RPC и пингбеки, убирает emoji-скрипты и добавляет авторские мета-теги.',
            'cs' => 'Čistí nepořádek v <head>, skrývá verzi WordPressu, zavírá XML-RPC a pingbacky, odstraňuje emoji skripty a přidává autorské meta tagy.',
            'de' => 'Räumt den <head> auf, verbirgt die WordPress-Version, schließt XML-RPC und Pingbacks, entfernt Emoji-Skripte und ergänzt Autoren-Meta-Tags.',
            'it' => 'Ripulisce il <head>, nasconde la versione di WordPress, chiude XML-RPC e i pingback, rimuove gli script emoji e aggiunge i meta tag autore.',
            'es' => 'Limpia el <head>, oculta la versión de WordPress, cierra XML-RPC y los pingbacks, elimina los scripts de emoji y añade metaetiquetas de autor.',
            'fr' => 'Nettoie le <head>, masque la version de WordPress, ferme XML-RPC et les pingbacks, supprime les scripts emoji et ajoute les métabalises d\'auteur.',
            'pl' => 'Czyści śmieci w <head>, ukrywa wersję WordPressa, zamyka XML-RPC i pingbacki, usuwa skrypty emoji i dodaje metatagi autora.',
        ),
        'disable-update-emails' => array(
            'ru' => 'Блокирует служебные письма об автообновлении ядра, плагинов и тем, которые WordPress шлёт администратору. Нулевые накладные расходы.',
            'cs' => 'Blokuje servisní e-maily o automatických aktualizacích jádra, pluginů a šablon, které WordPress posílá správci. Nulová zátěž.',
            'de' => 'Blockiert die Benachrichtigungs-E-Mails zu automatischen Updates von Core, Plugins und Themes an den Administrator. Ohne Mehraufwand.',
            'it' => 'Blocca le e-mail di notifica sugli aggiornamenti automatici di core, plugin e temi inviate all\'amministratore. Nessun sovraccarico.',
            'es' => 'Bloquea los correos de notificación sobre actualizaciones automáticas del núcleo, plugins y temas enviados al administrador. Sin sobrecarga.',
            'fr' => 'Bloque les e-mails de notification concernant les mises à jour automatiques du cœur, des extensions et des thèmes envoyés à l\'administrateur. Aucun surcoût.',
            'pl' => 'Blokuje e-maile powiadomień o automatycznych aktualizacjach rdzenia, wtyczek i motywów wysyłane do administratora. Zero narzutu.',
        ),
        'image-resizer' => array(
            'ru' => 'Автоматически уменьшает большие JPEG, PNG и WebP при загрузке до заданного размера с высоким качеством сжатия. Экономит место на диске и ускоряет сайт.',
            'cs' => 'Automaticky zmenšuje velké soubory JPEG, PNG a WebP při nahrávání na zvolený rozměr s vysokou kvalitou komprese. Šetří místo na disku a zrychluje web.',
            'de' => 'Verkleinert große JPEG-, PNG- und WebP-Uploads automatisch auf eine einstellbare Maximalgröße bei hoher Qualität. Spart Speicherplatz und beschleunigt die Website.',
            'it' => 'Ridimensiona automaticamente i caricamenti JPEG, PNG e WebP di grandi dimensioni fino a un massimo configurabile con compressione di alta qualità. Risparmia spazio e velocizza il sito.',
            'es' => 'Redimensiona automáticamente las subidas grandes de JPEG, PNG y WebP a un máximo configurable con compresión de alta calidad. Ahorra espacio en disco y acelera el sitio.',
            'fr' => 'Redimensionne automatiquement les envois volumineux JPEG, PNG et WebP à une taille maximale configurable avec une compression de haute qualité. Économise l\'espace disque et accélère le site.',
            'pl' => 'Automatycznie zmniejsza duże pliki JPEG, PNG i WebP podczas wysyłania do ustalonego rozmiaru z wysoką jakością kompresji. Oszczędza miejsce na dysku i przyspiesza witrynę.',
        ),
        'translit-cyr-lat' => array(
            'ru' => 'Мгновенно превращает кириллицу и европейскую диакритику (чешскую, словацкую, немецкую, польскую) в чистые латинские URL и имена файлов. Без внешних запросов.',
            'cs' => 'Okamžitě převádí azbuku i evropskou diakritiku (českou, slovenskou, německou, polskou) do čistých latinských URL a názvů souborů. Bez externích dotazů.',
            'de' => 'Wandelt Kyrillisch und europäische Diakritika (Tschechisch, Slowakisch, Deutsch, Polnisch) sofort in saubere lateinische URLs und Dateinamen um. Ohne externe Anfragen.',
            'it' => 'Converte istantaneamente cirillico e segni diacritici europei (ceco, slovacco, tedesco, polacco) in URL e nomi file latini puliti. Senza richieste esterne.',
            'es' => 'Convierte al instante el cirílico y los diacríticos europeos (checo, eslovaco, alemán, polaco) en URL y nombres de archivo latinos limpios. Sin peticiones externas.',
            'fr' => 'Convertit instantanément le cyrillique et les diacritiques européens (tchèque, slovaque, allemand, polonais) en URL et noms de fichiers latins propres. Sans requête externe.',
            'pl' => 'Błyskawicznie zamienia cyrylicę i europejskie znaki diakrytyczne (czeskie, słowackie, niemieckie, polskie) na czyste łacińskie adresy URL i nazwy plików. Bez zapytań zewnętrznych.',
        ),
        'wp-allow-html-cats' => array(
            'ru' => 'Разрешает безопасное HTML-форматирование (абзацы, ссылки, картинки, заголовки, списки) в описаниях рубрик, меток и таксономий WooCommerce.',
            'cs' => 'Povoluje bezpečné formátování HTML (odstavce, odkazy, obrázky, nadpisy, seznamy) v popisech rubrik, štítků a taxonomií WooCommerce.',
            'de' => 'Erlaubt sicheres HTML (Absätze, Links, Bilder, Überschriften, Listen) in Beschreibungen von Kategorien, Schlagwörtern und WooCommerce-Taxonomien.',
            'it' => 'Consente HTML sicuro (paragrafi, link, immagini, titoli, elenchi) nelle descrizioni di categorie, tag e tassonomie WooCommerce.',
            'es' => 'Permite HTML seguro (párrafos, enlaces, imágenes, encabezados, listas) en las descripciones de categorías, etiquetas y taxonomías de WooCommerce.',
            'fr' => 'Autorise le HTML sécurisé (paragraphes, liens, images, titres, listes) dans les descriptions des catégories, étiquettes et taxonomies WooCommerce.',
            'pl' => 'Zezwala na bezpieczny HTML (akapity, odnośniki, obrazy, nagłówki, listy) w opisach kategorii, tagów i taksonomii WooCommerce.',
        ),
        'wp-auto-sku' => array(
            'ru' => 'Присваивает новым товарам WooCommerce уникальные случайные артикулы, если поле пустое, полностью сохраняя ручные правки, и включает поиск товаров по артикулу.',
            'cs' => 'Přiřazuje novým produktům WooCommerce jedinečné náhodné kódy, pokud je pole prázdné, plně zachovává ruční úpravy a zapíná vyhledávání zboží podle kódu.',
            'de' => 'Vergibt neuen WooCommerce-Produkten eindeutige Zufalls-SKUs, wenn das Feld leer ist, behält manuelle Eingaben vollständig bei und aktiviert die Suche nach SKU.',
            'it' => 'Assegna ai nuovi prodotti WooCommerce SKU casuali univoci quando il campo è vuoto, preserva del tutto le modifiche manuali e attiva la ricerca per SKU.',
            'es' => 'Asigna SKU aleatorios únicos a los productos nuevos de WooCommerce cuando el campo está vacío, conserva íntegramente las ediciones manuales y activa la búsqueda por SKU.',
            'fr' => 'Attribue des UGS aléatoires uniques aux nouveaux produits WooCommerce lorsque le champ est vide, préserve entièrement les saisies manuelles et active la recherche par UGS.',
            'pl' => 'Nadaje nowym produktom WooCommerce unikalne losowe kody SKU, gdy pole jest puste, w pełni zachowuje ręczne zmiany i włącza wyszukiwanie po SKU.',
        ),
        'wp-online-counter' => array(
            'ru' => 'Счётчик посетителей онлайн в панели администратора: гости, администраторы, редакторы и менеджеры магазина в реальном времени, плюс колонка «Онлайн» в списке пользователей.',
            'cs' => 'Počítadlo návštěvníků online v liště administrace: hosté, správci, editoři a manažeři obchodu v reálném čase, plus sloupec „Online“ v seznamu uživatelů.',
            'de' => 'Zähler für Besucher online in der Adminleiste: Gäste, Administratoren, Redakteure und Shop-Manager in Echtzeit, dazu eine Spalte „Online“ in der Benutzerliste.',
            'it' => 'Contatore dei visitatori online nella barra di amministrazione: ospiti, amministratori, editori e manager del negozio in tempo reale, più la colonna "Online" nell\'elenco utenti.',
            'es' => 'Contador de visitantes en línea en la barra de administración: invitados, administradores, editores y gestores de tienda en tiempo real, más una columna «Online» en la lista de usuarios.',
            'fr' => 'Compteur de visiteurs en ligne dans la barre d\'administration : invités, administrateurs, éditeurs et gestionnaires de boutique en temps réel, ainsi qu\'une colonne « En ligne » dans la liste des utilisateurs.',
            'pl' => 'Licznik odwiedzających online na pasku administratora: goście, administratorzy, redaktorzy i menedżerowie sklepu w czasie rzeczywistym oraz kolumna „Online” na liście użytkowników.',
        ),
        'wp-seo-micro' => array(
            'ru' => 'Лёгкий SEO-модуль: title, meta description и keywords, теги Open Graph, канонические ссылки, управление индексацией и XML-карта сайта. Совместим с данными SEOPress.',
            'cs' => 'Lehký SEO modul: title, meta description a keywords, značky Open Graph, kanonické odkazy, řízení indexace a XML mapa webu. Kompatibilní s daty SEOPress.',
            'de' => 'Schlankes SEO-Modul: Title, Meta-Description und Keywords, Open-Graph-Tags, Canonical-URLs, Indexierungssteuerung und XML-Sitemap. Kompatibel mit SEOPress-Daten.',
            'it' => 'Modulo SEO leggero: title, meta description e keywords, tag Open Graph, URL canonici, controllo dell\'indicizzazione e sitemap XML. Compatibile con i dati di SEOPress.',
            'es' => 'Módulo SEO ligero: title, meta description y keywords, etiquetas Open Graph, URL canónicas, control de indexación y sitemap XML. Compatible con los datos de SEOPress.',
            'fr' => 'Module SEO léger : title, meta description et mots-clés, balises Open Graph, URL canoniques, contrôle de l\'indexation et sitemap XML. Compatible avec les données SEOPress.',
            'pl' => 'Lekki moduł SEO: title, meta description i keywords, znaczniki Open Graph, adresy kanoniczne, kontrola indeksowania i mapa XML. Zgodny z danymi SEOPress.',
        ),
        'wp-simple-post-order' => array(
            'ru' => 'Сортировка записей, страниц, товаров WooCommerce и рубрик перетаскиванием мышью, плюс настраиваемая сортировка списков в админке (поле и направление) отдельно для каждого типа. Товары не трогаются, пока это не включено вручную.',
            'cs' => 'Řazení příspěvků, stránek, produktů WooCommerce a rubrik přetažením myší a nastavitelné řazení seznamů v administraci (sloupec i směr) zvlášť pro každý typ. Produkty zůstávají nedotčené, dokud to sami nezapnete.',
            'de' => 'Sortierung von Beiträgen, Seiten, WooCommerce-Produkten und Kategorien per Drag-and-drop, dazu eine einstellbare Standardsortierung der Admin-Listen (Feld und Richtung) je Inhaltstyp. Produkte bleiben unberührt, solange es nicht ausdrücklich aktiviert wird.',
            'it' => 'Ordinamento di articoli, pagine, prodotti WooCommerce e categorie tramite trascinamento, più un ordinamento predefinito configurabile degli elenchi in bacheca (campo e direzione) per ogni tipo. I prodotti restano intatti finché non lo attivi.',
            'es' => 'Ordenación de entradas, páginas, productos de WooCommerce y categorías arrastrando y soltando, más una ordenación predeterminada configurable de las listas del escritorio (campo y dirección) por cada tipo. Los productos no se tocan mientras no se active.',
            'fr' => 'Tri des articles, pages, produits WooCommerce et catégories par glisser-déposer, ainsi qu\'un tri par défaut configurable des listes d\'administration (champ et sens) pour chaque type. Les produits restent intacts tant que ce n\'est pas activé.',
            'pl' => 'Sortowanie wpisów, stron, produktów WooCommerce i kategorii przez przeciąganie myszą oraz konfigurowalne domyślne sortowanie list w panelu (pole i kierunek) dla każdego typu. Produkty pozostają nietknięte, dopóki tego nie włączysz.',
        ),
        'wp-test-email-micro' => array(
            'ru' => 'Диагностика почты по требованию: отправляет тестовое письмо через wp_mail() и показывает точную причину сбоя. Без фоновых процессов и записей в базе.',
            'cs' => 'Diagnostika pošty na vyžádání: odešle testovací e-mail přes wp_mail() a zobrazí přesnou příčinu selhání. Bez procesů na pozadí a zápisů do databáze.',
            'de' => 'Mail-Diagnose auf Abruf: versendet eine Testnachricht über wp_mail() und zeigt die genaue Fehlerursache. Ohne Hintergrundprozesse und Datenbankeinträge.',
            'it' => 'Diagnostica e-mail su richiesta: invia un messaggio di prova tramite wp_mail() e mostra la causa esatta dell\'errore. Senza processi in background né scritture nel database.',
            'es' => 'Diagnóstico de correo a demanda: envía un mensaje de prueba mediante wp_mail() y muestra la causa exacta del fallo. Sin procesos en segundo plano ni escrituras en la base de datos.',
            'fr' => 'Diagnostic e-mail à la demande : envoie un message de test via wp_mail() et affiche la cause exacte de l\'échec. Sans processus d\'arrière-plan ni écriture en base.',
            'pl' => 'Diagnostyka poczty na żądanie: wysyła wiadomość testową przez wp_mail() i pokazuje dokładną przyczynę błędu. Bez procesów w tle i zapisów w bazie.',
        ),
    );
}

/**
 * Current admin language as a two-letter code.
 *
 * @return string
 */
function vladimir_ai_i18n_lang() {
    $locale = function_exists( 'get_user_locale' ) ? get_user_locale() : get_locale();

    return strtolower( substr( (string) $locale, 0, 2 ) );
}

/**
 * Translate the description of every suite plugin on the Plugins screen.
 *
 * English stays as written in each plugin header, so it needs no table entry.
 *
 * @param array $plugins Plugin data keyed by "folder/file.php".
 * @return array
 */
function vladimir_ai_i18n_all_plugins( $plugins ) {
    $lang = vladimir_ai_i18n_lang();
    if ( 'en' === $lang || '' === $lang ) {
        return $plugins;
    }

    $table = vladimir_ai_i18n_table();

    foreach ( $plugins as $key => $data ) {
        $slug = dirname( $key );

        if ( isset( $table[ $slug ][ $lang ] ) ) {
            $plugins[ $key ]['Description'] = $table[ $slug ][ $lang ];
        }
    }

    return $plugins;
}
add_filter( 'all_plugins', 'vladimir_ai_i18n_all_plugins' );
