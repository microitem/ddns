#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Zastavenie systému
log_message "Reštartujem systém - zastavujem služby"
./stop.sh

# Krátke čakanie
sleep 5

# Spustenie systému
log_message "Reštartujem systém - spúšťam služby"
./start.sh

# Kontrola
log_message "Kontrolujem služby po reštarte"
./monitor.sh

echo "Systém bol reštartovaný"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
