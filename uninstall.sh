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

echo "!!! VAROVANIE !!!"
echo "Tento skript kompletne odstráni DDNS systém vrátane všetkých dát!"
echo "Pred pokračovaním sa uistite, že máte zálohu."
read -p "Pokračovať? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 1. Zastavenie služieb
log_message "Zastavujem všetky služby"
./stop.sh

# 2. Odstránenie Docker kontajnerov a obrazov
log_message "Odstraňujem Docker kontajnery a obrazy"
docker-compose down -v --rmi all
docker-compose -f npm-compose.yml down -v --rmi all
docker network rm ddns_net || true

# 3. Odstránenie konfiguračných súborov
log_message "Odstraňujem konfiguračné súbory"
rm -rf ${CONFIG_DIR}
rm -f /etc/cron.d/ddns-*
rm -f /etc/logrotate.d/ddns
rm -f /etc/fail2ban/jail.d/ddns.conf
rm -f /etc/rsyslog.d/ddns.conf

# 4. Odstránenie dát
log_message "Odstraňujem dáta"
rm -rf ${BASE_DIR}
rm -rf ${LOG_DIR}

# 5. Záloha (ak užívateľ chce)
read -p "Zachovať zálohy? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_message "Odstraňujem zálohy"
    rm -rf ${BACKUP_DIR}
fi

# 6. Reštart služieb
systemctl restart rsyslog
systemctl restart fail2ban

log_message "Systém bol kompletne odstránený"
echo "DDNS systém bol kompletne odstránený"
echo "Pre novú inštaláciu použite: ./setup-all.sh"
