CREATE DATABASE IF NOT EXISTS pdns;
USE pdns;

CREATE TABLE IF NOT EXISTS domains (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255) NOT NULL,
  master                VARCHAR(128) DEFAULT NULL,
  last_check           INT DEFAULT NULL,
  type                  VARCHAR(6) NOT NULL,
  notified_serial      INT UNSIGNED DEFAULT NULL,
  account              VARCHAR(40) CHARACTER SET 'utf8' DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY name_index (name)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE IF NOT EXISTS records (
  id                    BIGINT AUTO_INCREMENT,
  domain_id            INT DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) DEFAULT NULL,
  content              VARCHAR(64000) DEFAULT NULL,
  ttl                   INT DEFAULT NULL,
  prio                  INT DEFAULT NULL,
  disabled             BOOLEAN DEFAULT 0,
  ordername            VARCHAR(255) BINARY DEFAULT NULL,
  auth                  BOOL DEFAULT 1,
  PRIMARY KEY (id),
  KEY nametype_index (name,type),
  KEY domain_id (domain_id),
  KEY ordername (ordername)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE IF NOT EXISTS supermasters (
  ip                    VARCHAR(64) NOT NULL,
  nameserver            VARCHAR(255) NOT NULL,
  account              VARCHAR(40) CHARACTER SET 'utf8' NOT NULL,
  PRIMARY KEY (ip, nameserver)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE IF NOT EXISTS comments (
  id                    INT AUTO_INCREMENT,
  domain_id            INT NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  type                  VARCHAR(10) NOT NULL,
  modified_at          INT NOT NULL,
  account              VARCHAR(40) CHARACTER SET 'utf8' DEFAULT NULL,
  comment              TEXT CHARACTER SET 'utf8' NOT NULL,
  PRIMARY KEY (id),
  KEY comments_domain_id_idx (domain_id),
  KEY comments_name_type_idx (name,type),
  KEY comments_order_idx (domain_id, modified_at)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE IF NOT EXISTS domainmetadata (
  id                    INT AUTO_INCREMENT,
  domain_id            INT NOT NULL,
  kind                  VARCHAR(32),
  content              TEXT,
  PRIMARY KEY (id),
  KEY domainmetadata_idx (domain_id, kind)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE IF NOT EXISTS cryptokeys (
  id                    INT AUTO_INCREMENT,
  domain_id            INT NOT NULL,
  flags                INT NOT NULL,
  active               BOOL,
  content              TEXT,
  PRIMARY KEY(id),
  KEY domainidindex (domain_id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE IF NOT EXISTS tsigkeys (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255),
  algorithm            VARCHAR(50),
  secret               VARCHAR(255),
  PRIMARY KEY (id),
  UNIQUE KEY namealgoindex (name, algorithm)
) Engine=InnoDB CHARACTER SET 'latin1';
