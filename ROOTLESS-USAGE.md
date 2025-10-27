# RSM-MSBA Container Usage Guide

The rsm-msba-k8s image now supports **two startup modes**:

1. **Rootful mode** (original): Uses `start-container.sh` - requires running as root with NB_UID/NB_GID
2. **Rootless mode** (new): Uses `start-rootless.sh` - runs as non-root user from the start

---

## Rootless Mode (Recommended for Podman)

### Requirements
- Rootless Podman with user namespaces
- CAP_NET_BIND_SERVICE capability for SSH port binding
- User UID mapping (e.g., UID 1001 inside = UID 1001 outside)

### Start Container

```bash
podman run -d \
  --name rsm-USERNAME \
  --security-opt label=disable \
  --userns=keep-id \
  --user 1001:1001 \
  --cap-add=CAP_NET_BIND_SERVICE \
  -p 22XXX:22 \
  -v /home/USERNAME:/home/jovyan \
  --entrypoint /usr/local/bin/start-rootless.sh \
  --memory=16g \
  --cpus=2 \
  docker.io/vnijs/rsm-msba-k8s:latest
```

### What Starts Automatically
- **SSHD** (port 22)
- **PostgreSQL 16** (port 5432)

### What Students Start Manually

**Hadoop/HDFS**:
```bash
# First time only - initialize HDFS
/opt/hadoop/init-dfs.sh

# Start HDFS
/opt/hadoop/start-dfs.sh

# Stop HDFS
/opt/hadoop/stop-dfs.sh
```

**PySpark**:
```bash
# Interactive shell
pyspark

# Run a script
spark-submit my_script.py
```

**PgWeb** (Database GUI):
```bash
pgweb_binary --bind=0.0.0.0 --listen=8000
```

### Environment Variables (Pre-configured)
All necessary environment variables are set automatically in `start-rootless.sh`:
- `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`
- `SPARK_HOME=/usr/local/spark`
- `HADOOP_HOME=/opt/hadoop`
- `PYTHONPATH` (includes PySpark and py4j)

---

## Rootful Mode (Original - Docker Desktop)

### Requirements
- Docker or Podman running as root
- NB_UID and NB_GID environment variables

### Start Container

**Linux/macOS**:
```bash
docker run -d \
  --name rsm-USERNAME \
  -p 22XXX:22 \
  -v /home/USERNAME:/home/jovyan \
  -e NB_UID=$(id -u) \
  -e NB_GID=$(id -g) \
  --memory=16g \
  --cpus=2 \
  docker.io/vnijs/rsm-msba-k8s:latest
```

**Windows**:
```bash
docker run -d \
  --name rsm-USERNAME \
  -p 22XXX:22 \
  -v C:\Users\USERNAME:/home/jovyan \
  -e NB_UID=1000 \
  -e NB_GID=1000 \
  --memory=16g \
  --cpus=2 \
  docker.io/vnijs/rsm-msba-k8s:latest
```

### What Starts Automatically
Same as rootless mode:
- **SSHD** (port 22)
- **PostgreSQL 16** (port 5432)

### Behavior
- Container starts as root
- `start-container.sh` changes jovyan user to match NB_UID/NB_GID
- Services start with proper permissions
- Works on Windows, macOS, and Linux with Docker Desktop

---

## Testing Rootless Mode

### 1. Build Image (with rootless script included)
```bash
cd /path/to/docker-k8s/rsm-msba-k8s
docker build -t rsm-msba-k8s:podman .
```

### 2. Test on Linux with Podman
```bash
# Stop and remove any existing test container
podman stop rsm-test 2>/dev/null || true
podman rm rsm-test 2>/dev/null || true

# Start fresh container
podman run -d \
  --name rsm-test \
  --security-opt label=disable \
  --userns=keep-id \
  --user $(id -u):$(id -g) \
  --cap-add=CAP_NET_BIND_SERVICE \
  -p 2222:22 \
  -v $HOME/test-data:/home/jovyan \
  --entrypoint /usr/local/bin/start-rootless.sh \
  --memory=4g \
  --cpus=1 \
  rsm-msba-k8s:podman

# Check logs
podman logs rsm-test

# SSH to container
ssh -p 2222 jovyan@localhost

# Inside container - test services
psql -U postgres -c 'SELECT version();'
/opt/hadoop/init-dfs.sh
/opt/hadoop/start-dfs.sh
hdfs dfs -ls /
pyspark --version
```

### 3. Test on macOS/Windows with Docker Desktop
```bash
# Should use original entrypoint (start-container.sh)
docker run -d \
  --name rsm-test \
  -p 2222:22 \
  -v $HOME/test-data:/home/jovyan \
  -e NB_UID=$(id -u) \
  -e NB_GID=$(id -g) \
  --memory=4g \
  --cpus=1 \
  rsm-msba-k8s:podman

# Test same way as above
```

---

## Troubleshooting

### Postgres won't start (rootless mode)
**Error**: `private key file has group or world access`

**Fix**: The SSL key permissions should be fixed automatically by `start-rootless.sh`, but if not:
```bash
podman exec rsm-USERNAME chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key
podman restart rsm-USERNAME
```

### Hadoop fails with "JAVA_HOME not set"
**Fix**: Environment should be set automatically by `start-rootless.sh`. If running commands manually:
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### PySpark import fails
**Fix**: Environment should be set automatically. If running manually:
```bash
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.9-src.zip:${PYTHONPATH}
```

### SSHD won't bind to port 22
**Error**: `Cannot bind to port 22`

**Fix**: Add the capability flag:
```bash
--cap-add=CAP_NET_BIND_SERVICE
```

---

## Comparison: Rootful vs Rootless

| Feature | Rootful (Original) | Rootless (New) |
|---------|-------------------|----------------|
| Container user at start | root | UID 1001 (mapped) |
| Needs NB_UID/NB_GID | ✅ Yes | ❌ No |
| User namespace | ❌ No | ✅ Yes |
| Security isolation | Standard | Enhanced |
| Works on Windows | ✅ Yes | ⚠️ Limited* |
| Works on macOS | ✅ Yes | ⚠️ Limited* |
| Works on Linux | ✅ Yes | ✅ Yes |
| UID/GID changes | At runtime | Pre-mapped |
| Startup script | start-container.sh | start-rootless.sh |

\* Rootless podman support on Windows/macOS is limited and may require additional configuration.

---

## Deployment Recommendations

### For Multi-User Servers (Linux)
Use **rootless mode** with:
- One container per student
- User namespaces for isolation
- systemd user services for lifecycle management
- See: `/home/vnijs/gh/rsm-docker-atomic/` for deployment scripts

### For Student Laptops (Windows/macOS/Linux)
Use **rootful mode** (original) with:
- Docker Desktop
- NB_UID/NB_GID matching student's user
- Original start-container.sh entrypoint (default)

### For Development/Testing
Either mode works - use rootless mode if testing for server deployment.
