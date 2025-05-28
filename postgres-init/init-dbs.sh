#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "Checking for and creating database: $OPENWEBUI_DB_NAME"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO
    $do$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${OPENWEBUI_DB_NAME}') THEN
            CREATE DATABASE "${OPENWEBUI_DB_NAME}";
        END IF;
    END
    $do$;
EOSQL

echo "PostgreSQL: Checked/Created database '$OPENWEBUI_DB_NAME' for OpenWebUI."
