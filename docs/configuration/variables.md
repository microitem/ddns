# Štandardné premenné a hodnoty

## Systémové premenné
SYSTEM_USER=ddns
SYSTEM_GROUP=ddns
BASE_DIR=/opt/ddns

## Databázové premenné
MYSQL_DATABASE=powerdns
MYSQL_USER=powerdns
MYSQL_PASSWORD=<STRONG_PASSWORD>
MYSQL_ROOT_PASSWORD=<STRONG_ROOT_PASSWORD>

## PowerDNS premenné
PDNS_API_KEY=<STRONG_API_KEY>
PDNS_WEBSERVER_PORT=8081
PDNS_WEBSERVER_ADDRESS=127.0.0.1

## Sieťové nastavenia
PORTS_DNS_TCP=53
PORTS_DNS_UDP=53
PORTS_HTTP=80
PORTS_HTTPS=443
PORTS_SSH=22

## Príklady domén
EXAMPLE_DOMAIN=example.com
EXAMPLE_SUBDOMAIN=nas.example.com
EXAMPLE_NS1=ns1.example.com
EXAMPLE_NS2=ns2.example.com

## Časové intervaly
TTL_DEFAULT=300
TTL_SOA=3600
REFRESH_INTERVAL=300

## Cesty k súborom
LOG_DIR=/var/log/ddns
BACKUP_DIR=/var/backup/ddns
CONFIG_DIR=/etc/ddns

## API endpointy
API_ENDPOINT=/api.php
API_UPDATE_ENDPOINT=/update.php
API_STATUS_ENDPOINT=/status.php
