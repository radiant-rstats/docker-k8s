#!/bin/bash

# PostgreSQL installation script for multi-platform Docker builds
# Uses direct pg_ctl commands to avoid init.d script issues

# Exit on error
set -e

# Set default for NB_USER if not provided
if [ -z "$NB_USER" ]; then
    echo "Warning: NB_USER not set, using default 'jovyan'"
    export NB_USER="jovyan"
fi

# Check if POSTGRES_VERSION is set
if [ -z "$POSTGRES_VERSION" ]; then
    echo "Error: POSTGRES_VERSION environment variable is not set"
    exit 1
fi

echo "=== PostgreSQL Installation for Multi-Platform Build ==="
echo "POSTGRES_VERSION: ${POSTGRES_VERSION}"
echo "NB_USER: ${NB_USER}"
echo "PGPASSWORD: [HIDDEN]"

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
echo "Creating PostgreSQL directories..."
mkdir -p /etc/postgresql/${POSTGRES_VERSION}/main/conf.d
mkdir -p /var/lib/postgresql/${POSTGRES_VERSION}/main
mkdir -p /var/log/postgresql

# Set correct permissions (PostgreSQL requires 700 or 750 for data directory)
chown -R postgres:postgres /etc/postgresql/${POSTGRES_VERSION}/main/
chmod 750 /etc/postgresql/${POSTGRES_VERSION}/main/
chmod 750 /etc/postgresql/${POSTGRES_VERSION}/main/conf.d
chown -R postgres:postgres /var/lib/postgresql/${POSTGRES_VERSION}/main/
chmod 700 /var/lib/postgresql/${POSTGRES_VERSION}/main/
chown postgres:postgres /var/log/postgresql
chmod 750 /var/log/postgresql

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
echo "Configuring PostgreSQL..."
if [ -f /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf ]; then
    sed -i 's/__version__/'"$POSTGRES_VERSION"'/g' /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf
    echo "PostgreSQL configuration updated"
else
    echo "Warning: postgresql.conf not found at expected location"
fi

# Start PostgreSQL using pg_ctl directly (avoiding init.d script)
echo "Starting PostgreSQL using pg_ctl..."
su - postgres -c "/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl \
    -D /var/lib/postgresql/${POSTGRES_VERSION}/main \
    -o '-c config_file=/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf' \
    -l /var/log/postgresql/startup.log \
    start"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 5

# Check if PostgreSQL is running
if su - postgres -c "/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_isready -p 8765"; then
    echo "PostgreSQL is ready and listening on port 8765"
else
    echo "PostgreSQL may not be ready yet, checking default port..."
    if su - postgres -c "/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_isready -p 5432"; then
        echo "Warning: PostgreSQL is running on default port 5432, not 8765"
    fi
fi

# Create user and database
echo "Creating PostgreSQL user and databases..."
su - postgres -c "PGPASSWORD=$(cat /tmp/pwfile) /usr/lib/postgresql/${POSTGRES_VERSION}/bin/psql -p 8765 --command \"CREATE USER ${NB_USER} WITH SUPERUSER PASSWORD '${PGPASSWORD}';\""
su - postgres -c "PGPASSWORD=$(cat /tmp/pwfile) /usr/lib/postgresql/${POSTGRES_VERSION}/bin/createdb -p 8765 -O ${NB_USER} ${NB_USER}"
su - postgres -c "PGPASSWORD=$(cat /tmp/pwfile) /usr/lib/postgresql/${POSTGRES_VERSION}/bin/createdb -p 8765 -O ${NB_USER} rsm-msba"

echo "User and databases created successfully"

# Stop PostgreSQL (it will be started again by the container's start script)
echo "Stopping PostgreSQL..."
su - postgres -c "/usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl \
    -D /var/lib/postgresql/${POSTGRES_VERSION}/main \
    stop -m fast"

# Clean up the password file
rm /tmp/pwfile

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

echo "PostgreSQL installation completed successfully"
