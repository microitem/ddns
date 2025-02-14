#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/db.log
}

# Funkcia pre zálohu databázy
backup_db() {
    local backup_file="${BACKUP_DIR}/db_$(date +%Y%m%d_%H%M%S).sql.gz"
    
    echo "=== Zálohujem databázu ==="
    
    docker-compose exec -T db mysqldump \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        ${MYSQL_DATABASE} | gzip > "$backup_file"
    
    if [ $? -eq 0 ]; then
        log_message "Databáza zálohovaná do: $backup_file"
        echo "Záloha bola vytvorená: $backup_file"
    else
        log_message "Chyba pri zálohovaní databázy"
        echo "Chyba pri vytváraní zálohy"
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
    
    echo "=== Obnovujem databázu ==="
    
    gunzip < "$backup_file" | docker-compose exec -T db mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        ${MYSQL_DATABASE}
    
    if [ $? -eq 0 ]; then
        log_message "Databáza obnovená zo zálohy: $backup_file"
        echo "Databáza bola obnovená"
    else
        log_message "Chyba pri obnove databázy"
        echo "Chyba pri obnove"
        exit 1
    fi
}

# Funkcia pre optimalizáciu databázy
optimize_db() {
    echo "=== Optimalizujem databázu ==="
    
    # Analýza tabuliek
    docker-compose exec -T db mysqlcheck \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        --analyze \
        ${MYSQL_DATABASE}
    
    # Optimalizácia tabuliek
    docker-compose exec -T db mysqlcheck \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        --optimize \
        ${MYSQL_DATABASE}
    
    log_message "Databáza bola optimalizovaná"
    echo "Optimalizácia dokončená"
}

# Funkcia pre kontrolu databázy
check_db() {
    echo "=== Kontrola databázy ==="
    
    # Kontrola integrity
    echo -e "\n== Kontrola integrity =="
    docker-compose exec -T db mysqlcheck \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        --check \
        ${MYSQL_DATABASE}
    
    # Štatistiky
    echo -e "\n== Štatistiky =="
    docker-compose exec -T db mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        -e "SHOW TABLE STATUS FROM ${MYSQL_DATABASE}"
    
    # Procesy
    echo -e "\n== Aktívne procesy =="
    docker-compose exec -T db mysql \
        -u${MYSQL_USER} \
        -p${MYSQL_PASSWORD} \
        -e "SHOW PROCESSLIST"
}

# Funkcia pre správu tabuliek
manage_tables() {
    local action=$1
    local table=$2
    
    case $action in
        create)
            if [ ! -f "sql/${table}.sql" ]; then
                echo "SQL súbor neexistuje: sql/${table}.sql"
                exit 1
            fi
            
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                ${MYSQL_DATABASE} < "sql/${table}.sql"
            
            log_message "Vytvorená tabuľka: $table"
            echo "Tabuľka bola vytvorená"
            ;;
            
        drop)
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                ${MYSQL_DATABASE} \
                -e "DROP TABLE IF EXISTS $table"
            
            log_message "Odstránená tabuľka: $table"
            echo "Tabuľka bola odstránená"
            ;;
            
        truncate)
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                ${MYSQL_DATABASE} \
                -e "TRUNCATE TABLE $table"
            
            log_message "Vyčistená tabuľka: $table"
            echo "Tabuľka bola vyčistená"
            ;;
            
        describe)
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                ${MYSQL_DATABASE} \
                -e "DESCRIBE $table"
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Funkcia pre správu používateľov DB
manage_db_users() {
    local action=$1
    local username=$2
    local password=$3
    
    case $action in
        create)
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                -e "CREATE USER '$username'@'%' IDENTIFIED BY '$password'"
            
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                -e "GRANT SELECT, INSERT, UPDATE, DELETE ON ${MYSQL_DATABASE}.* TO '$username'@'%'"
            
            log_message "Vytvorený DB používateľ: $username"
            echo "Používateľ bol vytvorený"
            ;;
            
        drop)
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                -e "DROP USER IF EXISTS '$username'@'%'"
            
            log_message "Odstránený DB používateľ: $username"
            echo "Používateľ bol odstránený"
            ;;
            
        list)
            docker-compose exec -T db mysql \
                -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                -e "SELECT user, host FROM mysql.user"
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
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
    tables)
        manage_tables "$2" "$3"
        ;;
    users)
        manage_db_users "$2" "$3" "$4"
        ;;
    *)
        echo "Použitie: $0 {backup|restore|optimize|check|tables|users} [parametre]"
        echo "Príklady:"
        echo "  $0 backup"
        echo "  $0 restore backup_file"
        echo "  $0 optimize"
        echo "  $0 check"
        echo "  $0 tables {create|drop|truncate|describe} table"
        echo "  $0 users {create|drop|list} username [password]"
        exit 1
esac

