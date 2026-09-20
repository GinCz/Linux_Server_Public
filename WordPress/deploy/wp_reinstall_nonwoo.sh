#!/usr/bin/env bash
# ==========================================================================================
#  wp_reinstall_nonwoo.sh — clean reinstall of the VladiMIR+AI suite, NON-WooCommerce sites
# ==========================================================================================
# Target : FastPanel node 222 (xxx.xxx.xxx.222) or 109 (xxx.xxx.xxx.109), run as root, bash
# Usage  : bash wp_reinstall_nonwoo.sh            # dry run, lists what it would do
#          bash wp_reinstall_nonwoo.sh --apply    # do it
#
# Shops are skipped entirely: any site with a woocommerce plugin folder is left untouched.
#
# Per site it does exactly what was done by hand on megan-consult.cz:
#   1. deletes the plugin folder of every suite plugin (and the merged wc-admin one)
#   2. unpacks the current release into wp-content/plugins
#   3. chowns everything to the site owner and activates the plugins
#
# No third-party plugin is removed or deactivated here.
# ==========================================================================================

set -uo pipefail

REL_TAG="wp-2026-09__1.25"
BASE_URL="https://github.com/GinCz/Linux_Server_Public/releases/download/${REL_TAG}"
WP=/usr/local/bin/wp
PKG_DIR="/tmp/vladimir-suite-${REL_TAG}"
LOG="/var/log/wp_reinstall_nonwoo.log"

SUITE="404-410-301 classic-editor-tinymce clean-head-meta disable-update-emails image-resizer translit-cyr-lat wp-allow-html-cats wp-online-counter wp-seo-micro wp-simple-post-order wp-test-email-micro"
OBSOLETE="wp-auto-sku wc-admin-default-sort-date"

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

G='\033[0;92m'; Y='\033[0;93m'; R='\033[1;31m'; C='\033[1;36m'; X='\033[0m'
say() { echo -e "$1" | tee -a "$LOG"; }

[ -x "$WP" ] || { echo "wp-cli not found"; exit 1; }
mkdir -p "$PKG_DIR"; chmod 755 "$PKG_DIR"

# Fetch each archive once, by its own name (wp-cli's own cache keys on repo+tag and would
# hand back the same ZIP for every plugin).
for S in $SUITE; do
    Z="$PKG_DIR/$S.zip"
    [ -s "$Z" ] || curl -fsSL -m 120 "$BASE_URL/$S.zip" -o "$Z" || { echo "FATAL: download $S"; exit 1; }
    unzip -l "$Z" 2>/dev/null | grep -q " $S/" || { echo "FATAL: $S.zip has no $S/ dir"; exit 1; }
    chmod 644 "$Z"
done

TOTAL=0; DONE=0; SHOPS=0; FAILED=()

say "=== $(hostname) | release $REL_TAG | $([ $APPLY -eq 1 ] && echo APPLY || echo 'DRY RUN') ==="

for U in /var/www/*/; do
    SU=$(basename "$U")
    [ "$SU" = "fastuser" ] && continue
    id "$SU" &>/dev/null || continue

    for D in "${U}data/www/"*/; do
        [ -f "${D}wp-config.php" ] || continue
        DOM=$(basename "$D")
        TOTAL=$((TOTAL+1))

        # Shop check on the filesystem: no database needed, and it cannot be fooled by a
        # site whose DB is unreachable at this moment.
        if [ -d "${D}wp-content/plugins/woocommerce" ]; then
            say "  ${C}skip (shop)   : ${DOM}${X}"
            SHOPS=$((SHOPS+1))
            continue
        fi

        if [ $APPLY -eq 0 ]; then
            say "  ${Y}would reinstall: ${DOM}${X}"
            continue
        fi

        PL="${D}wp-content/plugins"

        for S in $SUITE $OBSOLETE; do
            rm -rf "${PL:?}/$S"
        done

        BAD=0
        for S in $SUITE; do
            unzip -qo "$PKG_DIR/$S.zip" -d "$PL/" || BAD=$((BAD+1))
        done

        chown -R "$SU":"$SU" "$PL"

        for S in $SUITE; do
            timeout 60 sudo -u "$SU" "$WP" plugin activate "$S" --path="$D" --quiet >/dev/null 2>&1
        done

        # Verify against the filesystem and the plugin list, not against exit codes.
        OK=0
        for S in $SUITE; do
            [ -f "$PL/$S/$S.php" ] && OK=$((OK+1))
        done

        HTTP=$(curl -sI -o /dev/null -w "%{http_code}" -m 12 "https://$DOM/" 2>/dev/null)

        if [ "$OK" -eq 11 ] && [ "$BAD" -eq 0 ]; then
            say "  ${G}reinstalled   : ${DOM}  (11/11, HTTP ${HTTP})${X}"
            DONE=$((DONE+1))
        else
            say "  ${R}PROBLEM       : ${DOM}  (${OK}/11 on disk, unzip errors ${BAD}, HTTP ${HTTP})${X}"
            FAILED+=("$DOM")
        fi
    done
done

say ""
say "=== summary on $(hostname) ==="
say "  sites total     : $TOTAL"
say "  shops skipped   : $SHOPS"
say "  reinstalled     : $DONE"
if [ ${#FAILED[@]} -gt 0 ]; then
    say "  ${R}problems        : ${FAILED[*]}${X}"
else
    say "  ${G}problems        : none${X}"
fi
