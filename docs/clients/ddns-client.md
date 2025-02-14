# DDNS Klient

## Základný bash skript pre aktualizáciu IP

### 1. Vytvorenie skriptu
Vytvorte súbor `update-ddns.sh`:

#!/bin/bash

# Konfiguračné premenné
DDNS_HOST="nas.vasa-domena.com"
DDNS_SERVER="https://ddns.vasa-domena.com"
DDNS_PASSWORD="vase_heslo"
LOG_FILE="/var/log/ddns-update.log"

# Funkcia pre logovanie
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Získanie aktuálnej verejnej IP adresy
CURRENT_IP=$(curl -s https://api.ipify.org)

if [ $? -ne 0 ]; then
    log_message "Chyba: Nepodarilo sa získať IP adresu"
    exit 1
fi

# Aktualizácia DNS záznamu
UPDATE_URL="$DDNS_SERVER/api.php?hostname=$DDNS_HOST&password=$DDNS_PASSWORD&ip=$CURRENT_IP"
RESPONSE=$(curl -s "$UPDATE_URL")

# Kontrola odpovede
case $RESPONSE in
    "OK")
        log_message "IP adresa úspešne aktualizovaná na: $CURRENT_IP"
        ;;
    "BADAUTH")
        log_message "Chyba: Nesprávne prihlasovacie údaje"
        ;;
    "NOHOST")
        log_message "Chyba: Hostname neexistuje"
        ;;
    *)
        log_message "Chyba: Neočakávaná odpoveď - $RESPONSE"
        ;;
esac

### 2. Nastavenie oprávnení
chmod +x update-ddns.sh

## Automatické spúšťanie

### 1. Cron nastavenie
# Pridanie do crontab (aktualizácia každých 5 minút)
*/5 * * * * /cesta/k/update-ddns.sh

### 2. Systemd služba
# Vytvorenie service súboru /etc/systemd/system/ddns-update.service:
[Unit]
Description=DDNS Update Service
After=network.target

[Service]
Type=simple
ExecStart=/cesta/k/update-ddns.sh
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target

## Monitorovanie

### 1. Kontrola logov
tail -f /var/log/ddns-update.log

### 2. Testovanie
# Manuálne spustenie
./update-ddns.sh

# Overenie DNS záznamu
dig @8.8.8.8 nas.vasa-domena.com

## Riešenie problémov

### 1. Časté problémy
- Nesprávne prihlasovacie údaje
- Problémy s pripojením
- Neplatný hostname
- Problémy s právami

### 2. Debugovanie
# Pridanie debug módu do skriptu
set -x
# Podrobnejšie logovanie
curl -v "$UPDATE_URL"

## Bezpečnostné odporúčania
- Používajte HTTPS
- Pravidelne meňte heslo
- Kontrolujte logy
- Obmedzte prístup k skriptu
- Používajte bezpečné umiestnenie pre konfiguračné súbory
