#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Kontrola root práv
if [ "$EUID" -ne 0 ]; then 
    echo "Spustite skript ako root"
    exit 1
fi

echo "=== Začínam kompletnú inštaláciu DDNS systému ==="

# 1. Inštalácia závislostí
log_message "1/10 Inštalujem závislosti"
./install-deps.sh

# 2. Nastavenie firewallu
log_message "2/10 Nastavujem firewall"
./setup-firewall.sh

# 3. Nastavenie fail2ban
log_message "3/10 Nastavujem fail2ban"
./setup-fail2ban.sh

# 4. Nastavenie rsyslog
log_message "4/10 Nastavujem rsyslog"
./setup-rsyslog.sh

# 5. Nastavenie logrotate
log_message "5/10 Nastavujem logrotate"
./setup-logrotate.sh

# 6. Nastavenie monitoringu
log_message "6/10 Nastavujem monitoring"
./setup-monitoring.sh

# 7. Nastavenie cron úloh
log_message "7/10 Nastavujem cron úlohy"
./setup-cron.sh

# 8. Spustenie NPM
log_message "8/10 Spúšťam Nginx Proxy Manager"
docker-compose -f npm-compose.yml up -d

# 9. Spustenie DDNS služieb
log_message "9/10 Spúšťam DDNS služby"
docker-compose up -d

# 10. Kontrola systému
log_message "10/10 Kontrolujem systém"
./status.sh

echo "=== Inštalácia dokončená ==="
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
echo "NPM admin rozhranie: http://localhost:81"
