# MySQL Konfigurácia pre PowerDNS

## Základná konfigurácia

### 1. Premenné prostredia
Nastavenia v .env súbore:
MYSQL_ROOT_PASSWORD=silne_root_heslo
MYSQL_DATABASE=powerdns
MYSQL_USER=powerdns
MYSQL_PASSWORD=silne_heslo

### 2. Databázová schéma
Základná schéma je v sql/init.sql:

CREATE TABLE domains (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255) NOT NULL,
  master                VARCHAR(128) DEFAULT NULL,
  last_check           INT DEFAULT NULL,
  type                  VARCHAR(6) NOT NULL,
  notified_serial      INT UNSIGNED DEFAULT NULL,
  account              VARCHAR(40) CHARACTER SET 'utf8' DEFAULT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE records (
  id                    BIGINT AUTO_INCREMENT,
  domain_id            INT DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) DEFAULT NULL,
  content              VARCHAR(64000) DEFAULT NULL,
  ttl                   INT DEFAULT NULL,
  prio                  INT DEFAULT NULL,
  disabled             BOOLEAN DEFAULT 0,
  PRIMARY KEY (id)
) Engine=InnoDB CHARACTER SET 'latin1';

## Správa databázy

### 1. Pripojenie k databáze
docker exec -it ddns_db_1 mysql -upowerdns -p powerdns

### 2. Základné príkazy
# Zobrazenie domén
SELECT * FROM domains;

# Zobrazenie DNS záznamov
SELECT * FROM records;

# Pridanie novej domény
INSERT INTO domains (name, type) VALUES ('example.com', 'NATIVE');

# Pridanie DNS záznamu
INSERT INTO records (domain_id, name, type, content, ttl) 
VALUES (1, 'nas.example.com', 'A', '192.168.1.100', 300);

## Zálohovanie

### 1. Vytvorenie zálohy
docker exec ddns_db_1 mysqldump -upowerdns -p powerdns > backup.sql

### 2. Obnova zo zálohy
docker exec -i ddns_db_1 mysql -upowerdns -p powerdns < backup.sql

## Optimalizácia

### 1. Indexy
CREATE INDEX recordname_index ON records (name);
CREATE INDEX domain_id ON records (domain_id);
CREATE INDEX nametype_index ON records (name,type);

### 2. Údržba
# Analýza tabuliek
ANALYZE TABLE domains, records;

# Optimalizácia tabuliek
OPTIMIZE TABLE domains, records;

## Monitoring

### 1. Stav databázy
SHOW STATUS;
SHOW PROCESSLIST;

### 2. Veľkosť tabuliek
SELECT 
    table_name AS 'Tabuľka',
    round(((data_length + index_length) / 1024 / 1024), 2) AS 'Veľkosť (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'powerdns';

## Bezpečnosť

### 1. Práva používateľov
SHOW GRANTS FOR 'powerdns'@'%';

### 2. Odporúčania
- Pravidelne meniť heslá
- Obmedziť prístup len na potrebné IP adresy
- Pravidelne zálohovať
- Monitorovať neobvyklú aktivitu
