#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# This script is run when the PostgreSQL container starts for the first time.
# It creates an additional database for OpenWebUI.
# The main database (defined by POSTGRES_DB in .env) is created automatically by the postgres image.

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE ${OPENWEBUI_DB_NAME}'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${OPENWEBUI_DB_NAME}')\gexec
EOSQL

echo "PostgreSQL: Checked/Created database '$OPENWEBUI_DB_NAME' for OpenWebUI."
