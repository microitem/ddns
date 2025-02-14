# Bezpečnostné nastavenia DDNS servera

## Základné zabezpečenie servera

### 1. Aktualizácie systému
# Pravidelné aktualizácie
apt update
apt upgrade -y

# Automatické bezpečnostné aktualizácie
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

### 2. Firewall nastavenia
# Povolenie len potrebných portov
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 53/tcp
ufw allow 53/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

## Zabezpečenie služieb

### 1. SSH zabezpečenie
# Konfigurácia v /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers vaspouzivatel
Protocol 2
MaxAuthTries 3

### 2. PowerDNS zabezpečenie
# Konfigurácia v pdns.conf
allow-axfr-ips=127.0.0.1
webserver-address=127.0.0.1
webserver-allow-from=127.0.0.1
api-key=silne_heslo
master=yes
slave=no

### 3. MySQL zabezpečenie
# Obmedzenie prístupu
GRANT ALL PRIVILEGES ON powerdns.* TO 'powerdns'@'localhost';
REVOKE ALL PRIVILEGES ON powerdns.* FROM 'powerdns'@'%';
FLUSH PRIVILEGES;

## API zabezpečenie

### 1. Rate limiting
# Konfigurácia v Apache
<IfModule mod_ratelimit.c>
    <Location "/api.php">
        SetOutputFilter RATE_LIMIT
        SetEnv rate-limit 60
    </Location>
</IfModule>

### 2. IP obmedzenia
# Konfigurácia v config.php
$allowed_ips = array(
    '192.168.1.0/24',
    'doveryhodna.ip.adresa'
);

## SSL/TLS nastavenia

### 1. Let's Encrypt certifikát
# Inštalácia a nastavenie
certbot certonly --webroot -w /var/www/html -d ddns.vasa-domena.com
# Automatická obnova
certbot renew --dry-run

### 2. SSL konfigurácia Apache
# Moderné SSL nastavenia
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder on
SSLCompression off
SSLSessionTickets off

## Monitoring a logovanie

### 1. Fail2ban
# Inštalácia
apt install fail2ban

# Konfigurácia pre API
[ddns-api]
enabled = true
filter = ddns-api
logpath = /var/log/apache2/access.log
maxretry = 3
bantime = 3600

### 2. Logovanie
# Centralizované logy
rsyslog.conf konfigurácia pre vzdialený logging server
*.* @log-server:514

## Pravidelná údržba

### 1. Kontrolný zoznam
- Kontrola logov
- Aktualizácia systému
- Kontrola SSL certifikátov
- Zálohovanie databázy
- Kontrola oprávnení súborov
- Monitoring dostupnosti služby

### 2. Automatizácia
# Vytvorenie skriptu pre kontrolu
#!/bin/bash
# security-check.sh
# Kontrola služieb
systemctl status pdns
# Kontrola logov
grep ERROR /var/log/syslog
# Kontrola certifikátov
certbot certificates
