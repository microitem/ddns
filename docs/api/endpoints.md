# API Dokumentácia

## Aktualizácia DNS záznamu

### Endpoint
`GET /api.php`

### Parametre
- `hostname` - Názov hostiteľa na aktualizáciu
- `password` - Heslo pre autentifikáciu
- `ip` - Nová IP adresa (voliteľné, ak nie je zadané, použije sa IP adresa klienta)

### Príklad použitia
http://ddns.example.com/api.php?hostname=nas.example.com&password=tajneheslo

### Odpovede
- `OK` - Aktualizácia prebehla úspešne
- `FAIL` - Aktualizácia zlyhala
- `BADAUTH` - Nesprávne prihlasovacie údaje
- `NOTFQDN` - Neplatný formát hostname
- `NOHOST` - Hostname neexistuje v konfigurácii

### Bezpečnostné odporúčania
- Používajte HTTPS pre zabezpečenú komunikáciu
- Používajte silné heslá
- Obmedzte prístup k API len na potrebné IP adresy
