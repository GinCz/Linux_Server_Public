# 🖥️ Server 109 — RU-FastVDS

## Hardware
- **IP:** xxx.xxx.xxx.109
- **Hostname:** 109-ru-vds
- **Provider:** FastVDS.ru, Russia
- **CPU:** 4 vCore AMD EPYC 7763
- **RAM:** 8 GB
- **Disk:** 80 GB NVMe
- **OS:** Ubuntu 24 LTS
- **Panel:** FastPanel (PHP 8.3/8.4)
- **Price:** 13 EUR/mo
- **Cloudflare:** NO — direct IP, Russian sites

## Network
- **Hostname:** 109-ru-vds
- **CrowdSec:** Active
- **AmneziaVPN:** Active
- **Color (SSH):** Light Pink `e[38;5;217m`

## Backup (updated 2026-03-25)
- **Script:** `109/system_backup.sh`
- **Primary:** local `/BackUP/109/` on this server
- **Secondary:** remote `/BackUP/109/` on 222 (xxx.xxx.xxx.222)
- **User:** `vlad` (password in Secret_Privat/servers.md)
- **Method:** sshpass + scp
- **Rotation:** keeps last 10 backups per location
- **Archive:** `/etc` + `/root` + `/usr/local/fastpanel2`
- **Telegram:** notifies on success and failure
- **Alias:** `backup`

## Aliases
`load` `save` `infooo` `sos` `sos1/3/24/120` `fight` `domains`
`backup` `antivir` `banlog` `303` `mailclean` `wphealth`
`cleanup` `wpcron` `aw` `audit` `aws-test` `00` `la`

## Changes log
- **2026-03-25:** backup system rebuilt — vlad user, local+remote, sshpass, no root SSH
- **2026-03-24:** shared_aliases.sh added, aw alias for WG stats
- **2026-03-12:** initial repo setup
