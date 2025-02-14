#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/network.log
}

# Funkcia pre kontrolu siete
check_network() {
    echo "=== Kontrola siete ==="
    
    # Sieťové rozhrania
    echo -e "\n== Sieťové rozhrania =="
    ip addr show
    
    # Docker siete
    echo -e "\n== Docker siete =="
    docker network ls
    docker network inspect ddns_net
    
    # Aktívne spojenia
    echo -e "\n== Aktívne spojenia =="
    netstat -tulpn | grep -E "docker|pdns|nginx"
    
    # DNS test
    echo -e "\n== DNS test =="
    for domain in ${EXAMPLE_DOMAIN} www.${EXAMPLE_DOMAIN}; do
        echo "Test pre $domain:"
        dig @localhost $domain +short
    done
    
    # Firewall
    echo -e "\n== Firewall pravidlá =="
    ufw status verbose
}

# Funkcia pre správu Docker sietí
manage_docker_network() {
    local action=$1
    local network=${2:-ddns_net}
    
    case $action in
        create)
            docker network create $network
            log_message "Vytvorená Docker sieť: $network"
            echo "Sieť bola vytvorená"
            ;;
            
        remove)
            docker network rm $network
            log_message "Odstránená Docker sieť: $network"
            echo "Sieť bola odstránená"
            ;;
            
        inspect)
            docker network inspect $network
            ;;
            
        connect)
            local container=$3
            docker network connect $network $container
            log_message "Pripojený kontajner $container k sieti $network"
            echo "Kontajner bol pripojený"
            ;;
            
        disconnect)
            local container=$3
            docker network disconnect $network $container
            log_message "Odpojený kontajner $container od siete $network"
            echo "Kontajner bol odpojený"
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Funkcia pre správu firewallu
manage_firewall() {
    local action=$1
    local port=$2
    local protocol=${3:-tcp}
    
    case $action in
        allow)
            ufw allow $port/$protocol
            log_message "Povolený port $port/$protocol"
            echo "Port bol povolený"
            ;;
            
        deny)
            ufw deny $port/$protocol
            log_message "Zakázaný port $port/$protocol"
            echo "Port bol zakázaný"
            ;;
            
        delete)
            ufw delete allow $port/$protocol
            ufw delete deny $port/$protocol
            log_message "Odstránené pravidlo pre port $port/$protocol"
            echo "Pravidlo bolo odstránené"
            ;;
            
        status)
            ufw status verbose
            ;;
            
        *)
            echo "Neznáma akcia: $action"
            exit 1
            ;;
    esac
}

# Funkcia pre diagnostiku siete
diagnose_network() {
    local target=${1:-${EXAMPLE_DOMAIN}}
    
    echo "=== Diagnostika siete pre $target ==="
    
    # Ping test
    echo -e "\n== Ping test =="
    ping -c 4 $target
    
    # Traceroute
    echo -e "\n== Traceroute =="
    traceroute $target
    
    # DNS lookup
    echo -e "\n== DNS lookup =="
    dig $target +trace
    
    # Port scan
    echo -e "\n== Port scan =="
    nmap -p- -T4 $target
    
    # HTTP test
    echo -e "\n== HTTP test =="
    curl -sI "http://$target"
    curl -sI "https://$target"
    
    log_message "Vykonaná diagnostika pre: $target"
}

# Funkcia pre monitoring siete
monitor_network() {
    local duration=${1:-300}  # predvolené 5 minút
    local interval=${2:-5}    # predvolený interval 5 sekúnd
    local output_file="${LOG_DIR}/network_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Monitorujem sieť po dobu ${duration}s (interval: ${interval}s)..."
    
    # Monitoring v cykle
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        {
            echo "=== $(date) ==="
            
            # Sieťové štatistiky
            echo "== Sieťové rozhrania =="
            ip -s link
            
            echo "== TCP spojenia =="
            netstat -tn | awk '/^tcp/ {print $6}' | sort | uniq -c
            
            echo "== Docker siete =="
            docker network inspect ddns_net
            
            echo "---"
        } >> "$output_file"
        sleep $interval
    done
    
    log_message "Monitoring siete dokončený: $output_file"
    echo "Monitoring bol dokončený. Výsledky: $output_file"
}

# Spracovanie parametrov
case "$1" in
    check)
        check_network
        ;;
    docker)
        manage_docker_network "$2" "$3" "$4"
        ;;
    firewall)
        manage_firewall "$2" "$3" "$4"
        ;;
    diagnose)
        diagnose_network "$2"
        ;;
    monitor)
        monitor_network "$2" "$3"
        ;;
    *)
        echo "Použitie: $0 {check|docker|firewall|diagnose|monitor} [parametre]"
        echo "Príklady:"
        echo "  $0 check"
        echo "  $0 docker {create|remove|inspect|connect|disconnect} [network] [container]"
        echo "  $0 firewall {allow|deny|delete|status} port [protocol]"
        echo "  $0 diagnose [target]"
        echo "  $0 monitor [duration] [interval]"
        exit 1
esac

