#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/backup.log
}

# Funkcia pre vytvorenie zálohy
create_backup() {
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_dir="${BACKUP_DIR}/${backup_name}"
    local backup_file="${BACKUP_DIR}/${backup_name}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    # Záloha konfigurácie
    cp -r ${CONFIG_DIR}/* "${backup_dir}/config/"
    
    # Záloha databázy
    docker-compose exec -T db mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > "${backup_dir}/database.sql"
    
    # Záloha DNS zón
    docker-compose exec -T pdns pdns_control list-zones > "${backup_dir}/dns_zones.txt"
    
    # Záloha SSL certifikátov
    docker-compose -f npm-compose.yml cp npm:/etc/letsencrypt "${backup_dir}/ssl/"
    
    # Záloha logov
    cp -r ${LOG_DIR}/* "${backup_dir}/logs/"
    
    # Vytvorenie archívu
    tar -czf "$backup_file" -C "${BACKUP_DIR}" "$backup_name"
    rm -rf "$backup_dir"
    
    log_message "Vytvorená záloha: $backup_file"
    echo "Záloha bola vytvorená: $backup_file"
}

# Funkcia pre výpis záloh
list_backups() {
    echo "Dostupné zálohy:"
    ls -lh ${BACKUP_DIR}/*.tar.gz 2>/dev/null || echo "Žiadne zálohy nenájdené"
}

# Funkcia pre kontrolu zálohy
verify_backup() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        echo "Záloha neexistuje: $backup_file"
        return 1
    fi
    
    echo "Kontrola zálohy: $backup_file"
    
    # Kontrola integrity archívu
    if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
        echo "Chyba: Poškodený archív"
        return 1
    fi
    
    # Rozbalenie do dočasného adresára
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Kontrola obsahu
    echo "Obsah zálohy:"
    echo "- Konfigurácia: $(ls -A $temp_dir/*/config/ 2>/dev/null | wc -l) súborov"
    echo "- Databáza: $(du -h $temp_dir/*/database.sql 2>/dev/null | cut -f1) veľkosť"
    echo "- DNS zóny: $(wc -l < $temp_dir/*/dns_zones.txt 2>/dev/null || echo "0") zón"
    echo "- SSL certifikáty: $(ls -A $temp_dir/*/ssl/live/ 2>/dev/null | wc -l) certifikátov"
    echo "- Logy: $(ls -A $temp_dir/*/logs/ 2>/dev/null | wc -l) súborov"
    
    rm -rf "$temp_dir"
    echo "Kontrola dokončená"
}

# Funkcia pre čistenie starých záloh
cleanup_backups() {
    local days=${1:-30}
    
    echo "Odstraňujem zálohy staršie ako $days dní"
    find ${BACKUP_DIR} -name "backup_*.tar.gz" -mtime +$days -delete
    
    log_message "Vyčistené zálohy staršie ako $days dní"
    echo "Čistenie dokončené"
}

# Spracovanie parametrov
case "$1" in
    create)
        create_backup
        ;;
    list)
        list_backups
        ;;
    verify)
        verify_backup "$2"
        ;;
    cleanup)
        cleanup_backups "$2"
        ;;
    *)
        echo "Použitie: $0 {create|list|verify|cleanup} [parametre]"
        echo "Príklady:"
        echo "  $0 create"
        echo "  $0 list"
        echo "  $0 verify backup_file.tar.gz"
        echo "  $0 cleanup [days]"
        exit 1
esac

