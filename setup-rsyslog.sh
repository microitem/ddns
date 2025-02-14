#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Kontrola či je rsyslog nainštalovaný
if ! command -v rsyslogd &> /dev/null; then
    apt update && apt install -y rsyslog
fi

# Vytvorenie konfigurácie pre DDNS logy
RSYSLOG_FILE="/etc/rsyslog.d/ddns.conf"

cat > ${RSYSLOG_FILE} << EOF
# PowerDNS logy
if \$programname == 'pdns' then ${LOG_DIR}/pdns.log
& stop

# API logy
if \$programname == 'ddns-api' then ${LOG_DIR}/api.log
& stop

# Systémové logy DDNS
if \$programname startswith 'ddns-' then ${LOG_DIR}/system.log
& stop

# Vytvorenie súborov s správnymi právami
template(name="ddnsLogFile" type="string" string="%TIMESTAMP:::date-rfc3339% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n")
EOF

# Vytvorenie log adresára ak neexistuje
mkdir -p ${LOG_DIR}
chown -R syslog:adm ${LOG_DIR}
chmod 755 ${LOG_DIR}

# Nastavenie práv pre log súbory
touch ${LOG_DIR}/{pdns,api,system}.log
chown syslog:adm ${LOG_DIR}/*.log
chmod 640 ${LOG_DIR}/*.log

# Reštart služby
systemctl restart rsyslog

log_message "Rsyslog bol nakonfigurovaný"
echo "Rsyslog bol nakonfigurovaný"
echo "Skontrolujte logy: ${LOG_DIR}/system.log"
