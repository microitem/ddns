# Zálohovanie DDNS servera

## Automatický zálohovací skript
#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d)

# Záloha MySQL
docker-compose exec db mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${BACKUP_DIR}/db_${BACKUP_DATE}.sql

# Záloha konfigurácie
cp docker-compose.yml ${BACKUP_DIR}/docker-compose_${BACKUP_DATE}.yml
cp .env ${BACKUP_DIR}/env_${BACKUP_DATE}
tar -czf ${BACKUP_DIR}/www_${BACKUP_DATE}.tar.gz ${BASE_DIR}/www/

# Vymazanie starých záloh
find ${BACKUP_DIR} -type f -mtime +30 -delete

## Cron nastavenie
0 1 * * * /root/backup-ddns.sh

## Obnova zo zálohy
1. Databáza:
docker-compose exec -i db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < ${BACKUP_DIR}/db_backup.sql

2. Konfigurácia:
tar -xzf ${BACKUP_DIR}/www_backup.tar.gz -C ${BASE_DIR}

3. Reštart služieb:
docker-compose down
docker-compose up -d
