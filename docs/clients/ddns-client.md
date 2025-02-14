# DDNS Klient

## Základný skript
#!/bin/bash

# Konfigurácia
DDNS_HOST="${EXAMPLE_SUBDOMAIN}"
DDNS_SERVER="http://${EXAMPLE_DOMAIN}"
DDNS_PASSWORD="vase_heslo"
LOG_FILE="${LOG_DIR}/ddns-client.log"

# Získanie IP
CURRENT_IP=$(curl -s https://api.ipify.org)

# Aktualizácia DNS
UPDATE_URL="${DDNS_SERVER}${API_ENDPOINT}?hostname=${DDNS_HOST}&password=${DDNS_PASSWORD}&ip=${CURRENT_IP}"
RESPONSE=$(curl -s "$UPDATE_URL")

# Logovanie
echo "$(date '+%Y-%m-%d %H:%M:%S') - IP: ${CURRENT_IP}, Response: ${RESPONSE}" >> ${LOG_FILE}

## Automatické spustenie
# Cron (každých 5 minút):
*/5 * * * * /path/to/ddns-client.sh

# Systemd služba:
[Unit]
Description=DDNS Client
After=network.target

[Service]
Type=simple
ExecStart=/path/to/ddns-client.sh
Restart=always
RestartSec=${REFRESH_INTERVAL}

[Install]
WantedBy=multi-user.target

## Logovanie
- Klient log: ${LOG_DIR}/ddns-client.log
- Rotácia logov: logrotate
