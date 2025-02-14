# Apache Konfigurácia

## Základné nastavenie Apache

### 1. Virtuálny host pre HTTP
<VirtualHost *:80>
    ServerName ddns.vasa-domena.com
    DocumentRoot /var/www/html
    
    # Presmerovanie na HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

### 2. Virtuálny host pre HTTPS
<VirtualHost *:443>
    ServerName ddns.vasa-domena.com
    DocumentRoot /var/www/html
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/ddns.vasa-domena.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/ddns.vasa-domena.com/privkey.pem
    
    # Bezpečnostné hlavičky
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

## Zabezpečenie

### 1. Základné nastavenia
# Vypnutie zobrazenia verzie Apache
ServerTokens Prod
ServerSignature Off

# Zakázanie prehliadania adresárov
<Directory /var/www/html>
    Options -Indexes
    AllowOverride All
    Require all granted
</Directory>

### 2. ModSecurity pravidlá
# Základné pravidlá pre API
SecRule REQUEST_METHOD "!^(GET)$" "deny,status:405,id:1"
SecRule ARGS:hostname "!^[a-zA-Z0-9.-]+$" "deny,status:400,id:2"
SecRule ARGS:password "^$" "deny,status:400,id:3"

## Logovanie

### 1. Nastavenie logov
LogLevel warn
ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined

### 2. Log rotácia
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
CustomLog ${APACHE_LOG_DIR}/access.log combined

## Výkon

### 1. MPM nastavenia
<IfModule mpm_prefork_module>
    StartServers 5
    MinSpareServers 5
    MaxSpareServers 10
    MaxRequestWorkers 150
    MaxConnectionsPerChild 0
</IfModule>

### 2. Cache nastavenia
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
</IfModule>

## Monitoring
- Sledujte error.log pre chyby
- Kontrolujte access.log pre podozrivé prístupy
- Monitorujte využitie zdrojov
