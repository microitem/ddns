# Apache Konfigurácia

## Základné nastavenie
Konfigurácia v docker-compose.yml:

version: '3'
services:
  web:
    image: httpd:2.4
    container_name: ddns_web
    ports:
      - "${PORTS_HTTP}:80"
      - "${PORTS_HTTPS}:443"
    volumes:
      - ${BASE_DIR}/www:/var/www/html
      - ${CONFIG_DIR}/apache:/etc/apache2/sites-enabled
      - ${LOG_DIR}:/var/log/apache2
    restart: unless-stopped

## Virtuálny host pre HTTP
<VirtualHost *:${PORTS_HTTP}>
    ServerName ${EXAMPLE_DOMAIN}
    DocumentRoot /var/www/html
    
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    ErrorLog ${LOG_DIR}/error.log
    CustomLog ${LOG_DIR}/access.log combined
</VirtualHost>

## Virtuálny host pre HTTPS
<VirtualHost *:${PORTS_HTTPS}>
    ServerName ${EXAMPLE_DOMAIN}
    DocumentRoot /var/www/html
    
    SSLEngine on
    SSLCertificateFile ${CONFIG_DIR}/ssl/fullchain.pem
    SSLCertificateKeyFile ${CONFIG_DIR}/ssl/privkey.pem
    
    Header always set Strict-Transport-Security "max-age=31536000"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    
    ErrorLog ${LOG_DIR}/error.log
    CustomLog ${LOG_DIR}/access.log combined
</VirtualHost>

## ModSecurity pravidlá
SecRule REQUEST_METHOD "!^(GET)$" "deny,status:405,id:1"
SecRule ARGS:hostname "!^[a-zA-Z0-9.-]+$" "deny,status:400,id:2"
SecRule ARGS:password "^$" "deny,status:400,id:3"

## Výkonnostné nastavenia
<IfModule mpm_prefork_module>
    StartServers 5
    MinSpareServers 5
    MaxSpareServers 10
    MaxRequestWorkers 150
    MaxConnectionsPerChild 0
</IfModule>

## Monitoring
tail -f ${LOG_DIR}/access.log
tail -f ${LOG_DIR}/error.log

## Údržba
1. Rotácia logov:
logrotate -f ${CONFIG_DIR}/logrotate.conf

2. Kontrola konfigurácie:
docker-compose exec web apache2ctl -t

3. Reštart služby:
docker-compose restart web
