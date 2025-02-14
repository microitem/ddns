#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Kontrola Docker siete
if ! docker network ls | grep -q "ddns_net"; then
    log_message "Vytváram Docker sieť ddns_net"
    docker network create ddns_net
fi

# Spustenie NPM
log_message "Spúšťam Nginx Proxy Manager"
docker-compose -f npm-compose.yml up -d

# Čakanie na NPM
sleep 10

# Spustenie DDNS služieb
log_message "Spúšťam DDNS služby"
docker-compose up -d

# Kontrola služieb
log_message "Kontrolujem služby"
./monitor.sh

echo "Systém je spustený"
echo "NPM admin rozhranie: http://localhost:81"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
