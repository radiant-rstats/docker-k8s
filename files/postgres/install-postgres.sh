#!/bin/bash

# Exit on error
set -e

# Check if POSTGRES_VERSION is set
if [ -z "$POSTGRES_VERSION" ]; then
    echo "Error: POSTGRES_VERSION environment variable is not set"
    exit 1
fi

echo "Installing packages that postgres needs"
apt update
apt install -y gnupg*

# Create the file repository configuration
echo "Creating PostgreSQL repository configuration..."
sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key
echo "Importing PostgreSQL repository signing key..."
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install PostgreSQL
echo "Installing PostgreSQL ${POSTGRES_VERSION}..."
apt update
apt install -y postgresql-${POSTGRES_VERSION} postgresql-contrib-${POSTGRES_VERSION}

# Create required directories
mkdir -p /etc/postgresql/${POSTGRES_VERSION}/main/conf.d
mkdir -p /var/lib/postgresql/${POSTGRES_VERSION}/main

# Set correct permissions (PostgreSQL requires 700 or 750 for data directory)
chown -R postgres:postgres /etc/postgresql/${POSTGRES_VERSION}/main/
chmod 750 /etc/postgresql/${POSTGRES_VERSION}/main/
chmod 750 /etc/postgresql/${POSTGRES_VERSION}/main/conf.d
chown -R postgres:postgres /var/lib/postgresql/${POSTGRES_VERSION}/main/
chmod 700 /var/lib/postgresql/${POSTGRES_VERSION}/main/

# Create a temporary password file in /tmp
echo "${PGPASSWORD}" > /tmp/pwfile
chown postgres:postgres /tmp/pwfile
chmod 600 /tmp/pwfile

# Initialize the database cluster with specific authentication
echo "Initializing PostgreSQL database cluster..."
su - postgres -c "/usr/lib/postgresql/${POSTGRES_VERSION}/bin/initdb \
    -D /var/lib/postgresql/${POSTGRES_VERSION}/main \
    --auth=scram-sha-256 \
    --pwfile=/tmp/pwfile"

# Now modify the postgresql.conf after initdb has created it
sed -i 's/__version__/'"$POSTGRES_VERSION"'/g' /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf

# Start PostgreSQL service
/etc/init.d/postgresql start

# Create user and databases using the same password file
su - postgres -c "PGPASSWORD=$(cat /tmp/pwfile) psql -h localhost -p 8765 --command \"CREATE USER ${NB_USER} WITH SUPERUSER PASSWORD '${PGPASSWORD}';\" && \
                 PGPASSWORD=$(cat /tmp/pwfile) createdb -h localhost -p 8765 -O ${NB_USER} ${NB_USER} && \
                 PGPASSWORD=$(cat /tmp/pwfile) createdb -h localhost -p 8765 -O ${NB_USER} rsm-msba"

# Clean up the password file
rm /tmp/pwfile

# Stop PostgreSQL (it will be started again by the container's start script)
/etc/init.d/postgresql stop

# Change ownership to jovyan for rootless container operation
# This allows the container to run postgres as jovyan in both Docker and Podman rootless
echo "Changing PostgreSQL ownership to jovyan for rootless operation..."
chown -R jovyan:users /var/lib/postgresql/${POSTGRES_VERSION}/main/
chown -R jovyan:users /etc/postgresql/${POSTGRES_VERSION}/main/
chown -R jovyan:users /var/log/postgresql/
chown -R jovyan:users /var/run/postgresql/

# Clean up
echo "Cleaning up..."
apt clean
rm -rf /var/lib/apt/lists/*

echo "PostgreSQL ${POSTGRES_VERSION} installation completed successfully"
