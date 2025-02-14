# SSL Certifikáty cez Nginx Proxy Manager

## Príprava
1. NPM musí byť nainštalovaný a bežať v Dockeri
2. DNS záznamy musia byť správne nakonfigurované
3. Porty 80 a 443 musia byť dostupné

## Postup v NPM

1. Prihlásenie do NPM
- Otvorte webové rozhranie NPM (štandardne port 81)
- Prihláste sa s admin účtom

2. Pridanie Proxy Host
- Kliknite na "Proxy Hosts" -> "Add Proxy Host"
- Domain Names: ${EXAMPLE_DOMAIN}, ${EXAMPLE_SUBDOMAIN}
- Scheme: http
- Forward Hostname: ddns_web
- Forward Port: 80
- Zaškrtnite "Block Common Exploits"

3. SSL Nastavenia
- V záložke SSL vyberte "Request a new SSL Certificate"
- Zaškrtnite "Force SSL"
- Vyberte "HTTP/2 Support"
- Kliknite "Save"

## Overenie
1. Otestujte HTTPS prístup na doménu
2. Skontrolujte platnosť certifikátu
3. Overte presmerovanie HTTP na HTTPS

## Údržba
- NPM automaticky obnovuje SSL certifikáty
- Platnosť môžete kontrolovať v NPM rozhraní
- Logy nájdete v NPM -> "Logs"
