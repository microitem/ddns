#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/db.log
}

# Funkcia pre zálohu databázy
backup_db() {
    local backup_file="${BACKUP_DIR}/db_$(date +%Y%m%d_%H%M%S).sql"
    
    log_message "Vytváram zálohu databázy"
    docker-compose exec -T db mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo "Záloha vytvorená: $backup_file"
        # Kompresia zálohy
        gzip "$backup_file"
        log_message "Záloha bola vytvorená: ${backup_file}.gz"
    else
        echo "Chyba pri vytváraní zálohy"
        log_message "Chyba pri vytváraní zálohy"
        exit 1
    fi
}

# Funkcia pre obnovu databázy
restore_db() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        echo "Záloha neexistuje: $backup_file"
        exit 1
    fi
    
    echo "!!! VAROVANIE !!!"
    echo "Táto operácia prepíše existujúcu databázu!"
    read -p "Pokračovať? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    log_message "Obnovujem databázu zo zálohy: $backup_file"
    
    # Ak je súbor komprimovaný
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
    else
        docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        echo "Databáza bola obnovená"
        log_message "Databáza bola obnovená"
    else
        echo "Chyba pri obnove databázy"
        log_message "Chyba pri obnove databázy"
        exit 1
    fi
}

# Funkcia pre optimalizáciu databázy
optimize_db() {
    log_message "Optimalizujem databázu"
    
    echo "Analyzujem a optimalizujem tabuľky..."
    docker-compose exec -T db mysqlcheck -u${MYSQL_USER} -p${MYSQL_PASSWORD} --auto-repair --optimize ${MYSQL_DATABASE}
    
    echo "Aktualizujem štatistiky..."
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} -e "ANALYZE TABLE users, domains, records"
    
    echo "Databáza bola optimalizovaná"
}

# Funkcia pre kontrolu databázy
check_db() {
    echo "=== Kontrola databázy ==="
    
    echo -e "\n== Stav databázy =="
    docker-compose exec -T db mysqladmin -u${MYSQL_USER} -p${MYSQL_PASSWORD} status
    
    echo -e "\n== Veľkosti tabuliek =="
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT table_name, table_rows, data_length/1024/1024 'Data MB', index_length/1024/1024 'Index MB' 
            FROM information_schema.tables 
            WHERE table_schema='${MYSQL_DATABASE}'"
    
    echo -e "\n== Kontrola integrity =="
    docker-compose exec -T db mysqlcheck -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
}

# Spracovanie parametrov
case "$1" in
    backup)
        backup_db
        ;;
    restore)
        restore_db "$2"
        ;;
    optimize)
        optimize_db
        ;;
    check)
        check_db
        ;;
    *)
        echo "Použitie: $0 {backup|restore|optimize|check} [parametre]"
        echo "Príklady:"
        echo "  $0 backup"
        echo "  $0 restore backup_file.sql[.gz]"
        echo "  $0 optimize"
        echo "  $0 check"
        exit 1
esac

