#!/bin/bash

#----------------------------------------
# OPTIONS
#----------------------------------------
USER=${MYSQL_USER:-'root'}       # MySQL User, fallback to 'root' if not set
PASSWORD=${MYSQL_PASSWORD:-'plc-db'} # MySQL Password, fallback to 'plc-db' if not set
DAYS_TO_KEEP=${DAYS_TO_KEEP:-5}  # Days to keep backups, fallback to 5 if not set
GZIP=${GZIP:-0}                  # 1 = Compress, fallback to 0 if not set
BACKUP_PATH=${BACKUP_PATH:-'/var/www/html/mysql'}
#----------------------------------------

# Exit on error
set -euo pipefail

# Ensure backup path exists with secure permissions
if [ ! -d "$BACKUP_PATH" ]; then
    mkdir -p "$BACKUP_PATH"
    chmod 700 "$BACKUP_PATH"
fi

# Get list of database names
databases=$(mysql -u"$USER" -p"$PASSWORD" -e "SHOW DATABASES;" | tr -d "|" | grep -vE 'Database|information_schema|performance_schema|mysql|sys|phpmyadmin')

for db in $databases; do
    date=$(date -I)
    backup_file="$BACKUP_PATH/$date-$db.sql"
    
    if [ "$GZIP" -eq 0 ]; then
        echo "Backing up database: $db without compression"
        if ! mysqldump -u"$USER" -p"$PASSWORD" --databases "$db" > "$backup_file"; then
            echo "Failed to back up database: $db" >&2
            exit 1
        fi
    else
        echo "Backing up database: $db with compression"
        backup_file="$BACKUP_PATH/$date-$db.sql.gz"
        if ! mysqldump -u"$USER" -p"$PASSWORD" --databases "$db" | gzip -c > "$backup_file"; then
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
