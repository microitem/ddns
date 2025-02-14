#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/security.log
}

# Funkcia pre kontrolu zabezpečenia
check_security() {
    echo "=== Kontrola zabezpečenia systému ==="
    
    # Kontrola firewallu
    echo -e "\n== Firewall =="
    ufw status verbose
    
    # Kontrola fail2ban
    echo -e "\n== Fail2ban =="
    fail2ban-client status
    
    # Kontrola SSL
    echo -e "\n== SSL Certifikáty =="
    for domain in $(docker-compose -f npm-compose.yml exec -T npm ls /etc/letsencrypt/live/); do
        echo "Certifikát pre $domain:"
        docker-compose -f npm-compose.yml exec -T npm openssl x509 -noout -dates -issuer -subject \
            -in /etc/letsencrypt/live/$domain/cert.pem
    done
    
    # Kontrola práv súborov
    echo -e "\n== Súborové práva =="
    find ${CONFIG_DIR} ${LOG_DIR} -type f -ls
    
    # Kontrola Docker zabezpečenia
    echo -e "\n== Docker zabezpečenie =="
    docker info | grep -i "security"
    
    # Kontrola otvorených portov
    echo -e "\n== Otvorené porty =="
    netstat -tulpn
    
    # Kontrola systémových aktualizácií
    echo -e "\n== Systémové aktualizácie =="
    apt list --upgradable
}

# Funkcia pre hardening systému
harden_system() {
    echo "=== Aplikujem bezpečnostné nastavenia ==="
    
    # Nastavenie firewallu
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ${PORTS_SSH}/tcp
    ufw allow ${PORTS_HTTP}/tcp
    ufw allow ${PORTS_HTTPS}/tcp
    ufw allow ${PORTS_DNS_TCP}/tcp
    ufw allow ${PORTS_DNS_UDP}/udp
    ufw --force enable
    
    # Konfigurácia fail2ban
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ${ALLOWED_IP_RANGES}

[sshd]
enabled = true
port = ${PORTS_SSH}

[ddns-api]
enabled = true
port = ${PORTS_HTTP},${PORTS_HTTPS}
filter = ddns-api
logpath = ${LOG_DIR}/api.log
maxretry = 5
EOF
    
    systemctl restart fail2ban
    
    # Nastavenie práv súborov
    chmod 600 ${CONFIG_DIR}/*.conf
    chmod 644 ${LOG_DIR}/*.log
    
    # Aktualizácia systému
    apt update && apt upgrade -y
    
    log_message "Systém bol zabezpečený"
    echo "Bezpečnostné nastavenia boli aplikované"
}

# Funkcia pre audit
security_audit() {
    local audit_file="${LOG_DIR}/security_audit_$(date +%Y%m%d).txt"
    
    {
        echo "=== Bezpečnostný audit $(date) ==="
        echo
        check_security
        
        echo -e "\n=== Kontrola logov ==="
        echo "Posledné neúspešné pokusy o prihlásenie:"
        grep "Failed password" /var/log/auth.log | tail -10
        
        echo -e "\nPosledné blokované IP adresy:"
        fail2ban-client status sshd | grep "Banned IP list"
        
        echo -e "\nNeobvyklé systémové udalosti:"
        grep -i "error\|warning\|fail" ${LOG_DIR}/*.log | tail -20
    } > "$audit_file"
    
    log_message "Bezpečnostný audit vygenerovaný: $audit_file"
    echo "Audit bol vygenerovaný do: $audit_file"
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
        security_audit
        ;;
    *)
        echo "Použitie: $0 {check|harden|audit}"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 harden"
        echo "  $0 audit"
        exit 1
esac

