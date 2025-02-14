# Riešenie problémov DDNS servera

## Diagnostika

### 1. Kontrola stavu služieb
# Kontrola bežiacich kontajnerov
docker-compose ps

# Kontrola logov
docker-compose logs
docker-compose logs pdns
docker-compose logs db

### 2. Kontrola DNS
# Test DNS servera
dig @localhost nas.vasa-domena.com

# Test externého prístupu
dig @8.8.8.8 nas.vasa-domena.com

### 3. Kontrola databázy
# Pripojenie k MySQL
docker exec -it ddns_db_1 mysql -upowerdns -p powerdns

# Kontrola záznamov
SELECT * FROM domains;
SELECT * FROM records;

## Časté problémy a riešenia

### 1. PowerDNS nereaguje
- Skontrolujte logy: docker-compose logs pdns
- Overte pripojenie k MySQL
- Reštartujte službu: docker-compose restart pdns

### 2. Aktualizácia IP nefunguje
- Skontrolujte API logy v www/logs
- Overte správnosť hesla a hostname
- Skontrolujte práva na zápis do databázy

### 3. DNS záznamy sa neaktualizujú
- Overte TTL hodnoty v záznamoch
- Skontrolujte cache na DNS serveroch
- Vyčistite lokálnu DNS cache

### 4. Problémy s pripojením
- Skontrolujte firewall nastavenia
- Overte porty (53, 80, 443)
- Skontrolujte nastavenia routera

## Logovanie

### 1. Zapnutie debug logovania
V docker-compose.yml pridajte:
environment:
  - PDNS_loglevel=7

### 2. Kontrola logov
# PowerDNS logy
docker-compose logs -f pdns

# Apache logy
docker-compose logs -f web

# MySQL logy
docker-compose logs -f db

## Bezpečnostné problémy

### 1. Podozrivá aktivita
- Skontrolujte logy pre neobvyklé prístupy
- Zmeňte heslá
- Aktualizujte firewall pravidlá

### 2. Výkonnostné problémy
- Monitorujte využitie zdrojov
- Skontrolujte počet požiadaviek
- Optimalizujte TTL hodnoty
