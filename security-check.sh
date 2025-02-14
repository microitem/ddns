#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/system.log
}

# Funkcia pre kontrolu
check() {
    if [ $? -eq 0 ]; then
        echo "[OK] $1"
    else
        echo "[FAIL] $1"
        FAILS=$((FAILS+1))
    fi
}

FAILS=0

echo "=== Kontrola zabezpečenia DDNS systému ==="

# 1. Firewall
echo -e "\n== Firewall =="
ufw status | grep -q "Status: active"
check "UFW je aktívny"

# 2. Fail2ban
echo -e "\n== Fail2ban =="
fail2ban-client status | grep -q "Number of jail"
check "Fail2ban je aktívny"

# 3. SSL
echo -e "\n== SSL Certifikáty =="
curl -sI https://${EXAMPLE_DOMAIN} | grep -q "200 OK"
check "HTTPS je funkčné"

# 4. Docker
echo -e "\n== Docker zabezpečenie =="
docker info 2>/dev/null | grep -q "Security Options"
check "Docker security options"

# 5. Práva súborov
echo -e "\n== Súborové práva =="
find ${CONFIG_DIR} -type f -exec stat -c "%a %n" {} \; | grep -q "^[0-6][0-4][0-4]"
check "Konfiguračné súbory majú správne práva"

# 6. Porty
echo -e "\n== Otvorené porty =="
netstat -tuln | grep -q "${PORTS_HTTP}"
check "Web port je dostupný"
netstat -tuln | grep -q "${PORTS_DNS_TCP}"
check "DNS port je dostupný"

# 7. Logy
echo -e "\n== Kontrola logov =="
grep -i "error\|warning\|fail" ${LOG_DIR}/*.log | tail -5
check "Kontrola chýb v logoch"

if [ $FAILS -eq 0 ]; then
    log_message "Bezpečnostná kontrola: Všetko OK"
    echo -e "\nVšetky kontroly prešli úspešne!"
else
    log_message "Bezpečnostná kontrola: Nájdených ${FAILS} problémov"
    echo -e "\nNájdených ${FAILS} problémov - skontrolujte výstup vyššie"
fi
