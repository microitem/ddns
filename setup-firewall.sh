#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Kontrola či je UFW nainštalovaný
if ! command -v ufw &> /dev/null; then
    apt update && apt install -y ufw
fi

# Reset firewallu
ufw --force reset

# Základné pravidlá
ufw default deny incoming
ufw default allow outgoing

# Povolené porty
ufw allow ${PORTS_SSH}/tcp
ufw allow ${PORTS_DNS_TCP}/tcp
ufw allow ${PORTS_DNS_UDP}/udp
ufw allow ${PORTS_HTTP}/tcp
ufw allow ${PORTS_HTTPS}/tcp
ufw allow 81/tcp  # NPM admin rozhranie

# Povolenie konkrétnych IP adries
if [ ! -z "${ALLOWED_IP_RANGES}" ]; then
    for ip in ${ALLOWED_IP_RANGES//,/ }; do
        ufw allow from $ip
        log_message "Povolená IP/rozsah: $ip"
    done
fi

# Zapnutie firewallu
ufw --force enable

# Kontrola stavu
ufw status verbose

log_message "Firewall bol nakonfigurovaný"
echo "Firewall bol nakonfigurovaný"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
