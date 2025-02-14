#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/security.log
}

# Funkcia pre kontrolu zabezpečenia
check_security() {
    echo "=== Kontrola zabezpečenia ==="
    
    # Firewall
    echo -e "\n== Firewall status =="
    ufw status verbose
    
    # Fail2ban
    echo -e "\n== Fail2ban status =="
    fail2ban-client status
    
    # SSL certifikáty
    echo -e "\n== SSL certifikáty =="
    for domain in $(docker-compose exec -T db mysql -N -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} -e "SELECT name FROM domains"); do
        echo "Kontrola $domain:"
        ./manage-ssl.sh check "$domain"
    done
    
    # Docker zabezpečenie
    echo -e "\n== Docker zabezpečenie =="
    docker info | grep -E "Security|Swarm"
    
    # Oprávnenia súborov
    echo -e "\n== Oprávnenia súborov =="
    ls -la ${BASE_DIR}
    ls -la ${CONFIG_DIR}
    
    # Aktívne porty
    echo -e "\n== Otvorené porty =="
    netstat -tulpn | grep LISTEN
}

# Funkcia pre hardening systému
harden_system() {
    echo "=== Aplikujem bezpečnostné nastavenia ==="
    
    # Firewall pravidlá
    echo -e "\n== Konfigurujem firewall =="
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 53/tcp
    ufw allow 53/udp
    ufw --force enable
    
    # Fail2ban konfigurácia
    echo -e "\n== Konfigurujem Fail2ban =="
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true

[ddns-api]
enabled = true
port = http,https
filter = ddns-api
logpath = ${LOG_DIR}/api.log
maxretry = 5
EOF
    
    systemctl restart fail2ban
    
    # Docker zabezpečenie
    echo -e "\n== Zabezpečujem Docker =="
    chmod 660 /var/run/docker.sock
    
    # Oprávnenia súborov
    echo -e "\n== Nastavujem oprávnenia súborov =="
    chmod 700 ${CONFIG_DIR}
    chmod 600 ${BASE_DIR}/.env
    chmod 644 ${LOG_DIR}/*.log
    
    # SSL konfigurácia
    echo -e "\n== Optimalizujem SSL konfiguráciu =="
    docker-compose exec -T web bash -c '
        sed -i "s/SSLProtocol.*/SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1/" /etc/apache2/mods-available/ssl.conf
        sed -i "s/SSLCipherSuite.*/SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384/" /etc/apache2/mods-available/ssl.conf
        apache2ctl graceful
    '
    
    log_message "Systém bol zabezpečený"
    echo "Bezpečnostné nastavenia boli aplikované"
}

# Funkcia pre audit zabezpečenia
audit_security() {
    local output_file="${LOG_DIR}/security_audit_$(date +%Y%m%d_%H%M%S).log"
    
    echo "=== Bezpečnostný audit ===" | tee "$output_file"
    
    # Systémové informácie
    {
        echo -e "\n== Systémové informácie =="
        uname -a
        lsb_release -a
        
        echo -e "\n== Používatelia a skupiny =="
        cat /etc/passwd
        cat /etc/group
        
        echo -e "\n== Sudo konfigurácia =="
        cat /etc/sudoers
        
        echo -e "\n== Sieťové spojenia =="
        netstat -tulpn
        
        echo -e "\n== Procesy =="
        ps aux
        
        echo -e "\n== Inštalované balíčky =="
        dpkg -l
        
        echo -e "\n== Docker konfigurácia =="
        docker info
        docker ps -a
        
        echo -e "\n== Fail2ban logy =="
        tail -n 1000 /var/log/fail2ban.log
        
        echo -e "\n== Systémové logy =="
        tail -n 1000 /var/log/syslog
        tail -n 1000 /var/log/auth.log
    } >> "$output_file"
    
    log_message "Vykonaný bezpečnostný audit: $output_file"
    echo "Audit bol dokončený. Výsledky: $output_file"
}

# Funkcia pre správu prístupových práv
manage_access() {
    local action=$1
    local target=$2
    local rights=$3
    
    case $action in
        grant)
            chmod $rights "$target"
            log_message "Pridelené práva $rights pre: $target"
            echo "Práva boli pridelené"
            ;;
            
        revoke)
            chmod 000 "$target"
            log_message "Odobraté práva pre: $target"
            echo "Práva boli odobraté"
            ;;
            
        check)
            ls -la "$target"
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
        check_security
        ;;
    harden)
        harden_system
        ;;
    audit)
        audit_security
        ;;
    access)
        manage_access "$2" "$3" "$4"
        ;;
    *)
        echo "Použitie: $0 {check|harden|audit|access} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 harden"
        echo "  $0 audit"
        echo "  $0 access {grant|revoke|check} target [rights]"
        exit 1
esac

