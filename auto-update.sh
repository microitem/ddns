#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Kontrola či nie je aktualizácia už spustená
if [ -f /tmp/ddns-update.lock ]; then
    log_message "Aktualizácia už beží"
    exit 1
fi

# Vytvorenie zámku
touch /tmp/ddns-update.lock

# Čistenie pri ukončení
trap 'rm -f /tmp/ddns-update.lock' EXIT

# 1. Záloha pred aktualizáciou
log_message "Vytváram zálohu pred aktualizáciou"
./backup.sh

# 2. Aktualizácia systému
log_message "Aktualizujem systémové balíky"
apt update && apt upgrade -y

# 3. Aktualizácia Docker obrazov
log_message "Aktualizujem Docker obrazy"
docker-compose pull
docker-compose -f npm-compose.yml pull

# 4. Kontrola git repozitára
log_message "Kontrolujem aktualizácie skriptov"
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" != "$REMOTE" ]; then
    log_message "Nová verzia skriptov dostupná - aktualizujem"
    git pull origin main
    chmod +x *.sh
fi

# 5. Reštart služieb
log_message "Reštartujem služby"
./restart.sh

# 6. Kontrola systému
log_message "Kontrolujem systém po aktualizácii"
./status.sh
./security-check.sh

# 7. Čistenie
log_message "Čistím nepotrebné súbory"
docker system prune -af --volumes
apt autoremove -y
apt clean

log_message "Automatická aktualizácia dokončená"
echo "Aktualizácia systému bola dokončená"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
