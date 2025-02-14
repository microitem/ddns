#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Vytvorenie cron súboru
CRON_FILE="/etc/cron.d/ddns-tasks"

# Zálohovanie
echo "0 1 * * * root ${PWD}/backup.sh > /dev/null 2>&1" > ${CRON_FILE}

# Monitoring
echo "*/5 * * * * root ${PWD}/monitor.sh > /dev/null 2>&1" >> ${CRON_FILE}

# Čistenie logov
echo "0 0 * * 0 root ${PWD}/clean.sh > /dev/null 2>&1" >> ${CRON_FILE}

# Aktualizácia
echo "0 3 * * * root ${PWD}/update.sh > /dev/null 2>&1" >> ${CRON_FILE}

# Kontrola stavu
echo "*/30 * * * * root ${PWD}/status.sh > /dev/null 2>&1" >> ${CRON_FILE}

# Nastavenie práv
chmod 644 ${CRON_FILE}

# Reštart cron služby
systemctl restart cron

log_message "Cron úlohy boli nastavené"
echo "Cron úlohy boli nastavené v súbore: ${CRON_FILE}"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
