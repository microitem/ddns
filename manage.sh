#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/manage.log
}

# Funkcia pre kontrolu závislostí
check_dependencies() {
    local missing=0
    
    # Kontrola potrebných programov
    for cmd in docker docker-compose curl dig openssl mysql; do
        if ! command -v $cmd &> /dev/null; then
            echo "Chýba príkaz: $cmd"
            missing=1
        fi
    done
    
    # Kontrola konfiguračných súborov
    if [ ! -f .env ]; then
        echo "Chýba súbor: .env"
        missing=1
    fi
    
    # Kontrola skriptov
    for script in manage-users.sh manage-domains.sh manage-dns.sh manage-ssl.sh \
                 manage-web.sh manage-db.sh manage-api.sh manage-config.sh \
                 manage-monitoring.sh manage-updates.sh manage-docker.sh \
                 manage-network.sh manage-logs.sh manage-backups.sh \
                 manage-security.sh manage-performance.sh; do
        if [ ! -x "$script" ]; then
            echo "Chýba alebo nie je spustiteľný skript: $script"
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo "Prosím, nainštalujte chýbajúce závislosti"
        exit 1
    fi
}

# Funkcia pre inicializáciu systému
init_system() {
    echo "=== Inicializácia systému ==="
    
    # Vytvorenie potrebných adresárov
    mkdir -p ${CONFIG_DIR}/{pdns,apache,php,npm}
    mkdir -p ${LOG_DIR}
    mkdir -p ${BACKUP_DIR}
    mkdir -p ${BASE_DIR}/www
    
    # Nastavenie práv
    chmod 755 ${CONFIG_DIR} ${LOG_DIR} ${BACKUP_DIR} ${BASE_DIR}
    chmod 644 .env
    
    # Inicializácia Docker sietí
    docker network create ddns_net || true
    
    # Spustenie služieb
    docker-compose up -d
    docker-compose -f npm-compose.yml up -d
    
    log_message "Systém bol inicializovaný"
    echo "Inicializácia dokončená"
}

# Funkcia pre zobrazenie stavu
show_status() {
    echo "=== Stav systému ==="
    
    # Stav služieb
    echo -e "\n== Docker kontajnery =="
    docker-compose ps
    docker-compose -f npm-compose.yml ps
    
    # Systémové zdroje
    echo -e "\n== Využitie zdrojov =="
    ./manage-performance.sh resources
    
    # DNS štatistiky
    echo -e "\n== DNS štatistiky =="
    ./manage-dns.sh check
    
    # Webové štatistiky
    echo -e "\n== Web štatistiky =="
    ./manage-web.sh check
}

# Funkcia pre zobrazenie nápovedy
show_help() {
    echo "Použitie: $0 {init|status|help} alebo $0 {service} {action} [parametre]"
    echo
    echo "Hlavné príkazy:"
    echo "  init      - Inicializácia systému"
    echo "  status    - Zobrazenie stavu systému"
    echo "  help      - Zobrazenie tejto nápovedy"
    echo
    echo "Dostupné služby:"
    echo "  users     - Správa používateľov"
    echo "  domains   - Správa domén"
    echo "  dns       - Správa DNS"
    echo "  ssl       - Správa SSL certifikátov"
    echo "  web       - Správa webového servera"
    echo "  db        - Správa databázy"
    echo "  api       - Správa API"
    echo "  config    - Správa konfigurácie"
    echo "  monitor   - Monitoring systému"
    echo "  updates   - Správa aktualizácií"
    echo "  docker    - Správa Docker kontajnerov"
    echo "  network   - Správa siete"
    echo "  logs      - Správa logov"
    echo "  backups   - Správa záloh"
    echo "  security  - Správa zabezpečenia"
    echo "  perf      - Správa výkonu"
    echo
    echo "Pre zobrazenie nápovedy konkrétnej služby použite: $0 {service} help"
}

# Kontrola závislostí
check_dependencies

# Spracovanie parametrov
case "$1" in
    init)
        init_system
        ;;
    status)
        show_status
        ;;
    help)
        show_help
        ;;
    users|domains|dns|ssl|web|db|api|config|monitor|updates|docker|network|logs|backups|security|perf)
        service=$1
        shift
        "./manage-${service}.sh" "$@"
        ;;
    *)
        show_help
        exit 1
esac

