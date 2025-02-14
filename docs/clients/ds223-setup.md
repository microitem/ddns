# Konfigurácia Synology DS223

## Príprava
1. Prihláste sa do DSM (Synology DiskStation Manager)
2. Otvorte Control Panel
3. Prejdite do sekcie External Access

## Nastavenie DDNS

### 1. Pridanie vlastného DDNS poskytovateľa
- V sekcii DDNS kliknite na "Add"
- Vyberte "Custom Provider"
- Vyplňte nasledujúce údaje:
  - Hostname: nas.vasa-domena.com
  - Provider URL: http://vasa-domena.com/api.php?hostname=__HOSTNAME__&password=__PASSWORD__&ip=__MYIP__
  - Prihlasovacie údaje podľa vašej konfigurácie

### 2. Nastavenie portov
V sekcii "Router Configuration":
- Povoľte automatické presmerovanie portov
- Nastavte potrebné služby:
  - DSM (5000, 5001)
  - File Station (80, 443)
  - Ďalšie služby podľa potreby

### 3. Bezpečnostné nastavenia
V Control Panel > Security:
- Povoľte firewall
- Nastavte automatické blokovanie
- Povoľte 2-faktorovú autentifikáciu
- Nakonfigurujte HTTPS certifikát

## Overenie nastavení
1. Test DDNS:
   - Počkajte 5 minút na aktualizáciu
   - Skúste prístup cez nas.vasa-domena.com
   
2. Test portov:
   - Overte prístup cez HTTPS
   - Skontrolujte všetky povolené služby

## Riešenie problémov
- Skontrolujte logy v Log Center
- Overte nastavenia firewallu
- Skontrolujte pripojenie k internetu
- Overte nastavenia routera
