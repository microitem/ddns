# DDNS Server pre DS223

## Prehľad
Tento projekt poskytuje DDNS (Dynamic DNS) server špeciálne navrhnutý pre potreby Synology DS223 NAS zariadenia. Všetky konfiguračné premenné sú štandardizované a dokumentované v [configuration/variables.md](configuration/variables.md).

## Rýchly štart
1. Naklonujte repozitár
2. Nastavte premenné prostredia podľa [configuration/variables.md](configuration/variables.md)
3. Spustite pomocou docker-compose
4. Nakonfigurujte DNS záznamy

## Štruktúra dokumentácie
- [Inštalácia](installation/)
  - [Nastavenie VPS](installation/vps-setup.md)
  - [Docker inštalácia](installation/docker-setup.md)
  - [Počiatočná konfigurácia](installation/initial-configuration.md)
- [Konfigurácia](configuration/)
  - [Štandardné premenné](configuration/variables.md)
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
- Docker Engine 20.10+
- Docker Compose 2.0+
- 1GB RAM
- 20GB priestoru na disku
- Verejná IP adresa
- Zaregistrovaná doména

## Bezpečnostné odporúčania
Pozrite si [security.md](configuration/security.md) pre komplexné bezpečnostné nastavenia.

## Podpora
- Hlásenie chýb: GitHub Issues
- Dokumentácia: /docs
- Príspevky: Pull Requests sú vítané

## Licencia
MIT License - pozrite [LICENSE](../LICENSE)
