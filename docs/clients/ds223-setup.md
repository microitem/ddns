# Konfigurácia Synology DS223

## DDNS nastavenie
1. Control Panel > External Access > DDNS
2. Add > Custom Provider
3. Nastavenia:
   - Hostname: ${EXAMPLE_SUBDOMAIN}
   - Provider URL: http://${EXAMPLE_DOMAIN}${API_ENDPOINT}?hostname=__HOSTNAME__&password=__PASSWORD__&ip=__MYIP__
   - Interval aktualizácie: ${REFRESH_INTERVAL}

## Porty
1. Control Panel > Network > Port Forwarding
   - HTTP: ${PORTS_HTTP}
   - HTTPS: ${PORTS_HTTPS}
   - SSH: ${PORTS_SSH}

## SSL certifikát
1. Control Panel > Security > Certificate
2. Add > Let's Encrypt
3. Domain: ${EXAMPLE_SUBDOMAIN}

## Bezpečnosť
1. Control Panel > Security
   - Enable firewall
   - Enable auto-block
   - Enable 2FA
   - Enable HTTPS only

## Logovanie
- Log Center > Log Search
- Filter: DDNS updates
- Export: ${LOG_DIR}/ds223_ddns.log

## Riešenie problémov
1. Test DDNS:
   curl -v "http://${EXAMPLE_DOMAIN}${API_ENDPOINT}?hostname=${EXAMPLE_SUBDOMAIN}&password=heslo"

2. Test portov:
   nc -zv ${EXAMPLE_SUBDOMAIN} ${PORTS_HTTP}
   nc -zv ${EXAMPLE_SUBDOMAIN} ${PORTS_HTTPS}
