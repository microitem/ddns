#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/version.log
}

echo "=== Kontrola verzií komponentov ==="

# Kontrola OS
echo -n "Operačný systém: "
cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2

# Docker verzie
echo -n "Docker: "
docker --version | cut -d' ' -f3 | tr -d ','

echo -n "Docker Compose: "
docker-compose --version | cut -d' ' -f3

# Verzie kontajnerov
echo -e "\n== Docker kontajnery =="
docker-compose ps --format "table {{.Service}}\t{{.Image}}\t{{.Status}}"
docker-compose -f npm-compose.yml ps --format "table {{.Service}}\t{{.Image}}\t{{.Status}}"

# PowerDNS verzia
echo -e "\n== PowerDNS =="
docker-compose exec pdns pdns_control version

# Nginx verzia (cez NPM)
echo -e "\n== Nginx (NPM) =="
docker-compose -f npm-compose.yml exec npm nginx -v

# PHP verzia
echo -e "\n== PHP =="
docker-compose exec web php -v | head -n1

# MySQL verzia
echo -e "\n== MySQL =="
docker-compose exec db mysql -V

# Git verzia repozitára
echo -e "\n== Git repozitár =="
echo "Aktuálna vetva: $(git branch --show-current)"
echo "Posledný commit: $(git log -1 --format=%H)"
echo "Dátum commitu: $(git log -1 --format=%cd)"

# Kontrola aktualizácií
echo -e "\n== Dostupné aktualizácie =="
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "Systém je aktuálny"
else
    echo "Dostupná nová verzia"
    echo "Použite './update.sh' pre aktualizáciu"
fi

log_message "Kontrola verzií dokončená"
echo -e "\nKompletný výpis nájdete v: ${LOG_DIR}/version.log"
