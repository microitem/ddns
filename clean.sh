#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Vytvorenie zálohy pred čistením
log_message "Vytváram zálohu pred čistením"
./backup.sh

# Zastavenie všetkých služieb
log_message "Zastavujem všetky služby"
./stop.sh

# Čistenie Docker
log_message "Čistím Docker systém"
docker system prune -af --volumes

# Čistenie logov
log_message "Čistím staré logy"
find ${LOG_DIR} -name "*.log" -mtime +30 -delete

# Čistenie záloh
log_message "Čistím staré zálohy"
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +30 -delete

# Čistenie dočasných súborov
log_message "Čistím dočasné súbory"
rm -rf ${BASE_DIR}/tmp/*

echo "Systém bol vyčistený"
echo "Pre opätovné spustenie použite: ./start.sh"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
