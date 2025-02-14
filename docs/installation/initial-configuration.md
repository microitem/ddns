# Počiatočná konfigurácia DDNS servera

## Príprava prostredia

### 1. Konfiguračné súbory
Vytvorte súbor `.env` s nasledujúcimi premennými:
MYSQL_ROOT_PASSWORD=silne_root_heslo
MYSQL_DATABASE=powerdns
MYSQL_USER=powerdns
MYSQL_PASSWORD=silne_heslo
PDNS_API_KEY=api_kluc_pre_powerdns

### 2. Inicializácia databázy
Po prvom spustení sa automaticky vytvorí databázová schéma pomocou sql/init.sql

## Konfigurácia domény

### 1. Pridanie domény
Pripojte sa k MySQL a pridajte doménu:
docker exec -it ddns_db_1 mysql -upowerdns -p powerdns

INSERT INTO domains (name, type) VALUES ('vasa-domena.com', 'NATIVE');
INSERT INTO records (domain_id, name, type, content, ttl) 
SELECT id, 'nas.vasa-domena.com', 'A', '192.168.1.100', 300 
FROM domains WHERE name='vasa-domena.com';

### 2. Nastavenie DNS
U vášho registrátora domény nastavte NS záznamy na váš server:
- ns1.vasa-domena.com -> IP adresa vášho servera
- ns2.vasa-domena.com -> IP adresa vášho servera

## Konfigurácia webového servera

### 1. SSL certifikát
Získajte SSL certifikát (napríklad Let's Encrypt):
certbot certonly --webroot -w /var/www/html -d vasa-domena.com

### 2. Apache konfigurácia
Upravte Apache konfiguráciu pre HTTPS:
<VirtualHost *:443>
    ServerName vasa-domena.com
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/vasa-domena.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/vasa-domena.com/privkey.pem
</VirtualHost>

## Zabezpečenie

### 1. Firewall
Povoľte len potrebné porty:
- 53 (TCP/UDP) pre DNS
- 80/443 pre web
- 22 pre SSH

### 2. API prístup
V config.php nastavte povolené IP adresy:
$allowed_ips = array(
    '192.168.1.0/24',
    'xxx.xxx.xxx.xxx'
);

## Testovanie

### 1. Test DNS
dig @localhost nas.vasa-domena.com
dig @8.8.8.8 nas.vasa-domena.com

### 2. Test API
curl "http://vasa-domena.com/api.php?hostname=nas.vasa-domena.com&password=heslo"

### 3. Test HTTPS
Otvorte https://vasa-domena.com v prehliadači

## Monitoring
- Nastavte monitoring dostupnosti
- Nakonfigurujte notifikácie
- Sledujte systémové logy
