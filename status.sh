#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Kontrola Docker služieb
echo "=== Docker služby ==="
docker-compose ps
echo
docker-compose -f npm-compose.yml ps
echo

# Kontrola siete
echo "=== Sieťové pripojenia ==="
docker network inspect ddns_net
echo

# Kontrola diskov
echo "=== Využitie diskov ==="
df -h ${BASE_DIR} ${LOG_DIR} ${BACKUP_DIR}
echo

# Kontrola logov
echo "=== Posledné logy ==="
echo "System log:"
tail -n 5 ${LOG_DIR}/system.log
echo
echo "API log:"
tail -n 5 ${LOG_DIR}/api.log
echo
echo "PowerDNS log:"
tail -n 5 ${LOG_DIR}/pdns.log
echo

# Kontrola DNS
echo "=== DNS test ==="
dig @localhost ${EXAMPLE_DOMAIN} +short
echo

# Kontrola SSL
echo "=== SSL certifikáty ==="
curl -sI https://${EXAMPLE_DOMAIN} | grep -i "server-cert"
echo

log_message "Kontrola stavu systému dokončená"
