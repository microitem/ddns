#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/users.log
}

# Funkcia pre generovanie hesla
generate_password() {
    openssl rand -base64 12
}

# Funkcia pre pridanie používateľa
add_user() {
    local domain=$1
    local password=${2:-$(generate_password)}
    
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "INSERT INTO users (domain, password, created_at) VALUES ('$domain', '$password', NOW())"
    
    if [ $? -eq 0 ]; then
        log_message "Pridaný nový používateľ: $domain"
        echo "Používateľ bol pridaný:"
        echo "Domain: $domain"
        echo "Password: $password"
    else
        log_message "Chyba pri pridávaní používateľa: $domain"
        echo "Chyba pri pridávaní používateľa"
    fi
}

# Funkcia pre odstránenie používateľa
remove_user() {
    local domain=$1
    
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "DELETE FROM users WHERE domain='$domain'"
    
    if [ $? -eq 0 ]; then
        log_message "Odstránený používateľ: $domain"
        echo "Používateľ bol odstránený"
    else
        log_message "Chyba pri odstraňovaní používateľa: $domain"
        echo "Chyba pri odstraňovaní používateľa"
    fi
}

# Funkcia pre zmenu hesla
change_password() {
    local domain=$1
    local password=${2:-$(generate_password)}
    
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "UPDATE users SET password='$password' WHERE domain='$domain'"
    
    if [ $? -eq 0 ]; then
        log_message "Zmenené heslo pre: $domain"
        echo "Heslo bolo zmenené:"
        echo "Domain: $domain"
        echo "New password: $password"
    else
        log_message "Chyba pri zmene hesla pre: $domain"
        echo "Chyba pri zmene hesla"
    fi
}

# Funkcia pre výpis používateľov
list_users() {
    echo "Zoznam používateľov:"
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT domain, created_at, last_update FROM users"
}

# Spracovanie parametrov
case "$1" in
    add)
        add_user "$2" "$3"
        ;;
    remove)
        remove_user "$2"
        ;;
    password)
        change_password "$2" "$3"
        ;;
    list)
        list_users
        ;;
    *)
        echo "Použitie: $0 {add|remove|password|list} [domain] [password]"
        echo "Príklady:"
        echo "  $0 add example.com [password]"
        echo "  $0 remove example.com"
        echo "  $0 password example.com [new-password]"
        echo "  $0 list"
        exit 1
esac

