#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Vytvorenie logrotate konfigurácie
LOGROTATE_FILE="/etc/logrotate.d/ddns"

cat > ${LOGROTATE_FILE} << EOF
${LOG_DIR}/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${SYSTEM_USER} ${SYSTEM_GROUP}
    sharedscripts
    postrotate
        systemctl restart rsyslog >/dev/null 2>&1 || true
    endscript
}

${LOG_DIR}/pdns.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${SYSTEM_USER} ${SYSTEM_GROUP}
    sharedscripts
    postrotate
        docker-compose restart pdns >/dev/null 2>&1 || true
    endscript
}

${LOG_DIR}/api.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${SYSTEM_USER} ${SYSTEM_GROUP}
}
EOF

# Nastavenie práv
chmod 644 ${LOGROTATE_FILE}

# Test konfigurácie
logrotate -d ${LOGROTATE_FILE}

log_message "Logrotate konfigurácia bola nastavená"
echo "Logrotate konfigurácia bola nastavená v súbore: ${LOGROTATE_FILE}"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
