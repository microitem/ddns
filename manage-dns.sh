#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/dns.log
}

# Funkcia pre kontrolu DNS servera
check_dns() {
    echo "=== Kontrola DNS servera ==="
    
    # Kontrola PowerDNS
    echo -e "\n== PowerDNS status =="
    docker-compose exec -T pdns pdns_control status
    
    # Kontrola zón
    echo -e "\n== DNS zóny =="
    docker-compose exec -T pdns pdns_control list-zones
    
    # Test resolvovania
    echo -e "\n== Test DNS =="
    for domain in ${EXAMPLE_DOMAIN} www.${EXAMPLE_DOMAIN}; do
        echo "Test pre $domain:"
        dig @localhost $domain +short
    done
    
    # Štatistiky
    echo -e "\n== DNS štatistiky =="
    docker-compose exec -T pdns pdns_control show "*"
}

# Funkcia pre správu zón
manage_zone() {
    local action=$1
    local domain=$2
    
    case $action in
        add)
            # Vytvorenie zóny
            docker-compose exec -T pdns pdnsutil create-zone "$domain"
            docker-compose exec -T pdns pdnsutil set-kind "$domain" NATIVE
            
            # Pridanie základných záznamov
            docker-compose exec -T pdns pdnsutil add-record "$domain" "" A "300" "${DEFAULT_IP}"
            docker-compose exec -T pdns pdnsutil add-record "$domain" "www" A "300" "${DEFAULT_IP}"
            
            log_message "Pridaná zóna: ${domain}"
            echo "Zóna bola pridaná"
            ;;
            
        remove)
            docker-compose exec -T pdns pdnsutil delete-zone "$domain"
            
            log_message "Odstránená zóna: ${domain}"
            echo "Zóna bola odstránená"
            ;;
            
        list)
            echo "Aktívne zóny:"
            docker-compose exec -T pdns pdns_control list-zones
            ;;
            
        export)
            local export_file="${BACKUP_DIR}/zone_${domain}_$(date +%Y%m%d).txt"
            docker-compose exec -T pdns pdns_control list-zone "$domain" > "$export_file"
            
            echo "Zóna bola exportovaná do: $export_file"
            ;;
            
        import)
            local import_file=$3
            if [ ! -f "$import_file" ]; then
                echo "Súbor neexistuje: $import_file"
                exit 1
            fi
            
            docker-compose exec -T pdns pdnsutil load-zone "$domain" "$import_file"
            
            log_message "Importovaná zóna: ${domain}"
            echo "Zóna bola importovaná"
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Funkcia pre správu záznamov
manage_record() {
    local action=$1
    local domain=$2
    local name=$3
    local type=$4
    local content=$5
    local ttl=${6:-300}
    
    case $action in
        add)
            docker-compose exec -T pdns pdnsutil add-record "$domain" "$name" "$type" "$ttl" "$content"
            
            log_message "Pridaný záznam: ${name}.${domain} ${type} ${content}"
            echo "Záznam bol pridaný"
            ;;
            
        remove)
            docker-compose exec -T pdns pdnsutil delete-rrset "$domain" "$name" "$type"
            
            log_message "Odstránený záznam: ${name}.${domain} ${type}"
            echo "Záznam bol odstránený"
            ;;
            
        list)
            echo "Záznamy pre zónu $domain:"
            docker-compose exec -T pdns pdnsutil list-zone "$domain"
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
        check_dns
        ;;
    zone)
        manage_zone "$2" "$3" "$4"
        ;;
    record)
        manage_record "$2" "$3" "$4" "$5" "$6" "$7"
        ;;
    *)
        echo "Použitie: $0 {check|zone|record} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 zone {add|remove|list|export|import} domain [import_file]"
        echo "  $0 record {add|remove|list} domain name type [content] [ttl]"
        exit 1
esac

