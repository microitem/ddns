# DDNS Server pre DS223

## Prehľad
Tento projekt poskytuje DDNS (Dynamic DNS) server špeciálne navrhnutý pre potreby Synology DS223 NAS zariadenia.

## Štruktúra dokumentácie
- [Inštalácia](installation/)
  - [Nastavenie VPS](installation/vps-setup.md)
  - [Docker inštalácia](installation/docker-setup.md)
  - [Počiatočná konfigurácia](installation/initial-configuration.md)
- [Konfigurácia](configuration/)
  - [PowerDNS](configuration/powerdns.md)
  - [Apache](configuration/apache.md)
  - [MySQL](configuration/mysql.md)
  - [Bezpečnosť](configuration/security.md)
- [Klientske nastavenia](clients/)
  - [Nastavenie routera](clients/router-setup.md)
  - [Konfigurácia DS223](clients/ds223-setup.md)
  - [DDNS klient](clients/ddns-client.md)
- [API dokumentácia](api/endpoints.md)
- [Údržba](maintenance/)
  - [Zálohovanie](maintenance/backup.md)
  - [Riešenie problémov](maintenance/troubleshooting.md)

## Požiadavky
- Docker a Docker Compose
- Verejná IP adresa alebo VPS
- Zaregistrovaná doména
