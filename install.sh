#!/bin/bash

# Kontrola root práv
if [ "$EUID" -ne 0 ]; then 
    echo "Spustite skript ako root"
    exit 1
fi

# Načítanie premenných
source .env

# Vytvorenie adresárovej štruktúry
mkdir -p ${BASE_DIR}/{www,mysql} \
    ${CONFIG_DIR}/{apache,mysql,pdns,ssl} \
    ${LOG_DIR} \
    ${BACKUP_DIR}

# Nastavenie práv
chown -R ${SYSTEM_USER}:${SYSTEM_GROUP} \
    ${BASE_DIR} \
    ${CONFIG_DIR} \
    ${LOG_DIR} \
    ${BACKUP_DIR}

# Kopírovanie konfiguračných súborov
cp config/apache/ddns.conf.example ${CONFIG_DIR}/apache/ddns.conf
cp config/mysql/my.cnf.example ${CONFIG_DIR}/mysql/my.cnf
cp config/pdns/pdns.conf.example ${CONFIG_DIR}/pdns/pdns.conf
cp www/config.php.example www/config.php

# Spustenie služieb
docker-compose up -d

echo "Inštalácia dokončená"
echo "Nezabudnite:"
echo "1. Upraviť konfiguračné súbory"
echo "2. Nastaviť SSL certifikáty"
echo "3. Nakonfigurovať DNS záznamy"
