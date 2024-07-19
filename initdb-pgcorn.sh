#! /bin/bash

set -e
set -u

## Setting up pg_cron.
function pg_cron() {
    local db="postgres"

    echo "Creating pg_cron extension."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
        CREATE EXTENSION pg_cron;
EOSQL

    # Required to load pg_cron.
    pg_ctl restart
}

## Main.
if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Setting up pg_cron."
    pg_cron

    echo "Databases creation requested: $POSTGRES_MULTIPLE_DATABASES."

    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr "," " "); do
        if [ $db == "db_1" ]; then
            create_user_and_database $db "db_1"
            partitioning_management $db "db_1"
        elif [ $db == "db_2" ]; then
            create_user_and_database $db "db_2"
            partitioning_management $db "db_2"
        fi
    done

    echo "Databases created."
fi