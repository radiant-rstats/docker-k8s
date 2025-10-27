#!/bin/bash
set -e

echo "=========================================="
echo "RSM-MSBA Container - Rootless Startup"
echo "=========================================="
echo ""

# Set essential environment variables
# Write to jovyan's shell profile so they persist for SSH sessions
cat >> /home/jovyan/.bashrc << 'ENVEOF'

# RSM environment variables (set by start-rootless.sh)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.9-src.zip:${PYTHONPATH}
export HADOOP_HOME=/opt/hadoop
export PATH=${HADOOP_HOME}/bin:${SPARK_HOME}/bin:${PATH}
ENVEOF

# Also export for current script context
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.9-src.zip:${PYTHONPATH}
export HADOOP_HOME=/opt/hadoop
export PATH=${HADOOP_HOME}/bin:${SPARK_HOME}/bin:${PATH}

echo "Environment configured:"
echo "  JAVA_HOME: ${JAVA_HOME}"
echo "  SPARK_HOME: ${SPARK_HOME}"
echo "  HADOOP_HOME: ${HADOOP_HOME}"
echo ""

# Fix PostgreSQL SSL key permissions (required for non-root postgres)
echo "Configuring PostgreSQL SSL permissions..."
if [ -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
    chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key
    echo "  ✓ SSL key permissions fixed"
else
    echo "  ⚠ SSL key not found (may need to be generated)"
fi
echo ""

# Start SSHD
echo "Starting SSHD service..."
if [ -x /usr/sbin/sshd ]; then
    mkdir -p /var/log/sshd
    /usr/sbin/sshd -D -e &
    SSHD_PID=$!
    echo "  ✓ SSHD started (PID: ${SSHD_PID})"
else
    echo "  ✗ SSHD not found at /usr/sbin/sshd"
fi
echo ""

# Start PostgreSQL
echo "Starting PostgreSQL service..."
if [ -x /usr/lib/postgresql/${POSTGRES_VERSION}/bin/postgres ]; then
    mkdir -p /var/log/postgresql
    /usr/lib/postgresql/${POSTGRES_VERSION}/bin/postgres \
        -c config_file=/etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf \
        -D /var/lib/postgresql/${POSTGRES_VERSION}/main &
    PG_PID=$!
    echo "  ✓ PostgreSQL started (PID: ${PG_PID})"

    # Wait a moment for postgres to start
    sleep 2

    # Check if postgres is actually running
    if ps -p ${PG_PID} > /dev/null 2>&1; then
        echo "  ✓ PostgreSQL is running"
    else
        echo "  ✗ PostgreSQL failed to start (check logs in /var/log/postgresql/)"
    fi
else
    echo "  ✗ PostgreSQL not found"
fi
echo ""

# Information about manual services
echo "=========================================="
echo "Manual Services (start when needed)"
echo "=========================================="
echo ""
echo "Hadoop/HDFS:"
echo "  Initialize: /opt/hadoop/init-dfs.sh"
echo "  Start:      /opt/hadoop/start-dfs.sh"
echo "  Stop:       /opt/hadoop/stop-dfs.sh"
echo ""
echo "Spark/PySpark:"
echo "  Interactive: pyspark"
echo "  Submit job:  spark-submit <script.py>"
echo ""
echo "PgWeb (Database GUI):"
echo "  Start: pgweb_binary --bind=0.0.0.0 --listen=8000"
echo ""

# Keep container alive and handle signals gracefully
echo "=========================================="
echo "Container ready! Services running:"
echo "  - SSHD (port 22)"
echo "  - PostgreSQL (port 5432)"
echo "=========================================="
echo ""

# Trap signals to gracefully shutdown
trap 'echo ""; echo "Shutting down..."; kill ${SSHD_PID} ${PG_PID} 2>/dev/null; exit 0' SIGTERM SIGINT

# Keep container alive
tail -f /dev/null
