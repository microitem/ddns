#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/network.log
}

# Funkcia pre kontrolu siete
check_network() {
    echo "=== Kontrola sieťového pripojenia ==="
    
    # Kontrola Docker sietí
    echo -e "\n== Docker siete =="
    docker network ls
    docker network inspect ddns_net
    
    # Kontrola pripojení
    echo -e "\n== Aktívne pripojenia =="
    netstat -tulpn | grep -E "docker|pdns|nginx"
    
    # Kontrola DNS
    echo -e "\n== DNS test =="
    for domain in ${EXAMPLE_DOMAIN} www.${EXAMPLE_DOMAIN}; do
        echo "Test pre $domain:"
        dig @localhost $domain
        echo "---"
    done
    
    # Test HTTPS
    echo -e "\n== HTTPS test =="
    for domain in ${EXAMPLE_DOMAIN} www.${EXAMPLE_DOMAIN}; do
        echo "Test pre $domain:"
        curl -sIL https://$domain | grep -E "HTTP|SSL|Server"
        echo "---"
    done
    
    # Štatistiky siete
    echo -e "\n== Sieťové štatistiky =="
    iftop -t -s 5 2>/dev/null
}

# Funkcia pre reset siete
reset_network() {
    echo "=== Reset sieťových nastavení ==="
    
    # Zastavenie služieb
    docker-compose down
    docker-compose -f npm-compose.yml down
    
    # Odstránenie Docker sietí
    docker network rm ddns_net || true
    
    # Vytvorenie novej siete
    docker network create ddns_net
    
    # Reštart služieb
    docker-compose up -d
    docker-compose -f npm-compose.yml up -d
    
    log_message "Sieťové nastavenia boli resetované"
    echo "Sieť bola resetovaná"
}

# Funkcia pre monitoring siete
monitor_network() {
    local duration=${1:-300}  # predvolené 5 minút
    
    echo "=== Monitoring siete (${duration}s) ==="
    
    # Spustenie monitoringu
    {
        echo "Čas začiatku: $(date)"
        echo
        
        echo "== Sieťové pripojenia =="
        watch -n 10 "netstat -tulpn | grep -E 'docker|pdns|nginx'" &
        WATCH_PID=$!
        
        echo "== Sieťová prevádzka =="
        iftop -t -s $duration
        
        kill $WATCH_PID
        
        echo
        echo "Čas ukončenia: $(date)"
    } | tee "${LOG_DIR}/network_monitor_$(date +%Y%m%d_%H%M%S).log"
}

# Funkcia pre diagnostiku
diagnose_network() {
    echo "=== Sieťová diagnostika ==="
    
    # Test konektivity
    echo -e "\n== Test konektivity =="
    for service in pdns web db npm; do
        echo "Test $service:"
        docker-compose exec -T $service ping -c 3 1.1.1.1
    done
    
    # Test DNS resolvovania
    echo -e "\n== Test DNS =="
    for domain in ${EXAMPLE_DOMAIN} www.${EXAMPLE_DOMAIN}; do
        echo "Test $domain:"
        dig +trace $domain
    done
    
    # Test portov
    echo -e "\n== Test portov =="
    for port in ${PORTS_HTTP} ${PORTS_HTTPS} ${PORTS_DNS_TCP} ${PORTS_DNS_UDP}; do
        echo "Test port $port:"
        nc -zv localhost $port
    done
    
    log_message "Sieťová diagnostika dokončená"
}

# Spracovanie parametrov
case "$1" in
    check)
        check_network
        ;;
    reset)
        reset_network
        ;;
    monitor)
        monitor_network "$2"
        ;;
    diagnose)
        diagnose_network
        ;;
    *)
        echo "Použitie: $0 {check|reset|monitor|diagnose} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 reset"
        echo "  $0 monitor [seconds]"
        echo "  $0 diagnose"
        exit 1
esac

