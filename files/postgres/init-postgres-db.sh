#!/bin/bash
# Shared PostgreSQL initialization script
# Used by both install scripts (build time) and start-container.sh (runtime)
set -e

PGDATA="/var/lib/postgresql/${POSTGRES_VERSION}/main"

# Check if already initialized
if [ -f "${PGDATA}/PG_VERSION" ]; then
    echo "PostgreSQL data directory already initialized."
    exit 0
fi

echo "Initializing PostgreSQL data directory..."

# Create password file
echo "${PGPASSWORD:-postgres}" > /tmp/pwfile
chmod 600 /tmp/pwfile

# Initialize the database
/usr/lib/postgresql/${POSTGRES_VERSION}/bin/initdb \
    -D "${PGDATA}" \
    --auth=scram-sha-256 \
    --pwfile=/tmp/pwfile

# Start postgres temporarily to create user and database
/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl \
    -D "${PGDATA}" \
    -o "-c config_file=/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf" \
    -l /var/log/postgresql/startup.log \
    start

# Wait for postgres to be ready
sleep 3

# Create user and databases
/usr/lib/postgresql/${POSTGRES_VERSION}/bin/psql -p 8765 -c "CREATE USER jovyan WITH SUPERUSER PASSWORD '${PGPASSWORD:-postgres}';" postgres || true
/usr/lib/postgresql/${POSTGRES_VERSION}/bin/createdb -p 8765 -O jovyan jovyan || true
/usr/lib/postgresql/${POSTGRES_VERSION}/bin/createdb -p 8765 -O jovyan rsm-msba || true

# Stop postgres
/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl -D "${PGDATA}" stop -m fast

# Clean up
rm -f /tmp/pwfile

echo "PostgreSQL initialization complete."
