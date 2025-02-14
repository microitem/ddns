#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/logs.log
}

# Funkcia pre zobrazenie logov
show_logs() {
    local service=$1
    local lines=${2:-100}
    
    case $service in
        all)
            echo "=== Všetky logy ==="
            for log in ${LOG_DIR}/*.log; do
                echo -e "\n=== $(basename $log) ==="
                tail -n $lines "$log"
            done
            ;;
        docker)
            echo "=== Docker logy ==="
            docker-compose logs --tail=$lines
            docker-compose -f npm-compose.yml logs --tail=$lines
            ;;
        pdns)
            echo "=== PowerDNS logy ==="
            docker-compose logs --tail=$lines pdns
            ;;
        web)
            echo "=== Web server logy ==="
            docker-compose logs --tail=$lines web
            ;;
        db)
            echo "=== Database logy ==="
            docker-compose logs --tail=$lines db
            ;;
        npm)
            echo "=== Nginx Proxy Manager logy ==="
            docker-compose -f npm-compose.yml logs --tail=$lines npm
            ;;
        api)
            echo "=== API logy ==="
            tail -n $lines ${LOG_DIR}/api.log
            ;;
        *)
            if [ -f "${LOG_DIR}/${service}.log" ]; then
                echo "=== $service logy ==="
                tail -n $lines "${LOG_DIR}/${service}.log"
            else
                echo "Neznáma služba: $service"
                exit 1
            fi
            ;;
    esac
}

# Funkcia pre rotáciu logov
rotate_logs() {
    log_message "Začínam rotáciu logov"
    
    # Rotácia systémových logov
    for log in ${LOG_DIR}/*.log; do
        if [ -f "$log" ]; then
            # Vytvorenie archívu ak je log väčší ako 10MB
            if [ $(stat -f%z "$log") -gt 10485760 ]; then
                mv "$log" "${log}.$(date +%Y%m%d)"
                gzip "${log}.$(date +%Y%m%d)"
                touch "$log"
                log_message "Rotovaný log: $log"
            fi
        fi
    done
    
    # Vymazanie starých logov (staršie ako 30 dní)
    find ${LOG_DIR} -name "*.gz" -mtime +30 -delete
    
    log_message "Rotácia logov dokončená"
}

# Funkcia pre analýzu logov
analyze_logs() {
    local service=$1
    local date=${2:-$(date +%Y-%m-%d)}
    
    echo "=== Analýza logov pre $service ($date) ==="
    
    case $service in
        api)
            echo -e "\n== Top 10 IP adries =="
            grep "$date" ${LOG_DIR}/api.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
            
            echo -e "\n== Top 10 domén =="
            grep "$date" ${LOG_DIR}/api.log | grep "hostname=" | cut -d'=' -f2 | cut -d'&' -f1 | sort | uniq -c | sort -nr | head -10
            
            echo -e "\n== Chybové požiadavky =="
            grep "$date" ${LOG_DIR}/api.log | grep "ERROR" | tail -10
            ;;
            
        dns)
            echo -e "\n== DNS štatistiky =="
            docker-compose exec -T pdns pdns_control show "*"
            
            echo -e "\n== Top 10 dotazov =="
            docker-compose exec -T pdns pdns_control list-queries | sort | uniq -c | sort -nr | head -10
            ;;
            
        web)
            echo -e "\n== HTTP kódy =="
            grep "$date" ${LOG_DIR}/web.log | cut -d'"' -f3 | cut -d' ' -f2 | sort | uniq -c | sort -nr
            
            echo -e "\n== Top 10 URL =="
            grep "$date" ${LOG_DIR}/web.log | cut -d'"' -f2 | sort | uniq -c | sort -nr | head -10
            ;;
            
        security)
            echo -e "\n== Neúspešné pokusy o prihlásenie =="
            grep "$date" ${LOG_DIR}/security.log | grep "Failed login" | tail -10
            
            echo -e "\n== Blokované IP adresy =="
            fail2ban-client status ddns-api
            ;;
            
        *)
            echo "Neznáma služba pre analýzu: $service"
            exit 1
            ;;
    esac
}

# Funkcia pre export logov
export_logs() {
    local start_date=$1
    local end_date=${2:-$(date +%Y-%m-%d)}
    local output_dir="${BACKUP_DIR}/logs_${start_date}_${end_date}"
    
    mkdir -p "$output_dir"
    
    # Export všetkých logov v danom časovom rozsahu
    for log in ${LOG_DIR}/*.log; do
        if [ -f "$log" ]; then
            local basename=$(basename "$log")
            sed -n "/${start_date}/,/${end_date}/p" "$log" > "${output_dir}/${basename}"
        fi
    done
    
    # Vytvorenie archívu
    tar -czf "${output_dir}.tar.gz" -C "${BACKUP_DIR}" "$(basename $output_dir)"
    rm -rf "$output_dir"
    
    log_message "Logy exportované do: ${output_dir}.tar.gz"
    echo "Logy boli exportované do: ${output_dir}.tar.gz"
}

# Spracovanie parametrov
case "$1" in
    show)
        show_logs "$2" "$3"
        ;;
    rotate)
        rotate_logs
        ;;
    analyze)
        analyze_logs "$2" "$3"
        ;;
    export)
        export_logs "$2" "$3"
        ;;
    *)
        echo "Použitie: $0 {show|rotate|analyze|export} [parametre]"
        echo "Príklady:"
        echo "  $0 show {all|docker|pdns|web|db|npm|api} [lines]"
        echo "  $0 rotate"
        echo "  $0 analyze {api|dns|web|security} [date]"
        echo "  $0 export start_date [end_date]"
        exit 1
esac

