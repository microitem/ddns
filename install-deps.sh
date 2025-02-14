#!/bin/bash

# Kontrola root práv
if [ "$EUID" -ne 0 ]; then 
    echo "Spustite skript ako root"
    exit 1
fi

# Aktualizácia systému
apt update && apt upgrade -y

# Základné nástroje
apt install -y \
    curl \
    wget \
    git \
    nano \
    htop \
    net-tools \
    dnsutils \
    ufw \
    fail2ban \
    cron \
    logrotate

# Inštalácia Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Inštalácia Docker Compose
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Kontrola inštalácie
echo "=== Verzie nainštalovaných komponentov ==="
docker --version
docker-compose --version
dig -version
ufw --version

echo "Inštalácia závislostí dokončená"
