# PowerDNS Konfigurácia

## Docker konfigurácia
Nastavenia v docker-compose.yml:

version: '3'
services:
  pdns:
    image: powerdns/pdns-auth-master:latest
    container_name: ddns_pdns
    ports:
      - "${PORTS_DNS_TCP}:53/tcp"
      - "${PORTS_DNS_UDP}:53/udp"
    environment:
      - PDNS_launch=gmysql
      - PDNS_gmysql-host=db
      - PDNS_gmysql-port=3306
      - PDNS_gmysql-user=${MYSQL_USER}
      - PDNS_gmysql-dbname=${MYSQL_DATABASE}
      - PDNS_gmysql-password=${MYSQL_PASSWORD}
      - PDNS_api=yes
      - PDNS_api-key=${PDNS_API_KEY}
      - PDNS_webserver=yes
      - PDNS_webserver-port=${PDNS_WEBSERVER_PORT}
      - PDNS_webserver-address=${PDNS_WEBSERVER_ADDRESS}
    restart: unless-stopped

## Databázové príkazy

1. Pridanie novej domény:
INSERT INTO domains (name, type) VALUES ('${EXAMPLE_DOMAIN}', 'NATIVE');

2. Pridanie A záznamu:
INSERT INTO records (domain_id, name, type, content, ttl) 
SELECT id, '${EXAMPLE_SUBDOMAIN}', 'A', '192.168.1.100', ${TTL_DEFAULT}
FROM domains WHERE name='${EXAMPLE_DOMAIN}';

3. Pridanie NS záznamov:
INSERT INTO records (domain_id, name, type, content, ttl)
SELECT id, '${EXAMPLE_DOMAIN}', 'NS', '${EXAMPLE_NS1}', ${TTL_SOA}
FROM domains WHERE name='${EXAMPLE_DOMAIN}';

INSERT INTO records (domain_id, name, type, content, ttl)
SELECT id, '${EXAMPLE_DOMAIN}', 'NS', '${EXAMPLE_NS2}', ${TTL_SOA}
FROM domains WHERE name='${EXAMPLE_DOMAIN}';

## Logovanie
Logy sa ukladajú do: ${LOG_DIR}/pdns.log

## Monitoring
1. Kontrola stavu:
docker-compose exec pdns pdns_control status

2. Štatistiky:
docker-compose exec pdns pdns_control show "*"

3. Cache:
docker-compose exec pdns pdns_control purge
docker-compose exec pdns pdns_control clear-cache ${EXAMPLE_DOMAIN}

## Údržba
1. Záloha:
docker-compose exec db mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${BACKUP_DIR}/pdns_$(date +%Y%m%d).sql

2. Obnova:
docker-compose exec -i db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < ${BACKUP_DIR}/pdns_backup.sql
