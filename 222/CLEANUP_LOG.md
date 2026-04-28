# Cleanup Log — v2026-04-29

Versioned duplicates removed from 222/ on 2026-04-29.
All files are preserved in Git history.
To recover any file: `git log -- 222/<filename>` then `git show <sha>:222/<filename>`

## Batch 1 — removed
- apply_aliases_v2026-04-25.sh (base: apply_aliases.sh 1010B > 737B)
- backup_clean_v2026-04-25.sh (base: backup_clean.sh 10280B > 1363B)
- block_bots_v2026-04-25.sh (base: block_bots.sh 1620B > 876B)
- cloudflare_proxy_v2026-04-25.sh (base: cloudflare_proxy.sh)
- docker_backup_v2026-04-25.sh (base: docker_backup.sh 11252B > 971B)
- domains_v2026-04-25.sh (base: domains.sh 1619B > 756B)
- fix_crowdsec_hub_v2026-04-12.sh (base: fix_crowdsec_hub.sh 1945B > 2463B -> kept newer)
- fix_crowdsec_hub_v2026-04-25.sh (base: fix_crowdsec_hub.sh)
- fix_nginx_crowdsec_222_v2026-04-05.sh (base: no clean name exists)
- fix_nginx_crowdsec_v2026-04-25.sh
