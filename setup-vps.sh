#!/bin/bash

# Kontrola root práv
if [ "$EUID" -ne 0 ]; then 
    echo "Spustite skript ako root"
    exit 1
fi

# Aktualizácia systému
apt update && apt upgrade -y

# Inštalácia základných balíkov
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    ufw \
    fail2ban \
    htop \
    iftop \
    iotop \
    net-tools \
    chrony

# Inštalácia Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Inštalácia Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Vytvorenie používateľa
useradd -m -s /bin/bash ${SYSTEM_USER}
usermod -aG docker ${SYSTEM_USER}
usermod -aG sudo ${SYSTEM_USER}

# Firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ${PORTS_SSH}/tcp
ufw allow ${PORTS_DNS_TCP}/tcp
ufw allow ${PORTS_DNS_UDP}/udp
ufw allow ${PORTS_HTTP}/tcp
ufw allow ${PORTS_HTTPS}/tcp
ufw enable

# Fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# Časová zóna
timedatectl set-timezone Europe/Bratislava
systemctl enable chronyd
systemctl start chronyd

echo "VPS nastavenie dokončené"
echo "Nezabudnite:"
echo "1. Zmeniť SSH heslo"
echo "2. Nastaviť SSH kľúče"
echo "3. Zakázať root SSH prístup"
