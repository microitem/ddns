# Nastavenie routera pre DDNS

## Všeobecné nastavenie
1. Webové rozhranie routera (192.168.1.1)
2. DDNS sekcia:
   - Provider: Custom
   - Update URL: http://${EXAMPLE_DOMAIN}${API_ENDPOINT}?hostname=${EXAMPLE_SUBDOMAIN}&password=heslo&ip=[IP]
   - Hostname: ${EXAMPLE_SUBDOMAIN}
   - Interval: ${REFRESH_INTERVAL}

## Port forwarding
1. NAT/Port Forwarding:
   - HTTP: ${PORTS_HTTP} -> DS223_IP
   - HTTPS: ${PORTS_HTTPS} -> DS223_IP
   - DNS: ${PORTS_DNS_TCP} -> DS223_IP
   - DNS UDP: ${PORTS_DNS_UDP} -> DS223_IP

## Mikrotik konfigurácia
/ip cloud
set ddns-enabled=yes
set ddns-update-interval=${REFRESH_INTERVAL}
set update-url="http://${EXAMPLE_DOMAIN}${API_ENDPOINT}?hostname=${EXAMPLE_SUBDOMAIN}&password=heslo"

## OpenWrt konfigurácia
/etc/config/ddns:
config service 'custom'
    option service_name 'custom'
    option update_url "http://${EXAMPLE_DOMAIN}${API_ENDPOINT}?hostname=${EXAMPLE_SUBDOMAIN}&password=heslo&ip=[IP]"
    option check_interval ${REFRESH_INTERVAL}

## Logovanie
- Router logy: ${LOG_DIR}/router.log
- DDNS update logy: ${LOG_DIR}/ddns_updates.log

## Testovanie
1. curl -v "http://${EXAMPLE_DOMAIN}${API_ENDPOINT}?hostname=${EXAMPLE_SUBDOMAIN}&password=heslo"
2. dig @8.8.8.8 ${EXAMPLE_SUBDOMAIN}
