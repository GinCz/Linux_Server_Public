mkdir -p ~/.config/mc
cat > ~/.config/mc/menu << 'EOF'
+ ! t t
0       Очистить экран (00)
	clear

+ ! t t
1       Быстрый аудит сервера (15 мин) (sos)
	clear
	/usr/local/bin/server_audit.sh
	read -n 1

+ ! t t
2       Аудит сервера (1 час) (sos1)
	clear
	/usr/local/bin/server_audit.sh 1h
	read -n 1

+ ! t t
3       Аудит сервера (24 часа) (sos24)
	clear
	/usr/local/bin/server_audit.sh 24h
	read -n 1

+ ! t t
4       Блокировка ботов (fight)
	clear
	/root/scripts/block_bots.sh
	read -n 1

+ ! t t
5       Проверка всех доменов (domains)
	clear
	/usr/local/bin/domains_check.sh
	read -n 1

+ ! t t
6       Полный Бэкап и Синхронизация (backup)
	clear
	/usr/local/bin/backup
	read -n 1

+ ! t t
7       CrowdSec: Активные баны (antivir)
	clear
	cscli decisions list
	read -n 1

+ ! t t
8       CrowdSec: Последние тревоги (banlog)
	clear
	cscli alerts list -l 20
	read -n 1

+ ! t t
9       Системная информация (infoo)
	clear
	/usr/local/bin/infoo
	read -n 1
EOF
