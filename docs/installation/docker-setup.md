# Docker inštalácia a konfigurácia

## Požiadavky
- Docker Engine
- Docker Compose
- Git

## Inštalácia

1. Naklonovanie repozitára:
git clone https://github.com/microitem/ddns.git
cd ddns

2. Konfigurácia premenných prostredia:
Vytvorte súbor `.env` s nasledujúcim obsahom:
MYSQL_ROOT_PASSWORD=zmente_toto_heslo
MYSQL_DATABASE=powerdns
MYSQL_USER=powerdns
MYSQL_PASSWORD=zmente_toto_heslo
PDNS_API_KEY=zmente_toto_heslo

3. Spustenie služieb:
docker-compose up -d

## Overenie inštalácie

1. Kontrola bežiacich kontajnerov:
docker-compose ps

2. Kontrola logov:
docker-compose logs

## Údržba

### Reštart služieb
docker-compose restart

### Aktualizácia kontajnerov
docker-compose pull
docker-compose up -d
