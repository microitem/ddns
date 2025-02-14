#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/domains.log
}

# Funkcia pre pridanie domény
add_domain() {
    local domain=$1
    local owner=$2
    local ip=${3:-${DEFAULT_IP}}
    
    # Kontrola existencie domény
    if docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT 1 FROM domains WHERE name='$domain' LIMIT 1" | grep -q 1; then
        echo "Doména už existuje: $domain"
        exit 1
    fi
    
    # Pridanie domény do databázy
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "INSERT INTO domains (name, owner, created_at) VALUES ('$domain', '$owner', NOW())"
    
    # Vytvorenie DNS záznamov
    docker-compose exec -T pdns pdnsutil create-zone "$domain"
    docker-compose exec -T pdns pdnsutil add-record "$domain" "" A "300" "$ip"
    docker-compose exec -T pdns pdnsutil add-record "$domain" "www" A "300" "$ip"
    
    # Vytvorenie virtuálneho hosta
    ./manage-web.sh vhost add "$domain"
    
    # Vytvorenie SSL certifikátu
    ./manage-ssl.sh create "$domain"
    
    log_message "Pridaná doména: $domain ($owner)"
    echo "Doména bola pridaná"
}

# Funkcia pre odstránenie domény
remove_domain() {
    local domain=$1
    
    # Kontrola existencie domény
    if ! docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT 1 FROM domains WHERE name='$domain' LIMIT 1" | grep -q 1; then
        echo "Doména neexistuje: $domain"
        exit 1
    fi
    
    # Odstránenie z databázy
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "DELETE FROM domains WHERE name='$domain'"
    
    # Odstránenie DNS záznamov
    docker-compose exec -T pdns pdnsutil delete-zone "$domain"
    
    # Odstránenie virtuálneho hosta
    ./manage-web.sh vhost remove "$domain"
    
    log_message "Odstránená doména: $domain"
    echo "Doména bola odstránená"
}

# Funkcia pre výpis domén
list_domains() {
    echo "=== Zoznam domén ==="
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT name, owner, created_at, updated_at FROM domains"
}

# Funkcia pre kontrolu domény
check_domain() {
    local domain=$1
    
    echo "=== Kontrola domény $domain ==="
    
    # DNS záznamy
    echo -e "\n== DNS záznamy =="
    docker-compose exec -T pdns pdnsutil list-zone "$domain"
    
    # SSL certifikát
    echo -e "\n== SSL certifikát =="
    ./manage-ssl.sh check "$domain"
    
    # Web server
    echo -e "\n== Web server =="
    curl -sI "https://$domain" | head -n1
    
    # Štatistiky
    echo -e "\n== Štatistiky =="
    echo "DNS požiadavky:"
    docker-compose exec -T pdns pdns_control show-zone "$domain"
}

# Funkcia pre aktualizáciu domény
update_domain() {
    local domain=$1
    local field=$2
    local value=$3
    
    case $field in
        owner)
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "UPDATE domains SET owner='$value', updated_at=NOW() WHERE name='$domain'"
            ;;
        ip)
            docker-compose exec -T pdns pdnsutil delete-rrset "$domain" "" A
            docker-compose exec -T pdns pdnsutil add-record "$domain" "" A "300" "$value"
            docker-compose exec -T pdns pdnsutil delete-rrset "$domain" "www" A
            docker-compose exec -T pdns pdnsutil add-record "$domain" "www" A "300" "$value"
            ;;
        *)
            echo "Neznáme pole: $field"
            exit 1
            ;;
    esac
    
    log_message "Aktualizovaná doména $domain: $field = $value"
    echo "Doména bola aktualizovaná"
}

# Spracovanie parametrov
case "$1" in
    add)
        add_domain "$2" "$3" "$4"
        ;;
    remove)
        remove_domain "$2"
        ;;
    list)
        list_domains
        ;;
    check)
        check_domain "$2"
        ;;
    update)
        update_domain "$2" "$3" "$4"
        ;;
    *)
        echo "Použitie: $0 {add|remove|list|check|update} [parametre]"
        echo "Príklady:"
        echo "  $0 add domain owner [ip]"
        echo "  $0 remove domain"
        echo "  $0 list"
        echo "  $0 check domain"
        echo "  $0 update domain {owner|ip} value"
        exit 1
esac

