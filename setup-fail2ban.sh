#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Kontrola či je fail2ban nainštalovaný
if ! command -v fail2ban-client &> /dev/null; then
    apt update && apt install -y fail2ban
fi

# Vytvorenie vlastnej konfigurácie
JAIL_FILE="/etc/fail2ban/jail.local"

cat > ${JAIL_FILE} << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ${ALLOWED_IP_RANGES}

[sshd]
enabled = true
port = ${PORTS_SSH}
filter = sshd
logpath = /var/log/auth.log

[ddns-api]
enabled = true
port = ${PORTS_HTTP},${PORTS_HTTPS}
filter = ddns-api
logpath = ${LOG_DIR}/api.log
maxretry = 5
bantime = 7200
EOF

# Vytvorenie vlastného filtra pre DDNS API
FILTER_FILE="/etc/fail2ban/filter.d/ddns-api.conf"

cat > ${FILTER_FILE} << EOF
[Definition]
failregex = ^.* BADAUTH .* from <HOST>$
            ^.* ABUSE .* from <HOST>$
ignoreregex =
EOF

# Reštart služby
systemctl enable fail2ban
systemctl restart fail2ban

# Kontrola stavu
fail2ban-client status

log_message "Fail2ban bol nakonfigurovaný"
echo "Fail2ban bol nakonfigurovaný"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
