#!/bin/bash

# Farby pre výstup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funkcia pre výpis
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] CHYBA: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] VAROVANIE: $1${NC}"
}

# Kontrola root práv
if [ "$EUID" -ne 0 ]; then
    error "Tento skript musí byť spustený s root právami"
    exit 1
fi

# Načítanie premenných
if [ -f .env ]; then
    source .env
else
    error "Súbor .env neexistuje"
    exit 1
fi

# Kontrola aktuálnej verzie
current_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
log "Aktuálna verzia: $current_version"

# Záloha pred aktualizáciou
log "Vytváram zálohu pred aktualizáciou..."
./manage-backups.sh backup

# Aktualizácia repozitára
log "Kontrolujem aktualizácie..."
git fetch origin
latest_version=$(git describe --tags --abbrev=0 origin/main 2>/dev/null || echo "unknown")

if [ "$current_version" == "$latest_version" ]; then
    log "Systém je aktuálny (verzia $current_version)"
    exit 0
fi

warning "Nová verzia je dostupná: $latest_version"
read -p "Chcete pokračovať s aktualizáciou? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aktualizácia zrušená"
    exit 1
fi

# Zastavenie služieb
log "Zastavujem služby..."
docker-compose down
docker-compose -f npm-compose.yml down

# Záloha konfigurácie
log "Zálohujem konfiguráciu..."
cp -r ${CONFIG_DIR} ${CONFIG_DIR}.bak
cp .env .env.bak

# Aktualizácia kódu
log "Aktualizujem zdrojový kód..."
git pull origin main

# Kontrola nových závislostí
log "Kontrolujem závislosti..."
./install.sh --check-deps

# Aktualizácia Docker obrazov
log "Aktualizujem Docker obrazy..."
docker-compose pull
docker-compose -f npm-compose.yml pull

# Aktualizácia konfigurácie
log "Aktualizujem konfiguráciu..."
if [ -f update-config.sh ]; then
    ./update-config.sh
fi

# Aktualizácia databázy
log "Aktualizujem databázu..."
if [ -f update-db.sh ]; then
    ./update-db.sh
fi

# Spustenie služieb
log "Spúšťam služby..."
docker-compose up -d
docker-compose -f npm-compose.yml up -d

# Kontrola služieb
log "Kontrolujem služby..."
sleep 10
if ! docker-compose ps | grep -q "Up"; then
    error "Niektoré služby sa nespustili správne"
    warning "Obnovovanie zo zálohy..."
    
    docker-compose down
    docker-compose -f npm-compose.yml down
    
    mv ${CONFIG_DIR}.bak ${CONFIG_DIR}
    mv .env.bak .env
    
    docker-compose up -d
    docker-compose -f npm-compose.yml up -d
    
    error "Aktualizácia zlyhala, systém bol obnovený do pôvodného stavu"
    exit 1
fi

# Čistenie
log "Čistím systém..."
docker system prune -f
rm -rf ${CONFIG_DIR}.bak
rm -f .env.bak

# Kontrola verzie po aktualizácii
new_version=$(git describe --tags --abbrev=0)
log "Aktualizácia dokončená!"
echo
echo "Predchádzajúca verzia: $current_version"
echo "Aktuálna verzia: $new_version"
echo
warning "Skontrolujte prosím logy pre prípadné chyby:"
echo "tail -f ${LOG_DIR}/*.log"

