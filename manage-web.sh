#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/web.log
}

# Funkcia pre kontrolu webového servera
check_web() {
    echo "=== Kontrola webového servera ==="
    
    # Kontrola Apache
    echo -e "\n== Apache status =="
    docker-compose exec -T web apache2ctl status
    
    # Kontrola PHP
    echo -e "\n== PHP info =="
    docker-compose exec -T web php -v
    docker-compose exec -T web php -m
    
    # Kontrola SSL
    echo -e "\n== SSL status =="
    docker-compose -f npm-compose.yml exec -T npm nginx -t
    
    # Test dostupnosti
    echo -e "\n== Dostupnosť služieb =="
    curl -sI "http://localhost${API_ENDPOINT}" | head -n1
    curl -sI "https://${EXAMPLE_DOMAIN}" | head -n1
}

# Funkcia pre správu virtuálnych hostov
manage_vhost() {
    local action=$1
    local domain=$2
    
    case $action in
        add)
            # Vytvorenie konfigurácie virtualhost
            cat > "${CONFIG_DIR}/apache/sites/${domain}.conf" << EOF
<VirtualHost *:80>
    ServerName ${domain}
    DocumentRoot /var/www/html/${domain}
    ErrorLog \${APACHE_LOG_DIR}/${domain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_access.log combined
    
    <Directory /var/www/html/${domain}>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
            # Vytvorenie adresára pre web
            mkdir -p "${BASE_DIR}/www/${domain}"
            
            # Reštart Apache
            docker-compose exec -T web apache2ctl restart
            
            log_message "Pridaný virtualhost: ${domain}"
            echo "Virtualhost bol pridaný"
            ;;
            
        remove)
            rm -f "${CONFIG_DIR}/apache/sites/${domain}.conf"
            rm -rf "${BASE_DIR}/www/${domain}"
            
            docker-compose exec -T web apache2ctl restart
            
            log_message "Odstránený virtualhost: ${domain}"
            echo "Virtualhost bol odstránený"
            ;;
            
        list)
            echo "Aktívne virtualhosty:"
            ls -1 "${CONFIG_DIR}/apache/sites/"
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Funkcia pre správu SSL certifikátov
manage_ssl() {
    local action=$1
    local domain=$2
    
    case $action in
        create)
            docker-compose -f npm-compose.yml exec -T npm certbot certonly --webroot \
                -w /var/www/html -d "$domain" --email "${ADMIN_EMAIL}" --agree-tos
            
            log_message "Vytvorený SSL certifikát pre: ${domain}"
            echo "SSL certifikát bol vytvorený"
            ;;
            
        renew)
            docker-compose -f npm-compose.yml exec -T npm certbot renew --force-renewal
            
            log_message "Obnovené SSL certifikáty"
            echo "SSL certifikáty boli obnovené"
            ;;
            
        list)
            echo "Aktívne SSL certifikáty:"
            docker-compose -f npm-compose.yml exec -T npm certbot certificates
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Funkcia pre správu PHP
manage_php() {
    local action=$1
    
    case $action in
        config)
            echo "PHP konfigurácia:"
            docker-compose exec -T web php -i
            ;;
            
        modules)
            echo "PHP moduly:"
            docker-compose exec -T web php -m
            ;;
            
        test)
            echo "PHP test:"
            docker-compose exec -T web php -r "phpinfo();"
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
        check_web
        ;;
    vhost)
        manage_vhost "$2" "$3"
        ;;
    ssl)
        manage_ssl "$2" "$3"
        ;;
    php)
        manage_php "$2"
        ;;
    *)
        echo "Použitie: $0 {check|vhost|ssl|php} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 vhost {add|remove|list} domain"
        echo "  $0 ssl {create|renew|list} [domain]"
        echo "  $0 php {config|modules|test}"
        exit 1
esac

