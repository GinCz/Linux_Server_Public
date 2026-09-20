#!/usr/bin/env bash
# ==========================================================================================
#  wp_deploy_vladimir_plugins.sh — roll the VladiMIR+AI suite out to every site
# ==========================================================================================
# Target      : FastPanel web nodes 222 (xxx.xxx.xxx.222) and 109 (xxx.xxx.xxx.109), run as root
# Usage       : bash wp_deploy_vladimir_plugins.sh              # DRY RUN, changes nothing
#               bash wp_deploy_vladimir_plugins.sh --apply      # install suite + drop merged plugin
#               bash wp_deploy_vladimir_plugins.sh --apply --remove-legacy   # + delete replaced plugins
#               bash wp_deploy_vladimir_plugins.sh --apply --remove-legacy --remove-seo  # deletes SEO plugins instead of deactivating
#               add --backup-db to dump each database before touching it
#
# What it does per site:
#   1. deletes wc-admin-default-sort-date (merged into wp-simple-post-order) and its DB rows
#   2. installs/refreshes every suite plugin from the GitHub release and activates it
#      - wp-auto-sku only where WooCommerce is present
#   3. deactivates the old SEO plugin (SEOPress, Yoast, Rank Math, AIOSEO) - files and
#      database rows stay, so it is one click to bring it back
#   4. optionally deletes the other third-party plugins our modules replace
#
# Nothing is removed without a flag except the merged plugin itself. Read the DRY RUN first.
# ==========================================================================================

set -uo pipefail

REL_TAG="wp-2026-09__1.22"
BASE_URL="https://github.com/GinCz/Linux_Server_Public/releases/download/${REL_TAG}"

WP=/usr/local/bin/wp
LOG="/var/log/wp_deploy_vladimir_plugins.log"
BACKUP_DIR="/root/wp-deploy-backup/$(date +%Y%m%d-%H%M%S)"

# Suite plugins for every site
SUITE="404-410-301 classic-editor-tinymce clean-head-meta disable-update-emails image-resizer translit-cyr-lat wp-allow-html-cats wp-online-counter wp-seo-micro wp-simple-post-order wp-test-email-micro"
# WooCommerce-only plugin (SKU generator)
SUITE_WOO="wp-auto-sku"
# Merged into wp-simple-post-order in 2026-09__1.22 - always removed
MERGED="wc-admin-default-sort-date"

# Third-party plugins our modules replace. Unambiguous duplicates only.
LEGACY_SAFE="classic-editor tinymce-advanced advanced-editor-tools disable-gutenberg \
imsanity resize-image-after-upload image-sizes \
cyr2lat rus-to-lat rus-to-lat-advanced \
simple-custom-post-order post-types-order intuitive-custom-post-order \
404-to-301 all-404-redirect-to-homepage redirect-404-error-page-to-homepage \
wp-online-active-users manage-notification-emails check-email"

# SEO plugins are DEACTIVATED, not deleted: wp-seo-micro reads their meta fields, but it
# does not carry over redirects, schema, social images or extended sitemaps. Deactivating
# hands the job to our module while every row stays in the database, so one click in
# wp-admin puts the old plugin back if something turns out to be missing.
LEGACY_SEO="wordpress-seo wp-seopress wp-seopress-pro seo-by-rank-math all-in-one-seo-pack"

APPLY=0
REMOVE_LEGACY=0
REMOVE_SEO=0
BACKUP_DB=0

for arg in "$@"; do
    case "$arg" in
        --apply)         APPLY=1 ;;
        --remove-legacy) REMOVE_LEGACY=1 ;;
        --remove-seo)    REMOVE_SEO=1 ;;
        --backup-db)     BACKUP_DB=1 ;;
        *) echo "Unknown option: $arg"; exit 2 ;;
    esac
done

C='\033[1;36m'; G='\033[0;92m'; Y='\033[0;93m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
HR="${C}==========================================================================${X}"

SITES=0; WOO_SITES=0; INSTALLED=0; REMOVED=0; DEACTIVATED=0; SKIPPED=0
FAILED=()

say() { echo -e "$1" | tee -a "$LOG"; }

# Run wp-cli as the site owner, never longer than 120s
wpx() {
    local user="$1"; local path="$2"; shift 2
    timeout 120 sudo -u "$user" "$WP" --path="$path" --no-color --skip-plugins=hello --quiet "$@" 2>&1
}

[ -x "$WP" ] || { echo "wp-cli not found at $WP"; exit 1; }
mkdir -p "$(dirname "$LOG")" "$BACKUP_DIR"

say "$HR"
if [ "$APPLY" -eq 1 ]; then
    say "${W}  VladiMIR+AI suite rollout — APPLY MODE (changes will be written)${X}"
