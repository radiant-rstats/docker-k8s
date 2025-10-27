# Rootless Podman Service Testing Results

**Date**: 2025-10-27
**Branch**: podman
**Test Environment**: Fedora CoreOS VM, rootless podman with `--userns=keep-id --user 1001:1001`

## Test Container Configuration

```bash
podman run -d \
  --name rsm-aaa111 \
  --security-opt label=disable \
  --userns=keep-id \
  --user 1001:1001 \
  --cap-add=CAP_NET_BIND_SERVICE \
  -p 22921:22 \
  -v /home/aaa111:/home/jovyan \
  --entrypoint /bin/bash \
  --memory=16g \
  --cpus=2 \
  docker.io/vnijs/rsm-msba-k8s:latest \
  -c 'sleep infinity'
```

## Test Results Summary

All services successfully tested as non-root user (UID 1001):

| Service | Status | Notes |
|---------|--------|-------|
| PostgreSQL 16 | ✅ Works | Requires SSL key chmod 600 |
| Hadoop/HDFS | ✅ Works | Requires JAVA_HOME |
| Spark/PySpark | ✅ Works | Requires JAVA_HOME + PYTHONPATH |
| SSHD | ✅ Works | Requires CAP_NET_BIND_SERVICE |

---

## 1. PostgreSQL Testing

### Issues Found
- **SSL key permissions**: Default 0640 causes startup failure
- All postgres directories already owned by correct user

### Fix Required
```bash
chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key
```

### Startup Command
```bash
/usr/lib/postgresql/16/bin/postgres \
  -c config_file=/etc/postgresql/16/main/postgresql.conf \
  -D /var/lib/postgresql/16/main &
```

### Verification
```bash
psql -U postgres -c 'SELECT version();'
# PostgreSQL 16.10 (Debian 16.10-1.pgdg120+1) on x86_64-pc-linux-gnu
```

**Result**: ✅ Works perfectly as non-root after fixing SSL key permissions

---

## 2. Hadoop/HDFS Testing

### Issues Found
- **JAVA_HOME not set**: Hadoop scripts fail without it

### Environment Required
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### Initialization
```bash
# Create data directories
mkdir -p /tmp/hadoop-root/dfs/name
mkdir -p /tmp/hadoop-jovyan/dfs/data

# Format namenode
hdfs namenode -format -force
```

### Startup Commands
```bash
hdfs --daemon start namenode
hdfs --daemon start datanode
```

### Verification
```bash
# Check processes
ps aux | grep -E "(namenode|datanode)"
# Both running as UID 1001 ✓

# Test HDFS operations
hdfs dfs -mkdir -p /test
hdfs dfs -ls /
# Found 1 items
# drwxr-xr-x   - aaa111 supergroup          0 2025-10-27 07:12 /test

# Test file operations
echo "test data" > /tmp/test.txt
hdfs dfs -put /tmp/test.txt /test/
hdfs dfs -cat /test/test.txt
# test data ✓
```

**Result**: ✅ Works perfectly as non-root with JAVA_HOME set

---

## 3. PySpark Testing

### Issues Found
- **JAVA_HOME not set**: Same as Hadoop
- **PYTHONPATH not set**: py4j module not found

### Environment Required
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.9-src.zip:${PYTHONPATH}
```

### Version Check
```bash
pyspark --version
# Welcome to
#       ____              __
#      / __/__  ___ _____/ /__
#     _\ \/ _ \/ _ `/ __/  '_/
#    /___/ .__/\_,_/_/ /_/\_\   version 4.0.0
#       /_/
```

### Functional Test
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("test").master("local[1]").getOrCreate()
df = spark.createDataFrame([(1, "a"), (2, "b")], ["id", "value"])
df.show()
# +---+-----+
# | id|value|
# +---+-----+
# |  1|    a|
# |  2|    b|
# +---+-----+
spark.stop()
```

**Result**: ✅ Works perfectly as non-root with JAVA_HOME + PYTHONPATH

---

## 4. SSHD Testing

### Requirements
- **CAP_NET_BIND_SERVICE**: Needed to bind to port 22 as non-root
- Container must be started with: `--cap-add=CAP_NET_BIND_SERVICE`

### Startup Command
```bash
/usr/sbin/sshd -D &
```

**Result**: ✅ Works with capability added (tested in previous session)

---

## Required Changes for start-rootless.sh

### 1. SSL Key Permissions (Postgres)
```bash
chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key
```

### 2. Environment Variables
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.9-src.zip:${PYTHONPATH}
```

### 3. Auto-Start Services
```bash
# SSHD
/usr/sbin/sshd -D &

# PostgreSQL (after SSL fix)
/usr/lib/postgresql/16/bin/postgres \
  -c config_file=/etc/postgresql/16/main/postgresql.conf \
  -D /var/lib/postgresql/16/main &
```

### 4. Manual Start Scripts (for students)
**Hadoop**: Use existing `/opt/hadoop/start-dfs.sh`
**Spark**: Students launch via `pyspark` or python scripts

---

## Container Requirements

### Podman Flags Needed
```bash
--security-opt label=disable    # SELinux compat with user namespaces
--userns=keep-id                # Map UID 1001 inside = UID 1001 outside
--user 1001:1001                # Run as non-root
--cap-add=CAP_NET_BIND_SERVICE  # Allow port 22 binding
```

### Dockerfile Changes Needed
None! All services work as-is. Only startup script needs modification.

---

## Conclusion

**All services work perfectly as non-root user** with only minor environment setup:
1. SSL key permissions fix (one-time)
2. JAVA_HOME environment variable
3. PYTHONPATH environment variable
4. CAP_NET_BIND_SERVICE capability

No changes needed to Postgres, Hadoop, or Spark themselves.

**Next Step**: Create `start-rootless.sh` script that:
- Sets up environment variables
- Fixes SSL key permissions
- Starts SSHD and Postgres automatically
- Documents how students manually start Hadoop/Spark
