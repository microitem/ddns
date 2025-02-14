#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/config.log
}

# Funkcia pre zálohu konfigurácie
backup_config() {
    local backup_dir="${BACKUP_DIR}/config_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Záloha všetkých konfiguračných súborov
    cp -r ${CONFIG_DIR}/* "$backup_dir/"
    cp .env "$backup_dir/"
    
    # Vytvorenie archívu
    tar -czf "${backup_dir}.tar.gz" -C "${BACKUP_DIR}" "$(basename $backup_dir)"
    rm -rf "$backup_dir"
    
    log_message "Konfigurácia zálohovaná do: ${backup_dir}.tar.gz"
    echo "Konfigurácia bola zálohovaná"
}

# Funkcia pre obnovu konfigurácie
restore_config() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        echo "Záloha neexistuje: $backup_file"
        exit 1
    fi
    
    echo "!!! VAROVANIE !!!"
    echo "Táto operácia prepíše existujúcu konfiguráciu!"
    read -p "Pokračovať? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    # Dočasný adresár pre obnovu
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Obnova konfigurácie
    cp -r "$temp_dir"/*/* ${CONFIG_DIR}/
    if [ -f "$temp_dir"/*/.env ]; then
        cp "$temp_dir"/*/.env .env
    fi
    
    rm -rf "$temp_dir"
    
    log_message "Konfigurácia obnovená zo zálohy: $backup_file"
    echo "Konfigurácia bola obnovená"
    
    # Reštart služieb
    docker-compose restart
    docker-compose -f npm-compose.yml restart
}

# Funkcia pre úpravu konfigurácie
edit_config() {
    local file=$1
    local editor=${EDITOR:-nano}
    
    case $file in
        env)
            $editor .env
            ;;
        pdns)
            $editor ${CONFIG_DIR}/pdns/pdns.conf
            ;;
        web)
            $editor ${CONFIG_DIR}/apache/apache2.conf
            ;;
        php)
            $editor ${CONFIG_DIR}/php/php.ini
            ;;
        npm)
            $editor ${CONFIG_DIR}/npm/nginx.conf
            ;;
        *)
            echo "Neznámy konfiguračný súbor: $file"
            exit 1
            ;;
    esac
    
    log_message "Upravená konfigurácia: $file"
    echo "Konfigurácia bola upravená"
    
    # Opätovné načítanie konfigurácie
    case $file in
        env)
            source .env
            ;;
        pdns)
            docker-compose restart pdns
            ;;
        web)
            docker-compose restart web
            ;;
        php)
            docker-compose restart web
            ;;
        npm)
            docker-compose -f npm-compose.yml restart npm
            ;;
    esac
}

# Funkcia pre kontrolu konfigurácie
check_config() {
    echo "=== Kontrola konfigurácie ==="
    
    # Kontrola .env
    echo -e "\n== Premenné prostredia =="
    if [ -f .env ]; then
        echo "OK: .env existuje"
        source .env
        env | grep -E "^(MYSQL|PDNS|API|DOMAIN)"
    else
        echo "CHYBA: .env chýba"
    fi
    
    # Kontrola konfiguračných súborov
    echo -e "\n== Konfiguračné súbory =="
    for dir in pdns apache php npm; do
        echo "Kontrola $dir:"
        ls -l ${CONFIG_DIR}/$dir/
    done
    
    # Test konfigurácie
    echo -e "\n== Test konfigurácie =="
    docker-compose config -q && echo "OK: docker-compose konfigurácia"
    docker-compose -f npm-compose.yml config -q && echo "OK: npm-compose konfigurácia"
}

# Spracovanie parametrov
case "$1" in
    backup)
        backup_config
        ;;
    restore)
        restore_config "$2"
        ;;
    edit)
        edit_config "$2"
        ;;
    check)
        check_config
        ;;
    *)
        echo "Použitie: $0 {backup|restore|edit|check} [parametre]"
        echo "Príklady:"
        echo "  $0 backup"
        echo "  $0 restore backup_file.tar.gz"
        echo "  $0 edit {env|pdns|web|php|npm}"
        echo "  $0 check"
        exit 1
esac

