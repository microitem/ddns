# PowerDNS Konfigurácia

## Základné nastavenia PowerDNS
PowerDNS server je nakonfigurovaný cez docker-compose.yml a používa MySQL backend pre ukladanie záznamov.

## Konfiguračné parametre
Hlavné nastavenia sú definované v docker-compose.yml:

- launch=gmysql
- gmysql-host=db
- gmysql-port=3306
- gmysql-user=powerdns
- gmysql-dbname=powerdns
- gmysql-password=definované v .env
- api=yes
- api-key=definované v .env
- webserver=yes
- webserver-port=8081
- webserver-address=0.0.0.0
- webserver-allow-from=0.0.0.0/0

## Správa DNS záznamov

### Pridanie nového záznamu
1. Pripojenie k MySQL:
mysql -h localhost -u powerdns -p powerdns

2. Vloženie nového záznamu:
INSERT INTO domains (name, type) VALUES ('example.com', 'NATIVE');
INSERT INTO records (domain_id, name, type, content, ttl) 
SELECT id, 'nas.example.com', 'A', '192.168.1.100', 300 
FROM domains WHERE name='example.com';

### Aktualizácia záznamu
UPDATE records SET content='nova.ip.adresa' 
WHERE name='nas.example.com' AND type='A';

## Overenie konfigurácie

1. Test DNS servera:
dig @localhost nas.example.com

2. Kontrola logov:
docker-compose logs pdns

## Riešenie problémov
- Skontrolujte pripojenie k MySQL databáze
- Overte správnosť DNS záznamov
- Skontrolujte logy PowerDNS
- Overte firewall nastavenia
