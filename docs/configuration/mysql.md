# MySQL Konfigurácia

## Docker nastavenie
Konfigurácia v docker-compose.yml:

version: '3'
services:
  db:
    image: mysql:8.0
    container_name: ddns_db
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ${BASE_DIR}/mysql:/var/lib/mysql
      - ${CONFIG_DIR}/mysql:/etc/mysql/conf.d
      - ${LOG_DIR}:/var/log/mysql
    restart: unless-stopped

## Databázová schéma
CREATE TABLE domains (
  id INT AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  master VARCHAR(128) DEFAULT NULL,
  last_check INT DEFAULT NULL,
  type VARCHAR(6) NOT NULL,
  notified_serial INT UNSIGNED DEFAULT NULL,
  account VARCHAR(40) DEFAULT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE TABLE records (
  id BIGINT AUTO_INCREMENT,
  domain_id INT DEFAULT NULL,
  name VARCHAR(255) DEFAULT NULL,
  type VARCHAR(10) DEFAULT NULL,
  content VARCHAR(64000) DEFAULT NULL,
  ttl INT DEFAULT ${TTL_DEFAULT},
  prio INT DEFAULT NULL,
  disabled BOOLEAN DEFAULT 0,
  PRIMARY KEY (id),
  INDEX domain_id (domain_id),
  INDEX name_type_index (name, type)
) Engine=InnoDB;

## Správa databázy

1. Pripojenie:
docker-compose exec db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

2. Zálohovanie:
docker-compose exec db mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${BACKUP_DIR}/db_$(date +%Y%m%d).sql

3. Obnova:
docker-compose exec -i db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < ${BACKUP_DIR}/db_backup.sql

## Optimalizácia

1. Konfigurácia MySQL:
[mysqld]
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
max_connections = 100
key_buffer_size = 32M
query_cache_size = 32M

2. Údržba:
ANALYZE TABLE domains, records;
OPTIMIZE TABLE domains, records;

## Monitoring

1. Stav servera:
SHOW STATUS;
SHOW PROCESSLIST;

2. Veľkosť databázy:
SELECT table_name, round(((data_length + index_length) / 1024 / 1024), 2) AS "Size (MB)"
FROM information_schema.TABLES
WHERE table_schema = "${MYSQL_DATABASE}";

## Logovanie
Logy sa ukladajú do: ${LOG_DIR}/mysql.log
Error logy: ${LOG_DIR}/mysql-error.log
Slow query log: ${LOG_DIR}/mysql-slow.log
