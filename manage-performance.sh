#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/performance.log
}

# Funkcia pre kontrolu využitia zdrojov
check_resources() {
    echo "=== Využitie systémových zdrojov ==="
    
    echo "CPU využitie kontajnerov:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    
    echo -e "\nVyužitie disku:"
    df -h ${BASE_DIR} ${LOG_DIR} ${BACKUP_DIR}
    
    echo -e "\nTop procesy:"
    top -b -n 1 | head -n 20
}

# Funkcia pre kontrolu výkonu databázy
check_db_performance() {
    echo "=== Výkon databázy ==="
    
    echo "Aktívne spojenia:"
    docker-compose exec -T db mysqladmin -u${MYSQL_USER} -p${MYSQL_PASSWORD} processlist
    
    echo -e "\nStatus databázy:"
    docker-compose exec -T db mysqladmin -u${MYSQL_USER} -p${MYSQL_PASSWORD} status
    
    echo -e "\nSlow query log:"
    docker-compose exec -T db tail -n 20 /var/log/mysql/mysql-slow.log
}

# Funkcia pre kontrolu výkonu DNS
check_dns_performance() {
    echo "=== Výkon DNS servera ==="
    
    echo "DNS štatistiky:"
    docker-compose exec -T pdns pdns_control show "*"
    
    echo -e "\nTest DNS odozvy:"
    dig @localhost ${EXAMPLE_DOMAIN} | grep "Query time"
}

# Funkcia pre kontrolu výkonu webu
check_web_performance() {
    echo "=== Výkon webového servera ==="
    
    echo "Apache status:"
    docker-compose exec -T web apache2ctl status
    
    echo -e "\nTest HTTP odozvy:"
    curl -w "\nČas pripojenia: %{time_connect}s\nČas odpovede: %{time_starttransfer}s\nCelkový čas: %{time_total}s\n" \
        -o /dev/null -s "http://localhost${API_ENDPOINT}"
}

# Funkcia pre generovanie výkonnostného reportu
generate_report() {
    local report_file="${LOG_DIR}/performance_report_$(date +%Y%m%d).txt"
    
    {
        echo "=== Výkonnostný report $(date) ==="
        echo
        check_resources
        echo
        check_db_performance
        echo
        check_dns_performance
        echo
        check_web_performance
    } > "$report_file"
    
    log_message "Výkonnostný report vygenerovaný: $report_file"
    echo "Report bol vygenerovaný do: $report_file"
}

# Spracovanie parametrov
case "$1" in
    resources)
        check_resources
        ;;
    database)
        check_db_performance
        ;;
    dns)
        check_dns_performance
        ;;
    web)
        check_web_performance
        ;;
    report)
        generate_report
        ;;
    *)
        echo "Použitie: $0 {resources|database|dns|web|report}"
        echo "Príklady:"
        echo "  $0 resources"
        echo "  $0 database"
        echo "  $0 dns"
        echo "  $0 web"
        echo "  $0 report"
        exit 1
esac

