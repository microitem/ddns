#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Zastavenie DDNS služieb
log_message "Zastavujem DDNS služby"
docker-compose down

# Zastavenie NPM
log_message "Zastavujem Nginx Proxy Manager"
docker-compose -f npm-compose.yml down

# Záloha pred vypnutím
log_message "Vytváram zálohu"
./backup.sh

echo "Systém je zastavený"
echo "Záloha bola vytvorená v: ${BACKUP_DIR}"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
