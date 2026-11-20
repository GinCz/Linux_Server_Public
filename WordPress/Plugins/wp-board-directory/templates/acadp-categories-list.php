<?php
/**
 * ACADP Categories Enhanced Template (VladiMIR+AI)
 * Balanced 3 columns, clean horizontal dividers, small horizontal accent line above titles.
 *
 * @package WP_Board_Directory
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
?>
<div class="acadp acadp-categories acadp-text-list vb-categories-enhanced">
    <?php
    $tax = 'acadp_categories';

    // Grouping: Row 1, Row 2, Row 3
    $matrix = [
        0 => [ 'auto', 'entertainment', 'realty', 'avto', 'razvlecheniya', 'nedvizhimost' ],
        1 => [ 'business', 'home', 'other', 'rabota-i-biznes', 'dlya-doma', 'raznoe' ],
        2 => [ 'phones', 'household', 'electronics', 'sredstva-svyazi', 'hozyajstvo', 'elektronika' ],
    ];

    $pad_counts = isset( $attributes['pad_counts'] ) ? $attributes['pad_counts'] : true;
    $show_count = ! empty( $attributes['show_count'] );

    foreach ( $matrix as $row_idx => $cols ) :
        $row_class = 'acadp-cat-row row acadp-no-margin';
        if ( $row_idx > 0 ) {
            $row_class .= ' acadp-cat-row-divided';
        }
    ?>
        <div class="<?php echo esc_attr( $row_class ); ?>">
            <?php foreach ( $cols as $slug ) :
                $parent = get_term_by( 'slug', $slug, $tax );
                if ( ! $parent ) continue;

                $count = function_exists( 'acadp_get_listings_count_by_category' ) 
                    ? (int) acadp_get_listings_count_by_category( $parent->term_id, $pad_counts )
                    : (int) $parent->count;

                $cat_url = function_exists( 'acadp_get_category_page_link' )
                    ? acadp_get_category_page_link( $parent )
                    : get_term_link( $parent );

                $clean_name = trim( preg_replace( '/^[◉\s\-\•\·]+/u', '', $parent->name ) );

                $children = get_terms( [
                    'taxonomy'   => $tax,
                    'parent'     => $parent->term_id,
                    'hide_empty' => ! empty( $attributes['hide_empty'] ) ? 1 : 0,
                    'orderby'    => 'name',
                    'order'      => 'ASC',
                ] );
            ?>
                <div class="col-md-4 col-sm-6 col-xs-12 vb-cat-box">
                    <div class="vb-cat-header-wrap">
                        <div class="vb-cat-accent-line"></div>
                        <a href="<?php echo esc_url( $cat_url ); ?>" class="vb-cat-main-link" title="<?php echo esc_attr( sprintf( __( 'View all posts in %s', 'advanced-classifieds-and-directory-pro' ), $clean_name ) ); ?>">
                            <span class="vb-cat-bullet">◉</span>
                            <span class="vb-cat-title-text"><?php echo esc_html( $clean_name ); ?></span>
                            <?php if ( $show_count ) : ?>
                                <span class="vb-cat-count">(<?php echo esc_html( $count ); ?>)</span>
                            <?php endif; ?>
                        </a>
                    </div>

                    <?php if ( ! empty( $children ) && ! is_wp_error( $children ) ) : ?>
                        <ul class="list-unstyled vb-cat-sub-list">
                            <?php foreach ( $children as $child ) :
                                $ch_count = function_exists( 'acadp_get_listings_count_by_category' )
                                    ? (int) acadp_get_listings_count_by_category( $child->term_id, false )
                                    : (int) $child->count;

                                if ( ! empty( $attributes['hide_empty'] ) && 0 === $ch_count ) continue;

                                $ch_url = function_exists( 'acadp_get_category_page_link' )
                                    ? acadp_get_category_page_link( $child )
                                    : get_term_link( $child );
                            ?>
                                <li class="vb-subcat-li">
                                    <a href="<?php echo esc_url( $ch_url ); ?>" class="vb-subcat-link" title="<?php echo esc_attr( sprintf( __( 'View all posts in %s', 'advanced-classifieds-and-directory-pro' ), $child->name ) ); ?>">
                                        <span class="vb-subcat-name"><?php echo esc_html( $child->name ); ?></span>
                                        <?php if ( $show_count ) : ?>
                                            <span class="vb-subcat-cnt">(<?php echo esc_html( $ch_count ); ?>)</span>
                                        <?php endif; ?>
                                    </a>
                                </li>
                            <?php endforeach; ?>
                        </ul>
                    <?php endif; ?>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endforeach; ?>
</div>

<?php 
if ( function_exists( 'the_acadp_social_sharing_buttons' ) ) {
    the_acadp_social_sharing_buttons();
}
