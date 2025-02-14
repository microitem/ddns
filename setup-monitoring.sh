#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Inštalácia monitorovacích nástrojov
apt update && apt install -y \
    htop \
    iftop \
    iotop \
    nmon \
    sysstat \
    vnstat

# Konfigurácia sysstat
sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
systemctl enable sysstat
systemctl start sysstat

# Konfigurácia vnstat
vnstat -u -i $(ip route | grep default | awk '{print $5}')
systemctl enable vnstat
systemctl start vnstat

# Vytvorenie monitorovacieho skriptu
MONITOR_SCRIPT="${BASE_DIR}/scripts/system-stats.sh"

mkdir -p $(dirname ${MONITOR_SCRIPT})
cat > ${MONITOR_SCRIPT} << EOF
#!/bin/bash

# CPU a pamäť
echo "=== CPU a RAM ==="
top -b -n 1 | head -n 5

# Disk
echo -e "\n=== Využitie disku ==="
df -h ${BASE_DIR} ${LOG_DIR} ${BACKUP_DIR}

# Sieť
echo -e "\n=== Sieťové štatistiky ==="
vnstat -h

# Docker
echo -e "\n=== Docker kontajnery ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# DNS štatistiky
echo -e "\n=== PowerDNS štatistiky ==="
docker-compose exec pdns pdns_control show "*"
EOF

chmod +x ${MONITOR_SCRIPT}

# Pridanie do cronu
echo "*/5 * * * * root ${MONITOR_SCRIPT} >> ${LOG_DIR}/monitoring.log 2>&1" > /etc/cron.d/ddns-monitoring

log_message "Monitoring bol nakonfigurovaný"
echo "Monitoring bol nakonfigurovaný"
echo "Štatistiky nájdete v: ${LOG_DIR}/monitoring.log"
