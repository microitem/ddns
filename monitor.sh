#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/monitor.log
}

# Kontrola služieb
check_services() {
    # Docker kontajnery
    docker-compose ps | grep "Up" | grep -q "ddns_pdns" || log_message "ERROR: PowerDNS nie je spustený"
    docker-compose ps | grep "Up" | grep -q "ddns_web" || log_message "ERROR: Web server nie je spustený"
    docker-compose ps | grep "Up" | grep -q "ddns_db" || log_message "ERROR: MySQL nie je spustený"
}

# Kontrola DNS
check_dns() {
    dig @localhost ${EXAMPLE_DOMAIN} +short > /dev/null || log_message "ERROR: DNS test zlyhal"
}

# Kontrola API
check_api() {
    curl -s "http://localhost${API_ENDPOINT}?hostname=${EXAMPLE_SUBDOMAIN}&password=test" | grep -q "BADAUTH" || log_message "ERROR: API test zlyhal"
}

# Kontrola diskov
check_disk() {
    DISK_USAGE=$(df -h ${BASE_DIR} | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ ${DISK_USAGE} -gt 90 ]; then
        log_message "WARNING: Disk je zaplnený na ${DISK_USAGE}%"
    fi
}

# Kontrola logov
check_logs() {
    grep -i "error" ${LOG_DIR}/*.log | tail -5 | while read -r line; do
        log_message "LOG ERROR: $line"
    done
}

# Hlavná kontrola
log_message "Začiatok kontroly"
check_services
check_dns
check_api
check_disk
check_logs
log_message "Koniec kontroly"

# Vyčistenie starých logov (staršie ako 7 dní)
find ${LOG_DIR} -name "*.log" -mtime +7 -delete