else
    say "${W}  VladiMIR+AI suite rollout — DRY RUN (nothing will be changed)${X}"
fi
say "  release        : ${REL_TAG}"
say "  remove legacy  : $([ "$REMOVE_LEGACY" -eq 1 ] && echo yes || echo 'no (use --remove-legacy)')"
say "  remove SEO     : $([ "$REMOVE_SEO" -eq 1 ] && echo yes || echo 'no (use --remove-seo)')"
say "  database dumps : $([ "$BACKUP_DB" -eq 1 ] && echo "$BACKUP_DIR" || echo 'no (use --backup-db)')"
say "  log            : $LOG"
say "$HR"

for USER_DIR in /var/www/*/; do
    SITE_USER=$(basename "$USER_DIR")
    [[ "$SITE_USER" == "fastuser" || "$SITE_USER" == "lost+found" ]] && continue
    id "$SITE_USER" &>/dev/null || continue

    for DOMAIN_DIR in "${USER_DIR}data/www/"*/; do
        [ -d "$DOMAIN_DIR" ] || continue
        DOMAIN=$(basename "$DOMAIN_DIR")
        [ -f "${DOMAIN_DIR}wp-config.php" ] || continue

        SITES=$((SITES+1))
        say ""
        say "$HR"
        say "${Y}  ▶  ${W}${SITE_USER}${X}  ${G}→  ${Y}${DOMAIN}${X}"
        say "$HR"

        # Database reachable? A site that cannot answer must not be half-processed.
        if ! wpx "$SITE_USER" "$DOMAIN_DIR" option get siteurl >/dev/null 2>&1; then
            say "  ${R}✖  wp-cli cannot reach this site (DB down or broken config) — skipped${X}"
            FAILED+=("${DOMAIN} :: unreachable")
            SKIPPED=$((SKIPPED+1))
            continue
        fi

        # Inventory before any change - this is the record of what was there.
        PLUGIN_LIST=$(wpx "$SITE_USER" "$DOMAIN_DIR" plugin list --field=name)
        echo "$PLUGIN_LIST" > "${BACKUP_DIR}/${DOMAIN}.plugins.txt"

        HAS_WOO=0
        echo "$PLUGIN_LIST" | grep -qx "woocommerce" && HAS_WOO=1
        [ "$HAS_WOO" -eq 1 ] && WOO_SITES=$((WOO_SITES+1))
        say "  shop           : $([ "$HAS_WOO" -eq 1 ] && echo 'WooCommerce present' || echo 'no WooCommerce')"

        if [ "$BACKUP_DB" -eq 1 ] && [ "$APPLY" -eq 1 ]; then
            if wpx "$SITE_USER" "$DOMAIN_DIR" db export "${BACKUP_DIR}/${DOMAIN}.sql" >/dev/null 2>&1; then
                say "  ${G}✔  database dumped to ${BACKUP_DIR}/${DOMAIN}.sql${X}"
            else
                say "  ${Y}⚠  database dump failed — continuing${X}"
            fi
        fi

        # ---------------------------------------------------------------- 1. merged plugin
        if echo "$PLUGIN_LIST" | grep -qx "$MERGED"; then
            if [ "$APPLY" -eq 1 ]; then
                wpx "$SITE_USER" "$DOMAIN_DIR" plugin deactivate "$MERGED" >/dev/null 2>&1
                if wpx "$SITE_USER" "$DOMAIN_DIR" plugin delete "$MERGED" >/dev/null 2>&1; then
                    say "  ${G}✔  removed       : ${MERGED} (merged into wp-simple-post-order)${X}"
                    REMOVED=$((REMOVED+1))
                else
                    say "  ${R}✖  failed to remove ${MERGED}${X}"
                    FAILED+=("${DOMAIN} :: delete ${MERGED}")
                fi
                # That plugin stored nothing of its own, but leftovers from earlier builds
                # are cleaned anyway so no orphan rows are left behind.
                for OPT in wc_admin_default_sort_date _wc_admin_default_sort_date _vladimir_wc_sort_settings; do
                    wpx "$SITE_USER" "$DOMAIN_DIR" option delete "$OPT" >/dev/null 2>&1
                done
            else
                say "  ${Y}would remove   : ${MERGED} (+ its option rows)${X}"
            fi
        fi

        # ---------------------------------------------------------------- 2. suite install
        LIST="$SUITE"
        [ "$HAS_WOO" -eq 1 ] && LIST="$SUITE $SUITE_WOO"

        for SLUG in $LIST; do
            if [ "$APPLY" -eq 1 ]; then
                OUT=$(wpx "$SITE_USER" "$DOMAIN_DIR" plugin install "${BASE_URL}/${SLUG}.zip" --force --activate)
                if [ $? -eq 0 ]; then
                    say "  ${G}✔  installed     : ${SLUG}${X}"
                    INSTALLED=$((INSTALLED+1))
                else
                    say "  ${R}✖  install failed: ${SLUG} — $(echo "$OUT" | tail -1)${X}"
                    FAILED+=("${DOMAIN} :: install ${SLUG}")
                fi
            else
                say "  ${Y}would install  : ${SLUG}${X}"
            fi
        done

        [ "$HAS_WOO" -eq 0 ] && say "  ${C}ℹ  skipped       : ${SUITE_WOO} (no WooCommerce on this site)${X}"

        # ---------------------------------------------------------------- 3. replaced plugins
        DROP=""
        [ "$REMOVE_LEGACY" -eq 1 ] && DROP="$LEGACY_SAFE"
        # SEO plugins are deleted only if explicitly asked for; otherwise deactivated below.
        [ "$REMOVE_SEO" -eq 1 ] && DROP="$DROP $LEGACY_SEO"

        FOUND_LEGACY=""
        for SLUG in $LEGACY_SAFE $LEGACY_SEO; do
            echo "$PLUGIN_LIST" | grep -qx "$SLUG" && FOUND_LEGACY="$FOUND_LEGACY $SLUG"
        done

        if [ -n "$FOUND_LEGACY" ]; then
            say "  ${C}ℹ  replaced here :${FOUND_LEGACY}${X}"
        fi

        # ---------------------------------------------------- 3a. SEO plugins: deactivate
        if [ "$REMOVE_SEO" -eq 0 ]; then
            for SLUG in $LEGACY_SEO; do
                echo "$PLUGIN_LIST" | grep -qx "$SLUG" || continue

                # Already inactive? Then there is nothing to do and nothing to report.
                # stderr is dropped and only the last line is kept: wpx() merges stderr into
                # stdout, so a single PHP notice from the site used to turn the status into
                # "PHP Warning: ...\nactive" and the plugin was silently left running.
                STATUS=$(timeout 60 sudo -u "$SITE_USER" "$WP" --path="$DOMAIN_DIR" --no-color \
                    plugin get "$SLUG" --field=status 2>/dev/null | tail -1 | tr -d '\r')
                [ "$STATUS" = "active" ] || continue

                if [ "$APPLY" -eq 1 ]; then
                    if wpx "$SITE_USER" "$DOMAIN_DIR" plugin deactivate "$SLUG" >/dev/null 2>&1; then
                        say "  ${G}✔  deactivated   : ${SLUG} (files and database rows kept)${X}"
                        DEACTIVATED=$((DEACTIVATED+1))
                    else
                        say "  ${R}✖  failed to deactivate ${SLUG}${X}"
                        FAILED+=("${DOMAIN} :: deactivate ${SLUG}")
                    fi
                else
                    say "  ${Y}would deactivate: ${SLUG} (kept installed, one click to restore)${X}"
                fi
            done
        fi

        for SLUG in $DROP; do
            echo "$PLUGIN_LIST" | grep -qx "$SLUG" || continue
            if [ "$APPLY" -eq 1 ]; then
                wpx "$SITE_USER" "$DOMAIN_DIR" plugin deactivate "$SLUG" >/dev/null 2>&1
                if wpx "$SITE_USER" "$DOMAIN_DIR" plugin delete "$SLUG" >/dev/null 2>&1; then
                    say "  ${G}✔  removed       : ${SLUG}${X}"
                    REMOVED=$((REMOVED+1))
                else
                    say "  ${R}✖  failed to remove ${SLUG}${X}"
                    FAILED+=("${DOMAIN} :: delete ${SLUG}")
                fi
            else
                say "  ${Y}would remove   : ${SLUG}${X}"
            fi
        done
    done
done

say ""
say "$HR"
say "${W}  SUMMARY${X}"
say "  sites processed : $SITES  (WooCommerce: $WOO_SITES)"
say "  plugins installed: $INSTALLED"
say "  plugins removed  : $REMOVED"
say "  SEO deactivated  : $DEACTIVATED"
say "  sites skipped    : $SKIPPED"
if [ ${#FAILED[@]} -gt 0 ]; then
    say "${R}  failures:${X}"
    for f in "${FAILED[@]}"; do say "    - $f"; done
else
    say "${G}  no failures${X}"
fi
say "  inventory + dumps: $BACKUP_DIR"
[ "$APPLY" -eq 0 ] && say "${Y}  DRY RUN — nothing was changed. Re-run with --apply.${X}"
say "$HR"
