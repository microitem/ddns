# API Dokumentácia

## Aktualizácia DNS záznamu

### Endpoint
GET ${API_ENDPOINT}

### Parametre
- hostname: Názov hostiteľa (povinné)
- password: Heslo pre autentifikáciu (povinné)
- ip: Nová IP adresa (voliteľné)

### Príklad
http://${EXAMPLE_DOMAIN}${API_ENDPOINT}?hostname=${EXAMPLE_SUBDOMAIN}&password=heslo

### Odpovede
- OK: Aktualizácia úspešná
- BADAUTH: Nesprávne heslo
- NOTFQDN: Neplatný hostname
- NOHOST: Hostname neexistuje
- FAIL: Iná chyba

### Limity
- Rate limit: 60 požiadaviek/minútu
- Timeout: 10 sekúnd
- Max dĺžka hostname: 255 znakov

### Logy
Všetky požiadavky sa logujú do ${LOG_DIR}/api.log
