#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/test.log
}

# Funkcia pre test
run_test() {
    echo -n "Test: $1 ... "
    if eval $2; then
        echo "OK"
        return 0
    else
        echo "FAIL"
        return 1
    fi
}

FAILS=0

echo "=== Začínam testovanie DDNS systému ==="

# 1. Test Docker služieb
run_test "Docker kontajnery bežia" \
    "docker-compose ps | grep -q 'Up' && docker-compose -f npm-compose.yml ps | grep -q 'Up'" || \
    ((FAILS++))

# 2. Test DNS
run_test "DNS server odpovedá" \
    "dig @localhost ${EXAMPLE_DOMAIN} +short > /dev/null" || \
    ((FAILS++))

# 3. Test Web servera
run_test "Web server odpovedá" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost | grep -q 200" || \
    ((FAILS++))

# 4. Test SSL
run_test "HTTPS je funkčné" \
    "curl -sk -o /dev/null -w '%{http_code}' https://${EXAMPLE_DOMAIN} | grep -q 200" || \
    ((FAILS++))

# 5. Test API
run_test "API endpoint odpovedá" \
    "curl -s 'http://localhost${API_ENDPOINT}?hostname=test.com' | grep -q 'BADAUTH'" || \
    ((FAILS++))

# 6. Test databázy
run_test "Databáza je dostupná" \
    "docker-compose exec -T db mysqladmin -u${MYSQL_USER} -p${MYSQL_PASSWORD} ping | grep -q 'alive'" || \
    ((FAILS++))

# 7. Test logovanie
run_test "Logovanie funguje" \
    "echo 'test' >> ${LOG_DIR}/test.log && tail -1 ${LOG_DIR}/test.log | grep -q 'test'" || \
    ((FAILS++))

# 8. Test zálohovanie
run_test "Zálohovanie funguje" \
    "./backup.sh > /dev/null && ls -1 ${BACKUP_DIR}/*.tar.gz | wc -l | grep -q '[1-9]'" || \
    ((FAILS++))

# Výsledok
if [ $FAILS -eq 0 ]; then
    log_message "Všetky testy prešli úspešne"
    echo -e "\nVšetky testy prešli úspešne!"
else
    log_message "Zlyhalo ${FAILS} testov"
    echo -e "\nZlyhalo ${FAILS} testov!"
fi

echo "Detailné výsledky nájdete v: ${LOG_DIR}/test.log"
exit $FAILS
