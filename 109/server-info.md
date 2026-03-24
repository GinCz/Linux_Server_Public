# 🖥️ Server 109 — RU-FastVDS

## Hardware
- **IP:** xxx.xxx.xxx.109
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
- **Cloudflare:** Not used (RU sites, direct)
- **CrowdSec:** Active
- **AmneziaVPN:** Active

## WordPress Sites (23 total)

| Domain | WP Cron |
|---|---|
| stomatolog-belchikov.ru | system 23:00 |
| shapkioptom.ru | system 23:00 |
| natal-karta.ru | system 23:00 |
| geodesia-ekb.ru | system 23:00 |
| novorr-art.ru | system 23:00 |
| mtek-expert.ru | system 23:00 |
| nail-space-ekb.ru | system 23:00 |
| ne-son.ru | system 23:00 |
| septik4dom.ru | system 23:00 |
| comfort-eng.ru | system 23:00 |
| tri-sure.ru | system 23:00 |
| lvo-endo.ru | system 23:00 |
| stuba-dom.ru | system 23:00 |
| ugfp.ru | system 23:00 |
| prodvig-saita.ru | system 23:00 |
| news-port.ru | system 23:00 |
| study-italy.eu | system 23:00 |
| stanok-ural.ru | system 23:00 |
| tatra-ural.ru | system 23:00 |
| ver7.ru | system 23:00 |
| 4ton-96.ru | system 23:00 |
| andrey-maiorov.ru | system 23:00 |
| stassinhouse.ru | system 23:00 |

## Cron Jobs
```
0 3 * * 0   disk_cleanup.sh          # Every Sunday 3:00
0 23 * * *  wp-cron.php (23 sites)   # Every day 23:00
```

## Aliases
`load` `save` `infooo` `sos` `sos1/3/24/120` `fight` `domains`
`backup` `antivir` `banlog` `303` `chname` `mailclean`
`wphealth` `cleanup` `wpcron` `aw` `audit` `aws-test`
