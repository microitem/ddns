#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/restore.log
}

# Kontrola parametrov
if [ -z "$1" ]; then
    echo "Použitie: $0 <cesta_k_zalohe.tar.gz>"
    echo "Dostupné zálohy:"
    ls -l ${BACKUP_DIR}/*.tar.gz
    exit 1
fi

BACKUP_FILE="$1"

# Kontrola existencie zálohy
if [ ! -f "${BACKUP_FILE}" ]; then
    log_message "Záloha neexistuje: ${BACKUP_FILE}"
    exit 1
fi

echo "!!! VAROVANIE !!!"
echo "Táto operácia prepíše existujúce dáta!"
read -p "Pokračovať? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Zastavenie služieb
log_message "Zastavujem služby"
./stop.sh

# Vytvorenie dočasného adresára
TEMP_DIR=$(mktemp -d)
log_message "Rozbaľujem zálohu do: ${TEMP_DIR}"
tar xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Obnova konfigurácie
log_message "Obnovujem konfiguráciu"
cp -r "${TEMP_DIR}"/*/config/* ${CONFIG_DIR}/

# Obnova webových súborov
log_message "Obnovujem webové súbory"
cp -r "${TEMP_DIR}"/*/www/* ${BASE_DIR}/www/

# Obnova databázy
log_message "Obnovujem databázu"
docker-compose up -d db
sleep 10  # Čakanie na štart databázy
docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
    < "${TEMP_DIR}"/*/database.sql

# Čistenie
log_message "Čistím dočasné súbory"
rm -rf "${TEMP_DIR}"

# Spustenie služieb
log_message "Spúšťam služby"
./start.sh

# Kontrola
log_message "Kontrolujem systém"
./status.sh

log_message "Obnova zo zálohy dokončená: ${BACKUP_FILE}"
echo "Obnova zo zálohy bola dokončená"
echo "Skontrolujte logy: ${LOG_DIR}/restore.log"
