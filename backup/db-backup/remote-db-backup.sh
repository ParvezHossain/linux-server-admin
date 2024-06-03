#!/bin/bash

#----------------------------------------
# OPTIONS
#----------------------------------------
USER=${MYSQL_USER:-'root'}           # MySQL User, fallback to 'root' if not set
PASSWORD=${MYSQL_PASSWORD:-'plc-db'} # MySQL Password, fallback to 'plc-db' if not set
HOST=${MYSQL_HOST:-'192.168.1.231'}   # MySQL Host, fallback to '127.0.0.1' if not set
PORT=${MYSQL_PORT:-3306}             # MySQL Port, fallback to 3306 if not set
DAYS_TO_KEEP=${DAYS_TO_KEEP:-5}      # Days to keep backups, fallback to 5 if not set
GZIP=${GZIP:-0}                      # 1 = Compress, fallback to 0 if not set
BACKUP_PATH=${BACKUP_PATH:-'/var/www/html/mysql'}
#----------------------------------------

# Exit on error
set -euo pipefail

# Ensure backup path exists with secure permissions
if [ ! -d "$BACKUP_PATH" ]; then
    mkdir -p "$BACKUP_PATH"
    chmod 700 "$BACKUP_PATH"
fi

# If you don't need to back up views, you can exclude them:
# mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --skip-lock-tables --no-data --routines --triggers --events --no-create-db --no-create-info --skip-comments --databases "$db" > "$BACKUP_PATH/$date-$db-schema.sql"
# mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --skip-lock-tables --no-create-db --skip-triggers --skip-routines --skip-events --skip-comments --databases "$db" > "$BACKUP_PATH/$date-$db-data.sql"

# -----------------------------------------------

# If you need views, you can dump them as tables using the --single-transaction option and avoid locking tables:
# mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --single-transaction --routines --triggers --events --databases "$db" > "$backup_file"

# Get list of database names
databases=$(mysql -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" -e "SHOW DATABASES;" | tr -d "|" | grep -vE 'Database|information_schema|performance_schema|mysql|sys|phpmyadmin|base_visu_backup')

for db in $databases; do
    date=$(date -I)
    backup_file="$BACKUP_PATH/$date-$db.sql"

    if [ "$GZIP" -eq 0 ]; then
        echo "Backing up database: $db without compression"
        if ! mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --databases "$db" >"$backup_file"; then
            echo "Failed to back up database: $db" >&2
            exit 1
        fi
    else
        echo "Backing up database: $db with compression"
        backup_file="$BACKUP_PATH/$date-$db.sql.gz"
        if ! mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --databases "$db" | gzip -c >"$backup_file"; then
            echo "Failed to back up database: $db" >&2
            exit 1
        fi
    fi

    # Set secure permissions for the backup file
    chmod 600 "$backup_file"
done

# Delete old backups
if [ "$DAYS_TO_KEEP" -gt 0 ]; then
    echo "Deleting backups older than $DAYS_TO_KEEP days"
    find "$BACKUP_PATH"/* -mtime +"$DAYS_TO_KEEP" -exec rm {} \;
fi
