#!/bin/bash

# Kontrola služieb
echo "=== Služby ==="
systemctl status apache2 | grep "Active:"
docker ps --format "{{.Names}}: {{.Status}}"

# Kontrola DNS
echo -e "\n=== DNS Záznamy ==="
dig @localhost ns1.goodboog.com A +short
dig @localhost test.ns1.goodboog.com A +short

# Kontrola záloh
echo -e "\n=== Zálohy ==="
ls -l /var/www/ddns/docker/backups/ | tail -n 5

# Kontrola logov
echo -e "\n=== Posledné chyby ==="
tail -n 5 /var/log/apache2/ddns-error.log

# Kontrola stavu služieb
if ! systemctl is-active --quiet apache2 || ! docker ps | grep -q "ddns_pdns.*healthy" || ! docker ps | grep -q "ddns_mysql.*healthy"; then
    echo "ALERT: Jedna alebo viac služieb nie je aktívnych!" | mail -s "DDNS Monitor Alert" admin@goodboog.com
fi
