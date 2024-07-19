echo "cron.host = ''" >> /var/lib/postgresql/data/pg_hba.conf
echo "cron.database_name = 'postgres'" >> /var/lib/postgresql/data/postgresql.conf
echo "cron.timezone = 'PRC'" >> /var/lib/postgresql/data/postgresql.conf

su postgres -c 'psql -c "CREATE EXTENSION IF NOT EXISTS pg_cron;"'