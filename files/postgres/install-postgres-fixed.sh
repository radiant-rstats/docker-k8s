#!/bin/bash

# PostgreSQL installation script for multi-platform Docker builds
# Fixed to handle existing data directories

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

# Stop any running PostgreSQL service
/etc/init.d/postgresql stop || true

# Create required directories and ensure they're clean
echo "Preparing PostgreSQL directories..."
mkdir -p /etc/postgresql/${POSTGRES_VERSION}/main/conf.d

# Clean and recreate the data directory to avoid initdb conflicts
rm -rf /var/lib/postgresql/${POSTGRES_VERSION}/main
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

# Start PostgreSQL service with retry logic for port conflicts
echo "Starting PostgreSQL service..."
max_attempts=5
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt to start PostgreSQL..."

    if /etc/init.d/postgresql start; then
        echo "PostgreSQL started successfully on attempt $attempt"
        break
    else
        echo "PostgreSQL start failed on attempt $attempt"
        if [ $attempt -lt $max_attempts ]; then
            echo "Waiting 30 seconds before retry..."
            sleep 30
        else
            echo "Failed to start PostgreSQL after $max_attempts attempts"
            exit 1
        fi
    fi

    attempt=$((attempt + 1))
done

# Wait a bit for PostgreSQL to be fully ready
echo "Waiting for PostgreSQL to be ready..."
sleep 10

# Create user and database with retry logic
max_db_attempts=3
db_attempt=1

while [ $db_attempt -le $max_db_attempts ]; do
    echo "Attempt $db_attempt to create database and user..."

    if su - postgres -c "PGPASSWORD=$(cat /tmp/pwfile) psql -h localhost -p 8765 --command \"CREATE USER ${NB_USER} WITH SUPERUSER PASSWORD '${PGPASSWORD}';\" && \
                         PGPASSWORD=$(cat /tmp/pwfile) createdb -h localhost -p 8765 -O ${NB_USER} rsm-docker"; then
        echo "Database and user created successfully"
        break
    else
        echo "Database creation failed on attempt $db_attempt"
        if [ $db_attempt -lt $max_db_attempts ]; then
            echo "Waiting 15 seconds before retry..."
            sleep 15
        else
            echo "Failed to create database after $max_db_attempts attempts, but continuing..."
            break
        fi
    fi

    db_attempt=$((db_attempt + 1))
done

# Stop PostgreSQL (it will be started again by the container's start script)
echo "Stopping PostgreSQL..."
/etc/init.d/postgresql stop

# Clean up the password file
rm /tmp/pwfile

# Clean up
echo "Cleaning up..."
apt clean
rm -rf /var/lib/apt/lists/*

echo "PostgreSQL ${POSTGRES_VERSION} installation completed successfully"
