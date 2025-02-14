# Nginx Proxy Manager Nastavenie

## Sieťová konfigurácia
1. Vytvorenie Docker siete:
docker network create ddns_net

## NPM Docker Compose
Vytvorte súbor `npm-compose.yml`:

version: '3'
services:
  npm:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: npm
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    volumes:
      - ${BASE_DIR}/npm/data:/data
      - ${BASE_DIR}/npm/letsencrypt:/etc/letsencrypt
    networks:
      - ddns_net

networks:
  ddns_net:
    external: true

## Počiatočná konfigurácia NPM

1. Prístup do admin rozhrania:
   - URL: http://vas-server:81
   - Email: admin@example.com
   - Heslo: changeme

2. Zmena admin hesla:
   - Settings > Change Password
   - Nastavte silné heslo

3. Proxy Host nastavenie:
   - Proxy Hosts > Add Proxy Host
   - Domain Names: ${EXAMPLE_DOMAIN}
   - Scheme: http
   - Forward Hostname: ddns_web
   - Forward Port: 80
   - SSL: Request a new certificate
   - Force SSL: Enabled

## Údržba
- Zálohy: ${BACKUP_DIR}/npm/
- Logy: ${LOG_DIR}/npm/
- Certifikáty: automatická obnova
