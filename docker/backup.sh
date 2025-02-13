#!/bin/bash
BACKUP_DIR="/var/www/ddns/docker/backups"
mkdir -p "$BACKUP_DIR"
DATE=$(date +%Y%m%d_%H%M%S)
docker exec ddns_mysql mysqldump -u root -proot1234 pdns > "$BACKUP_DIR/pdns_$DATE.sql"
find "$BACKUP_DIR" -type f -mtime +7 -delete
