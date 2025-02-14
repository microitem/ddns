# Zálohovanie DDNS servera

## Komponenty na zálohovanie
1. MySQL databáza (PowerDNS záznamy)
2. Konfiguračné súbory
3. Docker volumes

## Automatické zálohovanie

### 1. Zálohovací skript
Vytvorte súbor `/root/backup-ddns.sh`:
#!/bin/bash

# Nastavenie premenných
BACKUP_DIR="/backup/ddns"
DATE=$(date +%Y%m%d)
MYSQL_USER="powerdns"
MYSQL_PASSWORD="vase_heslo"
MYSQL_DATABASE="powerdns"

# Vytvorenie zálohovacieho adresára
mkdir -p $BACKUP_DIR

# Záloha MySQL databázy
docker exec ddns_db_1 mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $BACKUP_DIR/powerdns_$DATE.sql

# Záloha konfiguračných súborov
cp docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml
cp .env $BACKUP_DIR/env_$DATE
tar -czf $BACKUP_DIR/www_$DATE.tar.gz www/

# Vymazanie starých záloh (staršie ako 30 dní)
find $BACKUP_DIR -type f -mtime +30 -delete

### 2. Nastavenie automatického spúšťania
Pridajte do crontab:
0 1 * * * /root/backup-ddns.sh

## Manuálne zálohovanie

### 1. Záloha databázy
docker exec ddns_db_1 mysqldump -upowerdns -p powerdns > powerdns_manual_backup.sql

### 2. Záloha konfigurácie
tar -czf ddns_config_backup.tar.gz docker-compose.yml .env www/

## Obnova zo zálohy

### 1. Obnova databázy
docker exec -i ddns_db_1 mysql -upowerdns -p powerdns < powerdns_backup.sql

### 2. Obnova konfigurácie
tar -xzf ddns_config_backup.tar.gz

### 3. Reštart služieb
docker-compose down
docker-compose up -d

## Odporúčania
- Pravidelne kontrolujte zálohy
- Uchovávajte zálohy na vzdialenom úložisku
- Testujte obnovu zo zálohy
- Dokumentujte zmeny v konfigurácii
