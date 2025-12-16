#!/bin/bash
set -e

echo "Starting SSHD service..."
/usr/sbin/sshd -o PidFile=/tmp/sshd.pid -E /var/log/sshd/sshd.log

echo "Starting PostgreSQL service..."

# Initialize postgres if needed (e.g., fresh volume mount)
/usr/local/bin/init-postgres-db.sh

# Start PostgreSQL
/usr/lib/postgresql/${POSTGRES_VERSION}/bin/postgres \
    -c config_file=/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf &

echo "All services started. Tailing logs..."
tail -f /var/log/sshd/sshd.log &
sleep 2
tail -f /var/log/postgresql/postgresql-*.log 2>/dev/null &

# Wait for all background processes
wait -n
