#! /bin/bash

set -e
set -u

# add conf
echo "shared_preload_libraries = 'pg_stat_monitor,pg_cron,pg_uuidv7'" >> /var/lib/postgresql/data/postgresql.conf
echo "cron.database_name = 'postgres'" >> /var/lib/postgresql/data/postgresql.conf
echo "cron.timezone = 'PRC'" >> /var/lib/postgresql/data/postgresql.conf
echo "timezone = 'Asia/Shanghai'" >> /var/lib/postgresql/data/postgresql.conf

"${psql[@]}" --dbname=postgres <<-'EOSQL'
CREATE EXTENSION IF NOT EXISTS pg_stat_monitor;
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
EOSQL

