#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/backup.log
}

# Kontrola konfigurácie
if [ -z "${REMOTE_BACKUP_HOST}" ] || [ -z "${REMOTE_BACKUP_USER}" ] || [ -z "${REMOTE_BACKUP_PATH}" ]; then
    log_message "Chýba konfigurácia vzdialeného servera"
    exit 1
fi

# Vytvorenie lokálnej zálohy
log_message "Vytváram lokálnu zálohu"
./backup.sh

# Získanie najnovšej zálohy
LATEST_BACKUP=$(ls -t ${BACKUP_DIR}/*.tar.gz | head -1)
if [ -z "${LATEST_BACKUP}" ]; then
    log_message "Nenašla sa žiadna záloha"
    exit 1
fi

# Kontrola pripojenia k vzdialenému serveru
if ! ssh -q ${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST} exit; then
    log_message "Nepodarilo sa pripojiť k vzdialenému serveru"
    exit 1
fi

# Vytvorenie vzdialeného adresára
ssh ${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST} "mkdir -p ${REMOTE_BACKUP_PATH}"

# Prenos zálohy
log_message "Prenášam zálohu na vzdialený server"
rsync -avz --progress ${LATEST_BACKUP} \
    ${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST}:${REMOTE_BACKUP_PATH}/

# Čistenie starých záloh na vzdialenom serveri
log_message "Čistím staré zálohy na vzdialenom serveri"
ssh ${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST} \
    "find ${REMOTE_BACKUP_PATH} -name '*.tar.gz' -mtime +30 -delete"

log_message "Vzdialená záloha dokončená: ${LATEST_BACKUP}"
echo "Vzdialená záloha bola dokončená"
echo "Skontrolujte logy: ${LOG_DIR}/backup.log"
