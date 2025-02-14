#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/ssl.log
}

# Funkcia pre kontrolu SSL certifikátu
check_cert() {
    local domain=$1
    echo "Kontrola SSL certifikátu pre $domain:"
    
    # Získanie informácií o certifikáte
    echo "=== Informácie o certifikáte ==="
    echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates -issuer -subject
    
    # Kontrola platnosti
    local expiry=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry" +%s)
    local now_epoch=$(date +%s)
    local days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))
    
    echo "Zostáva dní: $days_left"
    
    if [ $days_left -lt 30 ]; then
        log_message "Upozornenie: Certifikát pre $domain vyprší za $days_left dní"
        echo "!!! Upozornenie: Certifikát čoskoro vyprší !!!"
    fi
}

# Funkcia pre výpis všetkých certifikátov
list_certs() {
    echo "Zoznam SSL certifikátov v NPM:"
    docker-compose -f npm-compose.yml exec npm ls /etc/letsencrypt/live/
}

# Funkcia pre zálohu certifikátov
backup_certs() {
    local backup_dir="${BACKUP_DIR}/ssl_$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    log_message "Zálohujem SSL certifikáty do $backup_dir"
    docker-compose -f npm-compose.yml cp npm:/etc/letsencrypt/live/ "$backup_dir"
    
    if [ $? -eq 0 ]; then
        echo "Certifikáty boli zálohované do: $backup_dir"
        log_message "Záloha certifikátov úspešná"
    else
        echo "Chyba pri zálohovaní certifikátov"
        log_message "Chyba pri zálohovaní certifikátov"
    fi
}

# Funkcia pre vynútenie obnovy certifikátu
force_renew() {
    local domain=$1
    
    log_message "Vynútená obnova certifikátu pre $domain"
    docker-compose -f npm-compose.yml exec npm certbot renew --force-renewal --cert-name $domain
    
    if [ $? -eq 0 ]; then
        echo "Certifikát bol obnovený"
        docker-compose -f npm-compose.yml restart npm
    else
        echo "Chyba pri obnove certifikátu"
        log_message "Chyba pri obnove certifikátu pre $domain"
    fi
}

# Spracovanie parametrov
case "$1" in
    check)
        check_cert "$2"
        ;;
    list)
        list_certs
        ;;
    backup)
        backup_certs
        ;;
    renew)
        force_renew "$2"
        ;;
    *)
        echo "Použitie: $0 {check|list|backup|renew} [domain]"
        echo "Príklady:"
        echo "  $0 check example.com"
        echo "  $0 list"
        echo "  $0 backup"
        echo "  $0 renew example.com"
        exit 1
esac

