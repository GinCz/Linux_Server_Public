<?php
/**
 * Single Listing Template (Classified Ad & Company Profile)
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

get_header();

$post_id   = get_the_ID();
$vb_type   = get_post_meta( $post_id, '_vb_type', true ) ?: 'classified';
$price     = get_post_meta( $post_id, '_vb_price', true );
$phone     = get_post_meta( $post_id, '_vb_phone', true ) ?: get_post_meta( $post_id, '_phone', true );
$email     = get_post_meta( $post_id, '_vb_email', true ) ?: get_post_meta( $post_id, '_email', true );
$addr      = get_post_meta( $post_id, '_vb_address', true ) ?: get_post_meta( $post_id, '_address', true );
$wa        = get_post_meta( $post_id, '_vb_whatsapp', true );
$tg        = get_post_meta( $post_id, '_vb_telegram', true );
$web       = get_post_meta( $post_id, '_vb_website', true ) ?: get_post_meta( $post_id, '_website', true );

// Images
$raw_images = get_post_meta( $post_id, '_vb_images', true );
$images = [];
if ( ! empty( $raw_images ) && is_array( $raw_images ) ) {
    foreach ( $raw_images as $img_id ) {
        $url = wp_get_attachment_image_url( $img_id, 'large' );
        if ( $url ) {
            $images[] = [ 'id' => $img_id, 'url' => $url ];
        }
    }
}
if ( empty( $images ) ) {
    $thumb_id = get_post_thumbnail_id( $post_id );
    if ( $thumb_id ) {
        $images[] = [ 'id' => $thumb_id, 'url' => wp_get_attachment_image_url( $thumb_id, 'large' ) ];
    }
}

// Categories & Location
$cats = wp_get_post_terms( $post_id, 'vb_category' );
$primary_cat = ! empty( $cats ) && ! is_wp_error( $cats ) ? $cats[0] : null;

$locs = wp_get_post_terms( $post_id, 'vb_location' );
$primary_loc = ! empty( $locs ) && ! is_wp_error( $locs ) ? $locs[0] : null;

// Rating stats
$stats = VB_Ratings::get_vote_stats( $vb_type === 'company' ? 'company' : 'listing', $post_id );

// Author info
$author_id = get_post_field( 'post_author', $post_id );
$author_name = get_the_author_meta( 'display_name', $author_id ) ?: 'Пользователь';

// Clean phone for tel:
$clean_phone = preg_replace( '/[^\+0-9]/', '', (string) $phone );
?>

<div id="content" class="content-area page-wrapper" role="main">
    <div class="row row-main">
        <div class="large-12 col">
            <div class="col-inner">

                <!-- Breadcrumbs -->
                <nav class="vb-single-breadcrumbs">
                    <a href="<?php echo esc_url( home_url( '/' ) ); ?>">Главная</a>
                    <span class="vb-bc-sep">&rsaquo;</span>
                    <?php if ( $vb_type === 'company' ) : ?>
                        <a href="<?php echo esc_url( home_url( '/company/' ) ); ?>">Каталог компаний</a>
                    <?php else : ?>
                        <a href="<?php echo esc_url( home_url( '/ads/' ) ); ?>">Все объявления</a>
                    <?php endif; ?>
                    <?php if ( $primary_cat ) : ?>
                        <span class="vb-bc-sep">&rsaquo;</span>
                        <a href="<?php echo esc_url( get_term_link( $primary_cat ) ); ?>"><?php echo esc_html( trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $primary_cat->name ) ) ); ?></a>
                    <?php endif; ?>
                    <span class="vb-bc-sep">&rsaquo;</span>
                    <span class="vb-bc-current"><?php the_title(); ?></span>
                </nav>

                <div class="vb-single-layout">
                    <!-- Left / Main Column -->
                    <div class="vb-single-main">
                        <h2 class="vb-single-title"><?php the_title(); ?></h2>

                        <div class="vb-single-meta-bar">
                            <span class="vb-meta-item">📅 <?php echo esc_html( get_the_date( 'd.m.Y' ) ); ?></span>
                            <?php if ( $primary_loc ) : ?>
                                <span class="vb-meta-item">📍 <?php echo esc_html( $primary_loc->name ); ?></span>
                            <?php elseif ( $addr ) : ?>
                                <span class="vb-meta-item">📍 <?php echo esc_html( $addr ); ?></span>
                            <?php endif; ?>
                            <span class="vb-meta-item">👁️ <?php echo (int) get_post_meta( $post_id, 'views', true ) ?: 1; ?> просм.</span>
                            <span class="vb-meta-item vb-meta-id">ID: #<?php echo esc_html( $post_id ); ?></span>
                        </div>

                        <!-- Gallery / Image Box -->
                        <?php if ( ! empty( $images ) ) : ?>
                            <div class="vb-single-gallery">
                                <div class="vb-main-photo-wrap">
                                    <img id="vb-gallery-main" src="<?php echo esc_url( $images[0]['url'] ); ?>" alt="<?php the_title_attribute(); ?>" class="vb-main-photo">
                                </div>
                                <?php if ( count( $images ) > 1 ) : ?>
                                    <div class="vb-thumbs-strip">
                                        <?php foreach ( $images as $idx => $img ) : ?>
                                            <div class="vb-thumb-box <?php echo $idx === 0 ? 'active' : ''; ?>" onclick="document.getElementById('vb-gallery-main').src='<?php echo esc_url( $img['url'] ); ?>'; document.querySelectorAll('.vb-thumb-box').forEach(function(b){b.classList.remove('active');}); this.classList.add('active');">
                                                <img src="<?php echo esc_url( $img['url'] ); ?>" alt="">
                                            </div>
                                        <?php endforeach; ?>
                                    </div>
                                <?php endif; ?>
                            </div>
                        <?php endif; ?>

                        <!-- Full Description -->
                        <div class="vb-single-desc-card">
                            <h3 class="vb-section-heading">Описание</h3>
                            <div class="vb-desc-content">
                                <?php the_content(); ?>
                            </div>
                        </div>

                        <!-- Safety & Anti-Fraud Notice -->
                        <div class="vb-safety-box">
                            <div class="vb-safety-icon">🛡️</div>
                            <div class="vb-safety-text">
                                <strong>Безопасные сделки в Чехии:</strong> Никогда не отправляйте предоплату незнакомым лицам. Встречайтесь лично в публичных местах. Проверяйте товар перед оплатой.
                            </div>
                        </div>

                        <!-- Rating & Anti-Fraud Dual Vote -->
                        <div class="vb-single-rating-box">
                            <span class="vb-rating-label">Оценка публикации (защита от спама и мошенников):</span>
                            <div class="vb-rating-dual">
                                <button type="button" class="vb-btn-vote vb-vote-up" data-target="<?php echo $vb_type === 'company' ? 'company' : 'listing'; ?>" data-id="<?php echo esc_attr( $post_id ); ?>" data-vote="1">
                                    👍 Рекомендую (<span id="vb-likes-<?php echo esc_attr( $post_id ); ?>"><?php echo (int) $stats['likes']; ?></span>)
                                </button>
                                <button type="button" class="vb-btn-vote vb-vote-down" data-target="<?php echo $vb_type === 'company' ? 'company' : 'listing'; ?>" data-id="<?php echo esc_attr( $post_id ); ?>" data-vote="-1">
                                    👎 Сомнительно / Спам (<span id="vb-dislikes-<?php echo esc_attr( $post_id ); ?>"><?php echo (int) $stats['dislikes']; ?></span>)
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Right Column: Sidebar / Contact Card -->
                    <div class="vb-single-sidebar">
                        <div class="vb-contact-card">
                            <!-- Price Block -->
                            <div class="vb-single-price-box">
                                <?php if ( $price > 0 ) : 
                                    $curr_info   = VB_CPT::get_currency_info();
                                    $curr_symbol = $curr_info['symbol'];
                                    $curr_code   = $curr_info['currency'];
                                ?>
                                    <div class="vb-single-price"><?php echo number_format( (float) $price, 0, '.', ' ' ); ?> <?php echo esc_html( $curr_symbol ); ?></div>
                                    <?php if ( 'CZK' === $curr_code ) : ?>
                                        <div class="vb-price-eur">~ <?php echo number_format( (float) $price / 25, 0, '.', ' ' ); ?> €</div>
                                    <?php endif; ?>
                                <?php else : ?>
                                    <div class="vb-single-price vb-price-free">Договорная / Бесплатно</div>
                                <?php endif; ?>
                            </div>

                            <!-- Seller Info -->
                            <div class="vb-seller-block">
                                <div class="vb-seller-avatar">
                                    <?php echo get_avatar( $author_id, 56 ); ?>
                                </div>
                                <div class="vb-seller-meta">
                                    <div class="vb-seller-name"><?php echo esc_html( $author_name ); ?></div>
                                    <div class="vb-seller-sub">Автор публикации</div>
                                </div>
                            </div>

                            <!-- Action Buttons -->
                            <div class="vb-contact-actions">
                                <?php if ( $clean_phone ) : ?>
                                    <a href="tel:<?php echo esc_attr( $clean_phone ); ?>" class="vb-btn-contact vb-btn-phone">
                                        📞 Позвонить: <?php echo esc_html( $phone ); ?>
                                    </a>
                                <?php endif; ?>

                                <?php if ( $wa || $clean_phone ) : 
                                    $wa_num = preg_replace( '/[^\+0-9]/', '', $wa ?: $clean_phone );
                                ?>
                                    <a href="https://wa.me/<?php echo esc_attr( ltrim( $wa_num, '+' ) ); ?>" target="_blank" rel="noopener" class="vb-btn-contact vb-btn-whatsapp">
                                        💬 Написать в WhatsApp
                                    </a>
                                <?php endif; ?>

                                <?php if ( $tg ) : 
                                    $tg_user = ltrim( trim( $tg ), '@' );
                                ?>
                                    <a href="https://t.me/<?php echo esc_attr( $tg_user ); ?>" target="_blank" rel="noopener" class="vb-btn-contact vb-btn-telegram">
                                        ✈️ Написать в Telegram
                                    </a>
                                <?php endif; ?>

                                <?php if ( $web ) : ?>
                                    <a href="<?php echo esc_url( $web ); ?>" target="_blank" rel="noopener nofollow" class="vb-btn-contact vb-btn-website">
                                        🌐 Перейти на сайт компании
                                    </a>
                                <?php endif; ?>
                            </div>

                            <?php if ( $addr || $primary_loc ) : ?>
                                <div class="vb-sidebar-info-row">
                                    <strong>Локация:</strong>
                                    <span>📍 <?php echo esc_html( $addr ?: $primary_loc->name ); ?></span>
                                </div>
                            <?php endif; ?>

                            <div class="vb-sidebar-info-row">
                                <strong>Категория:</strong>
                                <span><?php echo esc_html( $primary_cat ? trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $primary_cat->name ) ) : 'Общие' ); ?></span>
                            </div>

                            <div class="vb-sidebar-post-ad-banner">
                                <p>Есть что продать или предложить в Чехии?</p>
                                <a href="<?php echo esc_url( home_url( '/new/' ) ); ?>" class="vb-btn-sidebar-new">+ Подать объявление бесплатно</a>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Similar Listings from the same category -->
                <?php if ( $primary_cat ) : 
                    $similar = new WP_Query( [
                        'post_type'      => 'vb_listing',
                        'post_status'    => 'publish',
                        'posts_per_page' => 3,
                        'post__not_in'   => [ $post_id ],
                        'tax_query'      => [
                            [
                                'taxonomy' => 'vb_category',
                                'field'    => 'term_id',
                                'terms'    => $primary_cat->term_id,
                            ],
                        ],
                    ] );
                    if ( $similar->have_posts() ) :
                ?>
                    <div class="vb-similar-section">
                        <h3 class="vb-similar-heading">Похожие объявления в рубрике «<?php echo esc_html( trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $primary_cat->name ) ) ); ?>»</h3>
                        <div class="vb-listings-grid">
                            <?php while ( $similar->have_posts() ) : $similar->the_post(); 
                                $sim_id = get_the_ID();
                                $sim_price = get_post_meta( $sim_id, '_vb_price', true );
                                $sim_thumb = get_the_post_thumbnail_url( $sim_id, 'medium' ) ?: ( defined( 'VB_BOARD_URL' ) ? ( VB_BOARD_URL . 'assets/no-photo.svg' ) : '/wp-content/plugins/wp-board-directory/assets/no-photo.svg' );
                                $sim_stats = VB_Ratings::get_vote_stats( 'listing', $sim_id );
                            ?>
                                <div class="vb-card" data-id="<?php echo esc_attr( $sim_id ); ?>">
                                    <div class="vb-card-img-wrap">
                                        <a href="<?php the_permalink(); ?>">
                                            <img src="<?php echo esc_url( $sim_thumb ); ?>" alt="<?php the_title_attribute(); ?>" loading="lazy" class="vb-card-img">
                                        </a>
                                    </div>
                                    <div class="vb-card-body">
                                        <h4 class="vb-card-title">
                                            <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                                        </h4>
                                        <div class="vb-card-price">
                                            <?php if ( $sim_price > 0 ) : ?>
                                                <strong><?php echo number_format( (float) $sim_price, 0, '.', ' ' ); ?> <?php echo esc_html( VB_CPT::get_currency_symbol() ); ?></strong>
                                            <?php else : ?>
                                                <strong class="vb-price-free">Договорная</strong>
                                            <?php endif; ?>
                                        </div>
                                    </div>
                                </div>
                            <?php endwhile; wp_reset_postdata(); ?>
                        </div>
                    </div>
                <?php endif; endif; ?>

            </div>
        </div>
    </div>
</div>

<?php
get_footer();
