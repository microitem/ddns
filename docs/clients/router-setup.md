# Nastavenie routera pre DDNS

## Podporované routery
Tento návod je primárne určený pre routery s podporou vlastných DDNS poskytovateľov.

## Všeobecné nastavenie

### 1. Prístup k nastaveniam routera
- Otvorte webové rozhranie routera (typicky 192.168.1.1 alebo 192.168.0.1)
- Prihláste sa s admin právami
- Nájdite sekciu DDNS alebo Dynamic DNS

### 2. Konfigurácia DDNS
Vyplňte nasledujúce údaje:
- DDNS Poskytovateľ: Vlastný
- Update URL: http://vasa-domena.com/api.php?hostname=[DOMAIN]&password=[PASSWORD]&ip=[IP]
- Hostname: nas.vasa-domena.com
- Heslo: vaše_bezpečné_heslo
- Interval aktualizácie: 300 (5 minút)

### 3. Port forwarding
Nastavte presmerovanie portov pre DS223:
- HTTP (port 80) -> IP adresa DS223
- HTTPS (port 443) -> IP adresa DS223
- Ďalšie porty podľa potreby

## Špecifické nastavenia pre rôzne modely

### Mikrotik
/ip cloud
set ddns-enabled=yes
set ddns-update-interval=5m
set update-url="http://vasa-domena.com/api.php\?hostname=nas.vasa-domena.com&password=heslo"

### OpenWrt
Vytvorte skript `/etc/ddns/custom.sh`:
#!/bin/sh
curl -s "http://vasa-domena.com/api.php?hostname=nas.vasa-domena.com&password=heslo&ip=$1"

## Overenie funkčnosti
1. Skontrolujte logy routera
2. Overte aktualizáciu IP pomocou:
   dig nas.vasa-domena.com

## Riešenie problémov
- Skontrolujte internetové pripojenie
- Overte správnosť URL a parametrov
- Skontrolujte firewall nastavenia
- Overte logy na DDNS serveri
