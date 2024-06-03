#!/bin/bash

#----------------------------------------
# OPTIONS
#----------------------------------------
USER=${MYSQL_USER:-'root'}           # MySQL User, fallback to 'root' if not set
PASSWORD=${MYSQL_PASSWORD:-'plc-db'} # MySQL Password, fallback to 'plc-db' if not set
HOST=${MYSQL_HOST:-'127.0.0.1'}      # MySQL Host, fallback to '127.0.0.1' if not set
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

# Get list of database names
databases=$(mysql -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" -e "SHOW DATABASES;" | tr -d "|" | grep -vE 'Database|information_schema|performance_schema|mysql|sys|phpmyadmin')

for db in $databases; do
    date=$(date -I)
    schema_backup_file="$BACKUP_PATH/$date-$db-schema.sql"
    data_backup_file="$BACKUP_PATH/$date-$db-data.sql"

    echo "Backing up database schema: $db"
    if [ "$GZIP" -eq 0 ]; then
        if ! mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --single-transaction --no-data --routines --triggers --events --databases "$db" > "$schema_backup_file"; then
            echo "Failed to back up database schema: $db" >&2
            exit 1
        fi
    else
        schema_backup_file="$BACKUP_PATH/$date-$db-schema.sql.gz"
        if ! mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --single-transaction --no-data --routines --triggers --events --databases "$db" | gzip -c > "$schema_backup_file"; then
            echo "Failed to back up database schema: $db" >&2
            exit 1
        fi
    fi

    echo "Backing up database data: $db"
    if [ "$GZIP" -eq 0 ]; then
        if ! mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --single-transaction --no-create-info --databases "$db" > "$data_backup_file"; then
            echo "Failed to back up database data: $db" >&2
            exit 1
        fi
    else
        data_backup_file="$BACKUP_PATH/$date-$db-data.sql.gz"
        if ! mysqldump -h"$HOST" -P"$PORT" -u"$USER" -p"$PASSWORD" --single-transaction --no-create-info --databases "$db" | gzip -c > "$data_backup_file"; then
            echo "Failed to back up database data: $db" >&2
            exit 1
        fi
    fi

    # Set secure permissions for the backup files
    chmod 600 "$schema_backup_file"
    chmod 600 "$data_backup_file"
done

# Delete old backups
if [ "$DAYS_TO_KEEP" -gt 0 ]; then
    echo "Deleting backups older than $DAYS_TO_KEEP days"
    find "$BACKUP_PATH"/* -mtime +"$DAYS_TO_KEEP" -exec rm {} \;
fi
