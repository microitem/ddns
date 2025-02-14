#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/docs.log
}

# Vytvorenie adresárovej štruktúry pre dokumentáciu
DOCS_DIR="docs"
mkdir -p ${DOCS_DIR}/{installation,configuration,maintenance,api,security}

# Generovanie hlavného README
cat > README.md << EOF
# DDNS Server Dokumentácia

## Obsah
1. [Inštalácia](docs/installation/README.md)
2. [Konfigurácia](docs/configuration/README.md)
3. [Údržba](docs/maintenance/README.md)
4. [API Dokumentácia](docs/api/README.md)
5. [Bezpečnosť](docs/security/README.md)

## Systémové požiadavky
- Ubuntu 20.04 LTS alebo novší
- Docker a Docker Compose
- Minimálne 2GB RAM
- 20GB voľného miesta na disku

## Rýchly štart
1. Klonujte repozitár
2. Skopírujte \`.env.example\` do \`.env\` a upravte
3. Spustite \`./setup-all.sh\`

## Licencia
MIT License
EOF

# Generovanie dokumentácie pre inštaláciu
cat > ${DOCS_DIR}/installation/README.md << EOF
# Inštalácia

## Príprava systému
1. [Systémové požiadavky](requirements.md)
2. [Inštalácia závislostí](dependencies.md)
3. [Sieťová konfigurácia](network.md)

## Inštalačný proces
1. [Základná inštalácia](basic-setup.md)
2. [Konfigurácia NPM](npm-setup.md)
3. [DNS nastavenia](dns-setup.md)
4. [SSL certifikáty](ssl-setup.md)

## Overenie inštalácie
1. [Kontrolný zoznam](checklist.md)
2. [Testovanie](testing.md)
3. [Riešenie problémov](troubleshooting.md)
EOF

# Generovanie dokumentácie pre API
cat > ${DOCS_DIR}/api/README.md << EOF
# API Dokumentácia

## Endpointy
- \`GET /api.php\`: Aktualizácia DNS záznamu

### Parametre
- \`hostname\`: Názov domény na aktualizáciu
- \`password\`: API kľúč pre autentifikáciu
- \`ip\`: (voliteľné) IP adresa pre záznam

### Odpovede
- \`OK\`: Úspešná aktualizácia
- \`BADAUTH\`: Neplatná autentifikácia
- \`NOHOST\`: Doména neexistuje
- \`FAIL\`: Všeobecná chyba

### Príklad
\`\`\`bash
curl "http://example.com/api.php?hostname=sub.example.com&password=secret"
\`\`\`
EOF

log_message "Dokumentácia bola vygenerovaná"
echo "Dokumentácia bola vygenerovaná v adresári: ${DOCS_DIR}"
echo "Skontrolujte logy: ${LOG_DIR}/docs.log"
