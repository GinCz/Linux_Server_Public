# 🖥️ Server 222 — DE-NetCup

## Hardware
- **IP:** xxx.xxx.xxx.222
- **Provider:** NetCup.com, Germany
- **CPU:** 4 vCore AMD EPYC-Genoa
- **RAM:** 8 GB DDR5 ECC
- **Disk:** 256 GB NVMe
- **OS:** Ubuntu 24 LTS
- **Panel:** FastPanel (PHP 8.3/8.4)
- **Price:** 8.60 EUR/mo
- **Cloudflare:** YES — all sites behind Cloudflare

## Network
- **Hostname:** 222-DE-NetCup
- **Cloudflare:** All .eu, .cz, .uk, .com domains
- **CrowdSec:** Active
- **AmneziaVPN:** Active

## WordPress Sites (44 total)

| Domain | User | WP Cron |
|---|---|---|
| detailing-alex.eu | alex_detailing | system 23:00 |
| ru-tv.eu | gincz | system 23:00 |
| ekaterinburg-sro.eu | gincz | system 23:00 |
| eco-seo.cz | gincz | system 23:00 |
| eurasia-translog.cz | serg_et | system 23:00 |
| east-vector.cz | serg_et | system 23:00 |
| rail-east.uk | serg_et | system 23:00 |
| vymena-motoroveho-oleje.cz | serg_pimonov | system 23:00 |
| car-chip.eu | serg_pimonov | system 23:00 |
| diamond-odtah.cz | diamond-drivers | system 23:00 |
| sveta-drobot.cz | sveta_drobot | system 23:00 |
| bio-zahrada.eu | tan-adrian | system 23:00 |
| alejandrofashion.cz | alejandrofashion | system 23:00 |
| czechtoday.eu | dmitry-vary | system 23:00 |
| stm-services-group.cz | tatiana_podzolkova | system 23:00 |
| autoservis-praha.eu | arslan | system 23:00 |
| praha-autoservis.eu | bayerhoff | system 23:00 |
| neonella.eu | neonella | system 23:00 |
| megan-consult.cz | igor_kap | system 23:00 |
| abl-metal.com | igor_kap | system 23:00 |
| stopservis-vestec.cz | serg_reno | system 23:00 |
| kadernik-olga.eu | olga_pisareva | system 23:00 |
| kk-med.eu | karina | system 23:00 |
| kadernictvi-salon.eu | viktoria | system 23:00 |
| doska-hun.ru | doski | system 23:00 |
| doska-ua.ru | doski | system 23:00 |
| doska-mld.ru | doski | system 23:00 |
| doska-it.ru | doski | system 23:00 |
| doska-esp.ru | doski | system 23:00 |
| doska-cz.ru | doski | system 23:00 |
| doska-isl.ru | doski | system 23:00 |
| doska-pl.ru | doski | system 23:00 |
| doska-de.ru | doski | system 23:00 |
| doska-gr.ru | doski | system 23:00 |
| doska-fr.ru | doski | system 23:00 |
| balance-b2b.eu | sveta_tuk | system 23:00 |
| car-bus-autoservice.cz | andrey-autoservis | system 23:00 |
| autoservis-rychlik.cz | andrey-autoservis | system 23:00 |
| hulk-jobs.cz | hulk | system 23:00 |
| gadanie-tel.eu | gadanie-tel | system 23:00 |
| lybawa.com | gadanie-tel | system 23:00 |
| wowflow.cz | wowflow | system 23:00 |
| svetaform.eu | spa | system 23:00 |
| tstwist.cz | tstwist | system 23:00 |

## Cron Jobs
```
0 3 * * 0   disk_cleanup.sh          # Every Sunday 3:00
0 23 * * *  wp-cron.php (44 sites)   # Every day 23:00
```

## Aliases
`load` `save` `infooo` `sos` `sos1/3/24/120` `fight` `domains`
`backup` `antivir` `banlog` `303` `chname` `mailclean`
`wphealth` `cleanup` `wpcron` `aw` `audit` `aws-test`
