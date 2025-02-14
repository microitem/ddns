#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/dns.log
}

# Funkcia pre pridanie DNS záznamu
add_record() {
    local name=$1
    local type=$2
    local content=$3
    local ttl=${4:-3600}
    
    docker-compose exec -T pdns pdnsutil add-record ${EXAMPLE_DOMAIN} "$name" "$type" "$ttl" "$content"
    
    if [ $? -eq 0 ]; then
        log_message "Pridaný DNS záznam: $name $type $content"
        echo "DNS záznam bol pridaný"
    else
        log_message "Chyba pri pridávaní DNS záznamu: $name"
        echo "Chyba pri pridávaní záznamu"
    fi
}

# Funkcia pre odstránenie DNS záznamu
remove_record() {
    local name=$1
    local type=$2
    
    docker-compose exec -T pdns pdnsutil delete-rrset ${EXAMPLE_DOMAIN} "$name" "$type"
    
    if [ $? -eq 0 ]; then
        log_message "Odstránený DNS záznam: $name $type"
        echo "DNS záznam bol odstránený"
    else
        log_message "Chyba pri odstraňovaní DNS záznamu: $name"
        echo "Chyba pri odstraňovaní záznamu"
    fi
}

# Funkcia pre výpis DNS záznamov
list_records() {
    echo "Zoznam DNS záznamov:"
    docker-compose exec -T pdns pdnsutil list-zone ${EXAMPLE_DOMAIN}
}

# Funkcia pre export zóny
export_zone() {
    local output_file="${BACKUP_DIR}/zone_${EXAMPLE_DOMAIN}_$(date +%Y%m%d).txt"
    docker-compose exec -T pdns pdnsutil list-zone ${EXAMPLE_DOMAIN} > "$output_file"
    
    if [ $? -eq 0 ]; then
        log_message "Zóna exportovaná do: $output_file"
        echo "Zóna bola exportovaná do: $output_file"
    else
        log_message "Chyba pri exporte zóny"
        echo "Chyba pri exporte zóny"
    fi
}

# Funkcia pre kontrolu zóny
check_zone() {
    echo "Kontrola zóny ${EXAMPLE_DOMAIN}:"
    docker-compose exec -T pdns pdnsutil check-zone ${EXAMPLE_DOMAIN}
}

# Spracovanie parametrov
case "$1" in
    add)
        add_record "$2" "$3" "$4" "$5"
        ;;
    remove)
        remove_record "$2" "$3"
        ;;
    list)
        list_records
        ;;
    export)
        export_zone
        ;;
    check)
        check_zone
        ;;
    *)
        echo "Použitie: $0 {add|remove|list|export|check} [parametre]"
        echo "Príklady:"
        echo "  $0 add subdomain A 192.168.1.1 [ttl]"
        echo "  $0 remove subdomain A"
        echo "  $0 list"
        echo "  $0 export"
        echo "  $0 check"
        exit 1
esac

