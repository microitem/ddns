#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/manage.log
}

# Funkcia pre výpis posledných logov
show_logs() {
    local service=$1
    local lines=${2:-50}
    
    case $service in
        pdns)
            docker-compose logs --tail=$lines pdns
            ;;
        web)
            docker-compose logs --tail=$lines web
            ;;
        db)
            docker-compose logs --tail=$lines db
            ;;
        npm)
            docker-compose -f npm-compose.yml logs --tail=$lines npm
            ;;
        api)
            tail -n $lines ${LOG_DIR}/api.log
            ;;
        system)
            tail -n $lines ${LOG_DIR}/system.log
            ;;
        all)
            echo "=== PowerDNS logs ==="
            docker-compose logs --tail=20 pdns
            echo -e "\n=== Web logs ==="
            docker-compose logs --tail=20 web
            echo -e "\n=== Database logs ==="
            docker-compose logs --tail=20 db
            echo -e "\n=== NPM logs ==="
            docker-compose -f npm-compose.yml logs --tail=20 npm
            echo -e "\n=== API logs ==="
            tail -n 20 ${LOG_DIR}/api.log
            echo -e "\n=== System logs ==="
            tail -n 20 ${LOG_DIR}/system.log
            ;;
        *)
            echo "Neznáma služba: $service"
            exit 1
            ;;
    esac
}

# Funkcia pre archiváciu logov
archive_logs() {
    local archive_dir="${BACKUP_DIR}/logs_$(date +%Y%m%d)"
    mkdir -p "$archive_dir"
    
    # Kompresia a archivácia logov
    for log in ${LOG_DIR}/*.log; do
        if [ -f "$log" ]; then
            filename=$(basename "$log")
            gzip -c "$log" > "${archive_dir}/${filename}.gz"
            # Vyčistenie pôvodného logu
            echo "" > "$log"
        fi
    done
    
    log_message "Logy archivované do: $archive_dir"
    echo "Logy boli archivované do: $archive_dir"
}

# Funkcia pre analýzu logov
analyze_logs() {
    echo "=== Analýza logov ==="
    
    echo "Top 10 IP adries:"
    grep -h "client" ${LOG_DIR}/*.log | awk '{print $8}' | sort | uniq -c | sort -nr | head -10
    
    echo -e "\nPosledné chyby:"
    grep -h "ERROR\|FAIL\|CRITICAL" ${LOG_DIR}/*.log | tail -10
    
    echo -e "\nŠtatistiky prístupov:"
    grep -h "GET\|POST" ${LOG_DIR}/api.log | awk '{print $6}' | sort | uniq -c | sort -nr | head -10
}

# Spracovanie parametrov
case "$1" in
    show)
        show_logs "$2" "$3"
        ;;
    archive)
        archive_logs
        ;;
    analyze)
        analyze_logs
        ;;
    *)
        echo "Použitie: $0 {show|archive|analyze} [služba] [počet_riadkov]"
        echo "Služby: pdns, web, db, npm, api, system, all"
        echo "Príklady:"
        echo "  $0 show pdns 100"
        echo "  $0 show all"
        echo "  $0 archive"
        echo "  $0 analyze"
        exit 1
esac

