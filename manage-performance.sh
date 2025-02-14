#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/performance.log
}

# Funkcia pre kontrolu zdrojov
check_resources() {
    echo "=== Systémové zdroje ==="
    
    # CPU
    echo -e "\n== CPU využitie =="
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU využitie: " (100 - $1) "%"}'
    
    # Pamäť
    echo -e "\n== Pamäť =="
    free -h
    
    # Disk
    echo -e "\n== Diskový priestor =="
    df -h ${BASE_DIR}
    
    # Docker kontajnery
    echo -e "\n== Docker kontajnery =="
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Funkcia pre monitoring výkonu
monitor_performance() {
    local duration=${1:-300}  # predvolené 5 minút
    local interval=${2:-5}    # predvolený interval 5 sekúnd
    local output_file="${LOG_DIR}/performance_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Monitorujem výkon systému po dobu ${duration}s (interval: ${interval}s)..."
    
    # Hlavička súboru
    {
        echo "=== Monitoring výkonu ==="
        echo "Začiatok: $(date)"
        echo "Trvanie: ${duration}s"
        echo "Interval: ${interval}s"
        echo "---"
    } > "$output_file"
    
    # Monitoring v cykle
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        {
            echo "=== $(date) ==="
            
            # CPU
            top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU: " (100 - $1) "%"}'
            
            # Pamäť
            free -h | grep "Mem:" | awk '{print "Pamäť: " $3 "/" $2 " (" int($3/$2 * 100) "%)"}'
            
            # Disk I/O
            iostat -x 1 1 | grep -A1 "avg-cpu"
            
            # Sieť
            netstat -i | grep -v "Kernel"
            
            # Docker kontajnery
            docker stats --no-stream --format "{{.Name}}: {{.CPUPerc}} CPU, {{.MemUsage}} MEM, {{.NetIO}} NET, {{.BlockIO}} IO"
            
            echo "---"
        } >> "$output_file"
        sleep $interval
    done
    
    # Zhrnutie
    {
        echo "=== Zhrnutie ==="
        echo "Koniec: $(date)"
        echo "Priemerné hodnoty:"
        
        # Priemerné CPU využitie
        echo -n "CPU: "
        awk '/CPU:/ {sum+=$2; count++} END {print sum/count "%"}' "$output_file"
        
        # Priemerné využitie pamäte
        echo -n "Pamäť: "
        awk '/Pamäť:/ {sum+=$4; count++} END {print sum/count "%"}' "$output_file"
    } >> "$output_file"
    
    log_message "Monitoring dokončený: $output_file"
    echo "Monitoring bol dokončený. Výsledky: $output_file"
}

# Funkcia pre optimalizáciu výkonu
optimize_performance() {
    echo "=== Optimalizácia výkonu ==="
    
    # Docker optimalizácie
    echo -e "\n== Optimalizujem Docker =="
    docker system prune -f
    
    # Databázová optimalizácia
    echo -e "\n== Optimalizujem databázu =="
    ./manage-db.sh optimize
    
    # Cache čistenie
    echo -e "\n== Čistím cache =="
    sync; echo 3 > /proc/sys/vm/drop_caches
    
    # Kontrola a optimalizácia služieb
    echo -e "\n== Optimalizujem služby =="
    
    # PowerDNS
    docker-compose exec -T pdns pdns_control purge
    docker-compose exec -T pdns pdns_control clear-cache
    
    # Web server
    docker-compose exec -T web apache2ctl -t
    docker-compose exec -T web apache2ctl graceful
    
    log_message "Systém bol optimalizovaný"
    echo "Optimalizácia dokončená"
}

# Funkcia pre stress test
stress_test() {
    local duration=${1:-60}  # predvolené 1 minúta
    
    echo "=== Stress test ==="
    echo "Trvanie: ${duration}s"
    
    # Záloha aktuálneho stavu
    local before_file="${LOG_DIR}/stress_before_$(date +%Y%m%d_%H%M%S).log"
    check_resources > "$before_file"
    
    # Spustenie stress testu
    echo -e "\n== Spúšťam stress test =="
    docker run --rm -it progrium/stress --cpu 2 --io 1 --vm 2 --vm-bytes 128M --timeout ${duration}s
    
    # Výsledky po teste
    local after_file="${LOG_DIR}/stress_after_$(date +%Y%m%d_%H%M%S).log"
    check_resources > "$after_file"
    
    # Porovnanie
    echo -e "\n== Výsledky testu =="
    echo "Pred testom: $before_file"
    echo "Po teste: $after_file"
    
    log_message "Stress test dokončený"
}

# Spracovanie parametrov
case "$1" in
    resources)
        check_resources
        ;;
    monitor)
        monitor_performance "$2" "$3"
        ;;
    optimize)
        optimize_performance
        ;;
    stress)
        stress_test "$2"
        ;;
    *)
        echo "Použitie: $0 {resources|monitor|optimize|stress} [parametre]"
        echo "Príklady:"
        echo "  $0 resources"
        echo "  $0 monitor [duration] [interval]"
        echo "  $0 optimize"
        echo "  $0 stress [duration]"
        exit 1
esac

