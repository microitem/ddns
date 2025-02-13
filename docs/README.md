# DDNS Server

## API Endpoint
- URL: http://ns1.goodboog.com/api/
- Metóda: GET
- Autentifikácia: Basic Auth

### Parametre
- hostname: názov záznamu (bez domény)
- ip: IP adresa (voliteľné, predvolene použije IP klienta)

### Príklad použitia
curl -u ddns_user:PASSWORD "http://ns1.goodboog.com/api/?hostname=test&ip=1.2.3.4"

## Klientsky skript
./ddns-client.sh

## Konfigurácia
- PowerDNS API: http://localhost:8081
- Zóna: ns1.goodboog.com
- TTL: 60 sekúnd

## Docker Konfigurácia
- PowerDNS kontajner
- MySQL kontajner pre DNS záznamy
- Automatické zálohy databázy

## Apache Konfigurácia
- Virtual host: ddns.conf
- Subdoména: ds223.conf
- Bezpečnostné nastavenia: ddns-security.conf

## Autentifikácia
- Basic Auth pre API
- Konfigurácia v .htaccess
- Používatelia v .htpasswd

## Zálohy
- Umiestnenie: /var/www/ddns/docker/backups/
- Formát: pdns_YYYYMMDD_HHMMSS.sql
- Automatické zálohovanie databázy

## Štruktúra projektu
/var/www/ddns/
├── api/                 # API endpoint
├── docs/               # Dokumentácia
│   └── config/         # Konfiguračné súbory
├── docker/             # Docker konfigurácia
└── ddns-client.sh      # Klientsky skript
