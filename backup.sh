#!/bin/bash

# Načítanie premenných
source .env

# Vytvorenie časovej značky
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_DATE}"

# Vytvorenie adresára pre zálohu
mkdir -p ${BACKUP_PATH}

# Záloha MySQL
echo "Zálohujem databázu..."
docker-compose exec -T db mysqldump \
    -u${MYSQL_USER} \
    -p${MYSQL_PASSWORD} \
    ${MYSQL_DATABASE} > ${BACKUP_PATH}/database.sql

# Záloha konfigurácie
echo "Zálohujem konfiguráciu..."
cp -r ${CONFIG_DIR} ${BACKUP_PATH}/config
cp -r ${BASE_DIR}/www ${BACKUP_PATH}/www
cp docker-compose.yml ${BACKUP_PATH}/
cp .env ${BACKUP_PATH}/

# Kompresia zálohy
echo "Kompresia zálohy..."
cd ${BACKUP_DIR}
tar -czf ${BACKUP_DATE}.tar.gz ${BACKUP_DATE}
rm -rf ${BACKUP_DATE}

# Vymazanie starých záloh (staršie ako 30 dní)
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +30 -delete

echo "Záloha dokončená: ${BACKUP_DIR}/${BACKUP_DATE}.tar.gz"
