# Podman Branch - Implementation Summary

**Branch**: `podman`
**Base**: `atomic` branch
**Date**: 2025-10-27
**Status**: ✅ Complete and tested

---

## Objective

Enable rsm-msba-k8s Docker image to work in **two modes**:

1. **Rootful mode** (original): For Docker Desktop on Windows/macOS/Linux
2. **Rootless mode** (new): For rootless Podman on Linux servers (~150 student containers)

---

## What Was Changed

### 1. New Startup Script: `start-rootless.sh`

**Location**: `files/start-rootless.sh`

**Features**:
- Runs as non-root user (no sudo required)
- Auto-starts SSHD and PostgreSQL
- Configures environment variables system-wide (writes to .bashrc)
- Fixes PostgreSQL SSL key permissions automatically
- Documents manual service startup (Hadoop, Spark)
- Handles graceful shutdown

**Auto-Start Services**:
- SSHD (port 22)
- PostgreSQL 16 (port 5432)

**Manual Services** (students start when needed):
- Hadoop/HDFS: `/opt/hadoop/init-dfs.sh` then `/opt/hadoop/start-dfs.sh`
- PySpark: `pyspark` or `spark-submit`
- PgWeb: `pgweb_binary --bind=0.0.0.0 --listen=8000`

### 2. Updated Dockerfile

**Location**: `rsm-msba-k8s/Dockerfile`

**Changes**:
- Added `COPY files/start-rootless.sh /usr/local/bin/`
- Made both scripts executable
- No changes to existing functionality
- Backward compatible with original `start-container.sh`

### 3. Documentation

Created three documentation files:

1. **ROOTLESS-PODMAN-TEST-RESULTS.md**: Detailed test results for all services
2. **ROOTLESS-USAGE.md**: Complete usage guide for both modes
3. **PODMAN-BRANCH-SUMMARY.md**: This file

---

## Test Results

All services tested and verified working as non-root user (UID 1001):

| Service | Status | Requirements | Notes |
|---------|--------|--------------|-------|
| **SSHD** | ✅ Works | `CAP_NET_BIND_SERVICE` | Auto-starts |
| **PostgreSQL 16** | ✅ Works | SSL key chmod 600 | Auto-starts, handled by script |
| **Hadoop/HDFS** | ✅ Works | `JAVA_HOME`, login shell | Manual start, fully functional |
| **Spark/PySpark** | ✅ Works | `JAVA_HOME`, `PYTHONPATH`, login shell | Manual start, fully functional |

### Environment Variables

The startup script writes these to `/home/jovyan/.bashrc`:

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export SPARK_HOME=/usr/local/spark
export PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.9-src.zip
export HADOOP_HOME=/opt/hadoop
export PATH=${HADOOP_HOME}/bin:${SPARK_HOME}/bin:${PATH}
```

---

## How to Use

### Rootless Mode (Podman on Linux)

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

**Key flags explained**:
- `--security-opt label=disable`: SELinux compatibility
- `--userns=keep-id`: Map UID 1001 inside = UID 1001 outside
- `--user 1001:1001`: Run as non-root from start
- `--cap-add=CAP_NET_BIND_SERVICE`: Allow binding to port 22
- `--entrypoint /usr/local/bin/start-rootless.sh`: Use rootless startup

### Rootful Mode (Docker Desktop - Original)

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

Uses original `start-container.sh` entrypoint (default).

---

## Important Notes

### For Students Using Hadoop/Spark

Students must use **login shells** (`bash -l` or SSH sessions) for environment variables to be available.

**Via SSH** (recommended):
```bash
ssh -p 22XXX student@server
# Environment automatically loaded
hdfs dfs -ls /
pyspark
```

**Via podman exec**:
```bash
podman exec -it rsm-USERNAME bash -l
# Environment automatically loaded
hdfs dfs -ls /
pyspark
```

**Direct exec** (won't work without -l):
```bash
podman exec rsm-USERNAME hdfs dfs -ls /
# ERROR: JAVA_HOME not set

# Correct way:
podman exec rsm-USERNAME bash -l -c 'hdfs dfs -ls /'
# ✓ Works
```

### Why .bashrc?

- Non-root users can't write to `/etc/profile.d/`
- `.bashrc` is sourced by login shells
- SSH sessions automatically use login shells
- Works for both bash and zsh (zsh sources .bashrc in some configs)

---

## What Didn't Change

- Original `start-container.sh`: Unchanged, still default entrypoint
- All existing functionality: Preserved
- Dockerfile base images: Same versions
- All installed packages: No changes
- Existing environment variables: All preserved

---

## Production Deployment Checklist

Before deploying to production servers:

1. ✅ Build new image with both scripts included
2. ✅ Test on Linux with rootless podman (completed)
3. ⏳ Test on Windows with Docker Desktop (if applicable)
4. ⏳ Test on macOS with Docker Desktop (if applicable)
5. ⏳ Push image to Docker Hub
6. ⏳ Update deployment scripts in `rsm-docker-atomic/` to use new entrypoint
7. ⏳ Document for students: how to manually start Hadoop/Spark

---

## Git Commits

```
efffd31 Add rootless podman support to rsm-msba-k8s image
6fc035b Fix environment variable persistence in start-rootless.sh
```

---

## Next Steps

1. **Build multi-platform image**:
   ```bash
   cd /home/vnijs/gh/docker-k8s/rsm-msba-k8s
   docker buildx build --platform linux/amd64,linux/arm64 \
     -t vnijs/rsm-msba-k8s:podman --push .
   ```

2. **Test on production server**: Use test user account first

3. **Update deployment scripts**: Modify `rsm-docker-atomic/` configs to use new entrypoint

4. **Student documentation**: Create guide showing Hadoop/Spark startup commands

5. **Monitor first deployments**: Check logs, verify services start correctly

---

## Support / Troubleshooting

### Issue: Postgres won't start
**Error**: `private key file has group or world access`
**Fix**: Should be automatic, but if not: `chmod 600 /etc/ssl/private/ssl-cert-snakeoil.key`

### Issue: Hadoop says "JAVA_HOME not set"
**Fix**: Use login shell: `bash -l` or SSH into container

### Issue: PySpark import fails
**Fix**: Use login shell: `bash -l` or SSH into container

### Issue: SSH won't bind to port 22
**Error**: `Cannot bind to port 22`
**Fix**: Add `--cap-add=CAP_NET_BIND_SERVICE` flag

---

## Contact

For questions about this implementation:
- See test results: `ROOTLESS-PODMAN-TEST-RESULTS.md`
- See usage guide: `ROOTLESS-USAGE.md`
- See deployment guide: `~/gh/rsm-docker-atomic/PODMAN-DEPLOYMENT-GUIDE.md`
