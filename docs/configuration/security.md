# Bezpečnostné nastavenia

## Systémové zabezpečenie

1. Firewall pravidlá:
ufw default deny incoming
ufw default allow outgoing
ufw allow ${PORTS_SSH}/tcp
ufw allow ${PORTS_DNS_TCP}/tcp
ufw allow ${PORTS_DNS_UDP}/udp
ufw allow ${PORTS_HTTP}/tcp
ufw allow ${PORTS_HTTPS}/tcp
ufw enable

2. SSH zabezpečenie:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers ${SYSTEM_USER}
Protocol 2
MaxAuthTries 3

3. Fail2ban konfigurácia:
[ddns-auth]
enabled = true
filter = ddns-auth
logpath = ${LOG_DIR}/auth.log
maxretry = 3
bantime = 3600

## PowerDNS zabezpečenie

1. API konfigurácia:
api=yes
api-key=${PDNS_API_KEY}
webserver=yes
webserver-address=${PDNS_WEBSERVER_ADDRESS}
webserver-allow-from=127.0.0.1
webserver-password=${PDNS_API_KEY}

2. DNS zabezpečenie:
allow-axfr-ips=127.0.0.1
disable-axfr=yes
local-address=0.0.0.0
local-port=${PORTS_DNS_TCP}

## MySQL zabezpečenie

1. Prístupové práva:
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
REVOKE ALL PRIVILEGES ON ${MYSQL_DATABASE}.* FROM '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;

2. Zabezpečenie pripojenia:
bind-address = 127.0.0.1
ssl-cert = ${CONFIG_DIR}/mysql/server-cert.pem
ssl-key = ${CONFIG_DIR}/mysql/server-key.pem
require_secure_transport = ON

## Apache zabezpečenie

1. SSL/TLS konfigurácia:
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
SSLHonorCipherOrder on
SSLCompression off
SSLSessionTickets off

2. Bezpečnostné hlavičky:
Header always set Strict-Transport-Security "max-age=31536000"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"

## API zabezpečenie

1. Rate limiting:
<IfModule mod_ratelimit.c>
    <Location "${API_ENDPOINT}">
        SetOutputFilter RATE_LIMIT
        SetEnv rate-limit 60
    </Location>
</IfModule>

2. IP obmedzenia:
<Location "${API_ENDPOINT}">
    Order deny,allow
    Deny from all
    Allow from 127.0.0.1
    Allow from ${ALLOWED_IP_RANGES}
</Location>

## Monitoring a logovanie

1. Centralizované logovanie:
*.* @log-server:514

2. Log rotácia:
${LOG_DIR}/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 ${SYSTEM_USER} ${SYSTEM_GROUP}
}
