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

# Potvrdenie odinštalácie
echo -e "${RED}!!! VAROVANIE !!!"
echo "Táto operácia odstráni celý DDNS systém vrátane:"
echo "- Všetkých dát a konfigurácie"
echo "- Docker kontajnerov a obrazov"
echo "- Všetkých súborov v ${BASE_DIR}"
echo -e "- Všetkých záloh${NC}"
echo
read -p "Ste si istý, že chcete pokračovať? (napíšte 'YES' pre potvrdenie) " confirm
if [ "$confirm" != "YES" ]; then
    echo "Odinštalácia zrušená"
    exit 1
fi

# Vytvorenie poslednej zálohy
log "Vytváram poslednú zálohu..."
./manage-backups.sh backup

# Zastavenie a odstránenie kontajnerov
log "Zastavujem služby..."
docker-compose down -v
docker-compose -f npm-compose.yml down -v

# Odstránenie Docker obrazov
log "Odstraňujem Docker obrazy..."
docker rmi $(docker images -q) -f 2>/dev/null || true

# Odstránenie Docker siete
log "Odstraňujem Docker sieť..."
docker network rm ddns_net 2>/dev/null || true

# Odstránenie firewall pravidiel
log "Odstraňujem firewall pravidlá..."
ufw delete allow 53/tcp
ufw delete allow 53/udp
ufw delete allow http
ufw delete allow https

# Odstránenie fail2ban konfigurácie
log "Odstraňujem fail2ban konfiguráciu..."
rm -f /etc/fail2ban/jail.d/ddns.conf
rm -f /etc/fail2ban/filter.d/ddns-api.conf
systemctl restart fail2ban

# Odstránenie adresárov
log "Odstraňujem súbory..."
rm -rf ${BASE_DIR}

# Odstránenie používateľských nastavení
log "Odstraňujem používateľské nastavenia..."
if [ -d ~/.ddns ]; then
    rm -rf ~/.ddns
fi

# Vyčistenie systému
log "Čistím systém..."
apt autoremove -y
apt clean

# Dokončenie
log "Odinštalácia bola dokončená!"
echo
warning "Všetky dáta boli odstránené. Posledná záloha je uložená v: ${BACKUP_DIR}"
warning "Pre kompletné odstránenie systému môžete teraz odstrániť Docker a ostatné závislosti:"
echo "apt remove docker-ce docker-ce-cli containerd.io docker-compose-plugin"
echo "apt remove fail2ban bind9-utils mysql-client"
echo
echo "Ďakujeme, že ste používali náš DDNS systém!"

