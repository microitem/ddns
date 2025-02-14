# Riešenie problémov

## Kontrola služieb
docker-compose ps
docker-compose logs pdns
docker-compose logs db
docker-compose logs web

## DNS testy
# Lokálny test
dig @localhost ${EXAMPLE_SUBDOMAIN}

# Externý test
dig @8.8.8.8 ${EXAMPLE_SUBDOMAIN}

## Databázové kontroly
docker exec -it ddns_db_1 mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
SELECT * FROM domains;
SELECT * FROM records;

## Časté problémy

1. PowerDNS nereaguje
- Kontrola logov: tail -f ${LOG_DIR}/pdns.log
- Kontrola MySQL pripojenia
- Reštart: docker-compose restart pdns

2. API chyby
- Kontrola logov: tail -f ${LOG_DIR}/api.log
- Overenie hesla a hostname
- Kontrola práv v MySQL

3. DNS problémy
- Kontrola NS záznamov
- Vyčistenie cache: docker-compose exec pdns pdns_control clear-cache
- Overenie firewall pravidiel

4. SSL problémy
- Kontrola certifikátov v ${CONFIG_DIR}/ssl/
- Overenie Apache SSL konfigurácie
- Kontrola SSL logov

## Monitoring
tail -f ${LOG_DIR}/*.log
docker stats
htop

## Debug režim
- PowerDNS: PDNS_loglevel=7
- Apache: LogLevel debug
- MySQL: slow_query_log = 1
