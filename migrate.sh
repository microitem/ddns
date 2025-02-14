#!/bin/bash

# Načítanie premenných
source .env

# Funkcia pre logovanie
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${LOG_DIR}/migrate.log
}

# Funkcia pre spustenie SQL súboru
run_sql() {
    local file=$1
    log_message "Spúšťam migráciu: $file"
    docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < "$file"
}

# Kontrola migračného adresára
MIGRATE_DIR="${BASE_DIR}/migrations"
if [ ! -d "$MIGRATE_DIR" ]; then
    mkdir -p "$MIGRATE_DIR"
    log_message "Vytvorený migračný adresár: $MIGRATE_DIR"
fi

# Vytvorenie tabuľky pre sledovanie migrácií
cat > "${MIGRATE_DIR}/000_init.sql" << EOF
CREATE TABLE IF NOT EXISTS migrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('success', 'failed') NOT NULL
);
EOF

run_sql "${MIGRATE_DIR}/000_init.sql"

# Spracovanie všetkých migrácií
for file in ${MIGRATE_DIR}/*.sql; do
    # Preskočenie init súboru
    if [[ "$file" == "${MIGRATE_DIR}/000_init.sql" ]]; then
        continue
    fi

    # Kontrola či migrácia už bola aplikovaná
    filename=$(basename "$file")
    applied=$(docker-compose exec -T db mysql -N -s -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        -e "SELECT COUNT(*) FROM migrations WHERE filename='$filename' AND status='success'")

    if [ "$applied" -eq "0" ]; then
        log_message "Aplikujem novú migráciu: $filename"
        
        # Začiatok transakcie
        echo "START TRANSACTION;" > "${MIGRATE_DIR}/temp.sql"
        cat "$file" >> "${MIGRATE_DIR}/temp.sql"
        echo "INSERT INTO migrations (filename, status) VALUES ('$filename', 'success');" >> "${MIGRATE_DIR}/temp.sql"
        echo "COMMIT;" >> "${MIGRATE_DIR}/temp.sql"

        if run_sql "${MIGRATE_DIR}/temp.sql"; then
            log_message "Migrácia úspešná: $filename"
        else
            log_message "Migrácia zlyhala: $filename"
            docker-compose exec -T db mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
                -e "INSERT INTO migrations (filename, status) VALUES ('$filename', 'failed')"
            rm "${MIGRATE_DIR}/temp.sql"
            exit 1
        fi

        rm "${MIGRATE_DIR}/temp.sql"
    else
        log_message "Migrácia už bola aplikovaná: $filename"
    fi
done

log_message "Všetky migrácie boli dokončené"
echo "Migrácie boli dokončené"
echo "Skontrolujte logy: ${LOG_DIR}/migrate.log"
