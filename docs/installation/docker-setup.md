# Docker inštalácia a konfigurácia

## Požiadavky
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

## Inštalácia

1. Klonujte repozitár do $BASE_DIR:
mkdir -p /opt/ddns
cd /opt/ddns
git clone https://github.com/microitem/ddns.git .

2. Vytvorte .env súbor:
cat > .env << EOF
MYSQL_ROOT_PASSWORD=<STRONG_ROOT_PASSWORD>
MYSQL_DATABASE=powerdns
MYSQL_USER=powerdns
MYSQL_PASSWORD=<STRONG_PASSWORD>
PDNS_API_KEY=<STRONG_API_KEY>
EOF

3. Spustite služby:
docker-compose up -d

## Overenie inštalácie
docker-compose ps
docker-compose logs

## Údržba
# Reštart služieb
docker-compose restart

# Aktualizácia
docker-compose pull
docker-compose up -d

## Logovanie
mkdir -p /var/log/ddns
touch /var/log/ddns/docker.log
ln -s /var/log/ddns/docker.log $BASE_DIR/docker.log

## Zálohovanie
mkdir -p /var/backup/ddns
docker-compose exec db mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > /var/backup/ddns/backup_$(date +%Y%m%d).sql
