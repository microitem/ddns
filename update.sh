#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/update.log
}

# Záloha pred aktualizáciou
log_message "Vytváram zálohu pred aktualizáciou..."
./backup.sh

# Aktualizácia git repozitára
log_message "Aktualizujem git repozitár..."
git pull origin main

# Aktualizácia Docker obrazov
log_message "Aktualizujem Docker obrazy..."
docker-compose pull

# Reštart služieb
log_message "Reštartujem služby..."
docker-compose down
docker-compose up -d

# Kontrola služieb
log_message "Kontrolujem služby..."
./monitor.sh

# Vyčistenie
log_message "Čistím nepotrebné Docker obrazy..."
docker image prune -f

log_message "Aktualizácia dokončená"

# Výpis verzie
echo "Aktuálna verzia: $(git describe --tags --abbrev=0)"
