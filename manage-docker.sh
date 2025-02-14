#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/docker.log
}

# Funkcia pre kontrolu kontajnerov
check_containers() {
    echo "=== Stav Docker kontajnerov ==="
    
    echo -e "\n== DDNS kontajnery =="
    docker-compose ps
    
    echo -e "\n== NPM kontajner =="
    docker-compose -f npm-compose.yml ps
    
    echo -e "\n== Využitie zdrojov =="
    docker stats --no-stream
    
    echo -e "\n== Verzie obrazov =="
    docker images | grep -E 'pdns|nginx|mysql'
}

# Funkcia pre reštart kontajnerov
restart_containers() {
    local container=$1
    
    if [ -z "$container" ]; then
        log_message "Reštartujem všetky kontajnery"
        docker-compose down
        docker-compose -f npm-compose.yml down
        docker-compose up -d
        docker-compose -f npm-compose.yml up -d
    else
        log_message "Reštartujem kontajner: $container"
        if [ "$container" = "npm" ]; then
            docker-compose -f npm-compose.yml restart $container
        else
            docker-compose restart $container
        fi
    fi
    
    echo "Kontajnery boli reštartované"
}

# Funkcia pre aktualizáciu obrazov
update_images() {
    log_message "Aktualizujem Docker obrazy"
    
    # Záloha pred aktualizáciou
    ./backup.sh
    
    # Stiahnutie nových obrazov
    docker-compose pull
    docker-compose -f npm-compose.yml pull
    
    # Reštart s novými obrazmi
    docker-compose down
    docker-compose -f npm-compose.yml down
    docker-compose up -d
    docker-compose -f npm-compose.yml up -d
    
    # Čistenie starých obrazov
    docker image prune -f
    
    echo "Docker obrazy boli aktualizované"
}

# Funkcia pre čistenie
cleanup_docker() {
    echo "=== Čistenie Docker systému ==="
    
    echo "Odstraňujem nepoužívané kontajnery..."
    docker container prune -f
    
    echo "Odstraňujem nepoužívané obrazy..."
    docker image prune -f
    
    echo "Odstraňujem nepoužívané volumes..."
    docker volume prune -f
    
    echo "Odstraňujem nepoužívané siete..."
    docker network prune -f
    
    log_message "Docker systém bol vyčistený"
    echo "Čistenie dokončené"
}

# Funkcia pre zobrazenie logov
show_logs() {
    local container=$1
    local lines=${2:-100}
    
    if [ -z "$container" ]; then
        echo "=== Logy všetkých kontajnerov ==="
        docker-compose logs --tail=$lines
        docker-compose -f npm-compose.yml logs --tail=$lines
    else
        echo "=== Logy kontajnera $container ==="
        if [ "$container" = "npm" ]; then
            docker-compose -f npm-compose.yml logs --tail=$lines $container
        else
            docker-compose logs --tail=$lines $container
        fi
    fi
}

# Spracovanie parametrov
case "$1" in
    check)
        check_containers
        ;;
    restart)
        restart_containers "$2"
        ;;
    update)
        update_images
        ;;
    cleanup)
        cleanup_docker
        ;;
    logs)
        show_logs "$2" "$3"
        ;;
    *)
        echo "Použitie: $0 {check|restart|update|cleanup|logs} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 restart [container]"
        echo "  $0 update"
        echo "  $0 cleanup"
        echo "  $0 logs [container] [lines]"
        exit 1
esac

