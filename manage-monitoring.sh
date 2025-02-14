#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/monitoring.log
}

# Funkcia pre kontrolu systému
check_system() {
    echo "=== Kontrola systému ==="
    
    # Systémové zdroje
    echo -e "\n== Využitie zdrojov =="
    echo "CPU:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | awk '{print $1"%"}'
    
    echo "Pamäť:"
    free -h
    
    echo "Disk:"
    df -h ${BASE_DIR}
    
    # Docker kontajnery
    echo -e "\n== Stav kontajnerov =="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Sieťové pripojenia
    echo -e "\n== Sieťové pripojenia =="
    netstat -tulpn | grep -E "docker|pdns|nginx"
}

# Funkcia pre monitorovanie výkonu
monitor_performance() {
    local duration=${1:-300}  # predvolené 5 minút
    local interval=${2:-5}    # predvolený interval 5 sekúnd
    local output_file="${LOG_DIR}/performance_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Monitorujem výkon systému po dobu ${duration}s..."
    
    # Monitorovanie v cykle
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        {
            echo "=== $(date) ==="
            echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
            echo "Pamäť: $(free -h | grep Mem | awk '{print $3"/"$2}')"
            echo "Docker kontajnery:"
            docker stats --no-stream --format "{{.Name}}: {{.CPUPerc}} CPU, {{.MemUsage}} MEM"
            echo "---"
        } >> "$output_file"
        sleep $interval
    done
    
    echo "Monitoring dokončený. Výsledky: $output_file"
}

# Funkcia pre kontrolu služieb
check_services() {
    echo "=== Kontrola služieb ==="
    
    # PowerDNS
    echo -e "\n== PowerDNS =="
    if docker-compose exec -T pdns pdns_control ping >/dev/null; then
        echo "OK: PowerDNS beží"
        docker-compose exec -T pdns pdns_control show "*"
    else
        echo "CHYBA: PowerDNS nebeží"
    fi
    
    # Web server
    echo -e "\n== Web server =="
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost${API_ENDPOINT}" | grep -q "200\|401"; then
        echo "OK: Web server beží"
    else
        echo "CHYBA: Web server nebeží"
    fi
    
    # Databáza
    echo -e "\n== Databáza =="
    if docker-compose exec -T db mysqladmin -u${MYSQL_USER} -p${MYSQL_PASSWORD} ping >/dev/null; then
        echo "OK: Databáza beží"
    else
        echo "CHYBA: Databáza nebeží"
    fi
    
    # NPM
    echo -e "\n== Nginx Proxy Manager =="
    if docker-compose -f npm-compose.yml exec -T npm nginx -t >/dev/null 2>&1; then
        echo "OK: NPM beží"
    else
        echo "CHYBA: NPM nebeží"
    fi
}

# Funkcia pre generovanie reportu
generate_report() {
    local report_file="${LOG_DIR}/system_report_$(date +%Y%m%d).html"
    
    # Vytvorenie HTML reportu
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Systémový report - $(date)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .section { margin: 20px 0; padding: 10px; background: #f5f5f5; }
        .error { color: red; }
        .ok { color: green; }
    </style>
</head>
<body>
    <h1>Systémový report</h1>
    <p>Vygenerované: $(date)</p>
    
    <div class="section">
        <h2>Systémové zdroje</h2>
        <pre>$(check_system)</pre>
    </div>
    
    <div class="section">
        <h2>Stav služieb</h2>
        <pre>$(check_services)</pre>
    </div>
    
    <div class="section">
        <h2>Štatistiky</h2>
        <pre>
DNS požiadavky: $(docker-compose exec -T pdns pdns_control show "query-count")
API požiadavky: $(grep "$(date +%Y-%m-%d)" ${LOG_DIR}/api.log | wc -l)
Aktívne domény: $(docker-compose exec -T db mysql -N -s -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} -e "SELECT COUNT(*) FROM domains")
        </pre>
    </div>
</body>
</html>
EOF
    
    log_message "Report vygenerovaný: $report_file"
    echo "Report bol vygenerovaný: $report_file"
}

# Spracovanie parametrov
case "$1" in
    check)
        check_system
        ;;
    monitor)
        monitor_performance "$2" "$3"
        ;;
    services)
        check_services
        ;;
    report)
        generate_report
        ;;
    *)
        echo "Použitie: $0 {check|monitor|services|report} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 monitor [duration] [interval]"
        echo "  $0 services"
        echo "  $0 report"
        exit 1
esac

