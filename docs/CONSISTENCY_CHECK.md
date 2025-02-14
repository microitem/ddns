# Kontrola konzistencie dokumentácie

## 1. Premenné a hodnoty
- MYSQL_DATABASE: powerdns (konzistentné vo všetkých súboroch)
- MYSQL_USER: powerdns (konzistentné)
- Porty: 53, 80, 443, 22 (konzistentné)
- Príklady domén: vasa-domena.com, nas.vasa-domena.com (zjednotiť)

## 2. Krížové referencie na doplnenie
- docker-setup.md potrebuje odkaz na initial-configuration.md
- security.md potrebuje odkazy na apache.md a mysql.md
- router-setup.md potrebuje odkaz na ddns-client.md
- api/endpoints.md potrebuje odkaz na security.md

## 3. Chýbajúce informácie
- Postup aktualizácie celého systému
- Postup migrácie na novú verziu
- Detailný troubleshooting pre DS223
- Príklady pokročilej konfigurácie

## 4. Návrhy na zlepšenie
- Pridať sekciu FAQ
- Pridať príklady reálneho nasadenia
- Pridať sekciu s najlepšími postupmi
- Vytvoriť quick-start príručku

## 5. Technické detaily na zjednotenie
- Formát príkazov (konzistentné odsadenie)
- Štruktúra konfigurácií
- Formát logov
- Bezpečnostné odporúčania
