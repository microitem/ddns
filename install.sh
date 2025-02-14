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

# Kontrola OS
if [ ! -f /etc/debian_version ]; then
    error "Tento skript je určený pre Debian/Ubuntu"
    exit 1
fi

# Inštalácia závislostí
log "Inštalujem potrebné balíčky..."
apt update
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    ufw \
    fail2ban \
    bind9-utils \
    mysql-client

# Inštalácia Docker
if ! command -v docker &> /dev/null; then
    log "Inštalujem Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Pridanie používateľa do docker skupiny
    usermod -aG docker $SUDO_USER
fi

# Inštalácia Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log "Inštalujem Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Vytvorenie adresárovej štruktúry
log "Vytváram adresárovú štruktúru..."
mkdir -p /opt/ddns/{config,logs,backups,www}
mkdir -p /opt/ddns/config/{pdns,apache,php,npm}
chown -R $SUDO_USER:$SUDO_USER /opt/ddns

# Konfigurácia firewallu
log "Konfigurujem firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 53/tcp
ufw allow 53/udp
ufw --force enable

# Konfigurácia fail2ban
log "Konfigurujem fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true

[ddns-api]
enabled = true
port = http,https
filter = ddns-api
logpath = /opt/ddns/logs/api.log
maxretry = 5
EOF

systemctl restart fail2ban

# Stiahnutie repozitára
log "Sťahujem zdrojový kód..."
cd /opt/ddns
if [ ! -d .git ]; then
    git clone https://github.com/tvoje/repo.git .
    chown -R $SUDO_USER:$SUDO_USER .
fi

# Vytvorenie .env súboru
if [ ! -f .env ]; then
    log "Vytváram .env súbor..."
    cat > .env << EOF
# Základné nastavenia
BASE_DIR=/opt/ddns
CONFIG_DIR=/opt/ddns/config
LOG_DIR=/opt/ddns/logs
BACKUP_DIR=/opt/ddns/backups

# Databáza
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_DATABASE=ddns
MYSQL_USER=ddns
MYSQL_PASSWORD=$(openssl rand -base64 32)

# PowerDNS
PDNS_API_KEY=$(openssl rand -base64 32)
PDNS_WEBSERVER_PASSWORD=$(openssl rand -base64 32)

# API
API_KEY=$(openssl rand -base64 32)
API_ENDPOINT=/update

# Domény
EXAMPLE_DOMAIN=example.com
DEFAULT_IP=1.2.3.4

# Porty
PORTS_SSH=22
PORTS_HTTP=80
PORTS_HTTPS=443
PORTS_DNS_TCP=53
PORTS_DNS_UDP=53

# Bezpečnosť
ALLOWED_IP_RANGES=127.0.0.1/8
EOF
    chown $SUDO_USER:$SUDO_USER .env
    chmod 600 .env
fi

# Nastavenie práv pre skripty
log "Nastavujem práva pre skripty..."
chmod +x *.sh

# Inicializácia systému
log "Inicializujem systém..."
./manage.sh init

# Dokončenie
log "Inštalácia bola dokončená!"
echo
echo "Pre správu systému použite: ./manage.sh"
echo "Pre zobrazenie nápovedy: ./manage.sh help"
echo
warning "Nezabudnite zmeniť predvolené heslá v .env súbore!"

