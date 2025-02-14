#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/updates.log
}

# Funkcia pre kontrolu aktualizácií
check_updates() {
    echo "=== Kontrola dostupných aktualizácií ==="
    
    # Systémové aktualizácie
    echo -e "\n== Systémové aktualizácie =="
    apt update
    apt list --upgradable
    
    # Docker aktualizácie
    echo -e "\n== Docker obrazy =="
    docker-compose pull --ignore-pull-failures
    docker-compose -f npm-compose.yml pull --ignore-pull-failures
    
    # Git aktualizácie
    echo -e "\n== Git repozitár =="
    git remote update
    git status -uno
    
    # Kontrola verzií
    echo -e "\n== Verzie komponentov =="
    docker-compose exec -T pdns pdns_control version
    docker-compose exec -T web apache2 -v
    docker-compose exec -T web php -v
    docker-compose exec -T db mysql -V
    docker-compose -f npm-compose.yml exec -T npm nginx -v
}

# Funkcia pre aplikáciu aktualizácií
apply_updates() {
    echo "=== Aplikujem aktualizácie ==="
    
    # Záloha pred aktualizáciou
    echo "Vytváram zálohu..."
    ./manage-backups.sh backup
    
    # Systémové aktualizácie
    echo -e "\n== Aktualizujem systém =="
    apt update && apt upgrade -y
    
    # Docker aktualizácie
    echo -e "\n== Aktualizujem Docker kontajnery =="
    docker-compose down
    docker-compose -f npm-compose.yml down
    docker-compose pull
    docker-compose -f npm-compose.yml pull
    docker-compose up -d
    docker-compose -f npm-compose.yml up -d
    
    # Git aktualizácie
    echo -e "\n== Aktualizujem Git repozitár =="
    git pull
    
    # Čistenie
    echo -e "\n== Čistenie =="
    docker image prune -f
    apt autoremove -y
    apt clean
    
    log_message "Systém bol aktualizovaný"
    echo "Aktualizácie boli aplikované"
}

# Funkcia pre rollback
rollback_updates() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Musíte zadať súbor zálohy pre rollback"
        exit 1
    fi
    
    echo "!!! VAROVANIE !!!"
    echo "Táto operácia obnoví systém do predchádzajúceho stavu!"
    read -p "Pokračovať? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    # Zastavenie služieb
    docker-compose down
    docker-compose -f npm-compose.yml down
    
    # Obnova zo zálohy
    ./manage-backups.sh restore "$backup_file"
    
    # Reštart služieb
    docker-compose up -d
    docker-compose -f npm-compose.yml up -d
    
    log_message "Systém bol obnovený zo zálohy: $backup_file"
    echo "Rollback bol dokončený"
}

# Funkcia pre správu verzií
manage_versions() {
    local action=$1
    
    case $action in
        list)
            echo "=== Verzie komponentov ==="
            echo -e "\nPowerDNS:"
            docker-compose exec -T pdns pdns_control version
            
            echo -e "\nApache:"
            docker-compose exec -T web apache2 -v
            
            echo -e "\nPHP:"
            docker-compose exec -T web php -v
            
            echo -e "\nMySQL:"
            docker-compose exec -T db mysql -V
            
            echo -e "\nNginx Proxy Manager:"
            docker-compose -f npm-compose.yml exec -T npm nginx -v
            ;;
            
        history)
            echo "=== História aktualizácií ==="
            cat ${LOG_DIR}/updates.log
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
        check_updates
        ;;
    apply)
        apply_updates
        ;;
    rollback)
        rollback_updates "$2"
        ;;
    versions)
        manage_versions "$2"
        ;;
    *)
        echo "Použitie: $0 {check|apply|rollback|versions} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 apply"
        echo "  $0 rollback backup_file"
        echo "  $0 versions {list|history}"
        exit 1
esac

