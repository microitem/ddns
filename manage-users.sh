#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/users.log
}

# Funkcia pre generovanie hesla
generate_password() {
    openssl rand -base64 12 | tr -d '/+=' | cut -c1-12
}

# Funkcia pre pridanie používateľa
add_user() {
    local username=$1
    local domain=$2
    local password=${3:-$(generate_password)}
    
    # Kontrola existencie používateľa
    if docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT 1 FROM users WHERE username='$username' LIMIT 1" | grep -q 1; then
        echo "Používateľ už existuje: $username"
        exit 1
    fi
    
    # Pridanie používateľa
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "INSERT INTO users (username, domain, password, created_at) VALUES ('$username', '$domain', '$password', NOW())"
    
    if [ $? -eq 0 ]; then
        log_message "Pridaný používateľ: $username ($domain)"
        echo "Používateľ bol pridaný:"
        echo "Username: $username"
        echo "Domain: $domain"
        echo "Password: $password"
    else
        echo "Chyba pri pridávaní používateľa"
    fi
}

# Funkcia pre odstránenie používateľa
remove_user() {
    local username=$1
    
    # Kontrola existencie používateľa
    if ! docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT 1 FROM users WHERE username='$username' LIMIT 1" | grep -q 1; then
        echo "Používateľ neexistuje: $username"
        exit 1
    fi
    
    # Odstránenie používateľa
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "DELETE FROM users WHERE username='$username'"
    
    if [ $? -eq 0 ]; then
        log_message "Odstránený používateľ: $username"
        echo "Používateľ bol odstránený"
    else
        echo "Chyba pri odstraňovaní používateľa"
    fi
}

# Funkcia pre zmenu hesla
change_password() {
    local username=$1
    local password=${2:-$(generate_password)}
    
    # Zmena hesla
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "UPDATE users SET password='$password', updated_at=NOW() WHERE username='$username'"
    
    if [ $? -eq 0 ]; then
        log_message "Zmenené heslo pre: $username"
        echo "Heslo bolo zmenené:"
        echo "Username: $username"
        echo "New password: $password"
    else
        echo "Chyba pri zmene hesla"
    fi
}

# Funkcia pre výpis používateľov
list_users() {
    echo "=== Zoznam používateľov ==="
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT username, domain, created_at, updated_at, last_login FROM users"
}

# Funkcia pre správu oprávnení
manage_permissions() {
    local action=$1
    local username=$2
    local permission=$3
    
    case $action in
        grant)
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "INSERT INTO user_permissions (username, permission) VALUES ('$username', '$permission')"
            
            log_message "Pridané oprávnenie $permission pre: $username"
            echo "Oprávnenie bolo pridané"
            ;;
            
        revoke)
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "DELETE FROM user_permissions WHERE username='$username' AND permission='$permission'"
            
            log_message "Odobrané oprávnenie $permission pre: $username"
            echo "Oprávnenie bolo odobrané"
            ;;
            
        list)
            echo "Oprávnenia pre $username:"
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "SELECT permission FROM user_permissions WHERE username='$username'"
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Spracovanie parametrov
case "$1" in
    add)
        add_user "$2" "$3" "$4"
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
    permissions)
        manage_permissions "$2" "$3" "$4"
        ;;
    *)
        echo "Použitie: $0 {add|remove|password|list|permissions} [parametre]"
        echo "Príklady:"
        echo "  $0 add username domain [password]"
        echo "  $0 remove username"
        echo "  $0 password username [new-password]"
        echo "  $0 list"
        echo "  $0 permissions {grant|revoke|list} username [permission]"
        exit 1
esac

