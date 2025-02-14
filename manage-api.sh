#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/api.log
}

# Funkcia pre kontrolu API
check_api() {
    echo "=== Kontrola API ==="
    
    # Test dostupnosti
    echo -e "\n== API dostupnosť =="
    curl -sI "http://localhost${API_ENDPOINT}" | head -n1
    
    # Test autentifikácie
    echo -e "\n== Test autentifikácie =="
    curl -s "http://localhost${API_ENDPOINT}?hostname=test.com" | grep "BADAUTH"
    
    # Štatistiky prístupov
    echo -e "\n== API štatistiky =="
    echo "Počet požiadaviek za posledných 24 hodín:"
    grep "$(date +%Y-%m-%d)" ${LOG_DIR}/api.log | wc -l
    
    echo -e "\nTop 10 IP adries:"
    grep "$(date +%Y-%m-%d)" ${LOG_DIR}/api.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
}

# Funkcia pre testovanie API
test_api() {
    local domain=$1
    local password=$2
    local ip=${3:-""}
    
    echo "=== Test API ==="
    echo "Domain: $domain"
    echo "Password: $password"
    echo "IP: ${ip:-'auto'}"
    
    # Vytvorenie URL
    local url="http://localhost${API_ENDPOINT}?hostname=${domain}&password=${password}"
    if [ ! -z "$ip" ]; then
        url="${url}&ip=${ip}"
    fi
    
    # Test požiadavky
    echo -e "\n== API odpoveď =="
    curl -s "$url"
    echo
}

# Funkcia pre generovanie API kľúča
generate_key() {
    local domain=$1
    local key=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)
    
    # Uloženie kľúča do databázy
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "INSERT INTO api_keys (domain, api_key, created_at) VALUES ('$domain', '$key', NOW())"
    
    if [ $? -eq 0 ]; then
        log_message "Vygenerovaný API kľúč pre: ${domain}"
        echo "API kľúč bol vygenerovaný:"
        echo "Domain: $domain"
        echo "Key: $key"
    else
        echo "Chyba pri generovaní API kľúča"
    fi
}

# Funkcia pre správu limitov
manage_limits() {
    local action=$1
    local domain=$2
    local limit=$3
    
    case $action in
        set)
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "UPDATE api_limits SET requests_per_day=$limit WHERE domain='$domain'"
            
            log_message "Nastavený limit pre ${domain}: ${limit} požiadaviek/deň"
            echo "Limit bol nastavený"
            ;;
            
        show)
            echo "Limity API:"
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "SELECT domain, requests_per_day, current_requests FROM api_limits"
            ;;
            
        reset)
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "UPDATE api_limits SET current_requests=0"
            
            log_message "Resetované počítadlá limitov"
            echo "Limity boli resetované"
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Spracovanie parametrov
case "$1" in
    check)
        check_api
        ;;
    test)
        test_api "$2" "$3" "$4"
        ;;
    key)
        generate_key "$2"
        ;;
    limits)
        manage_limits "$2" "$3" "$4"
        ;;
    *)
        echo "Použitie: $0 {check|test|key|limits} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 test domain password [ip]"
        echo "  $0 key domain"
        echo "  $0 limits {set|show|reset} [domain] [limit]"
        exit 1
esac

