# Docker-based Student Container System

A simple, scalable system for managing individual Docker containers for 150+ students, allowing VS Code Remote-SSH access without Kubernetes complexity.

## Overview

This system replaces the previous Kubernetes (microk8s) setup with a simpler Docker-based approach that:

- Automatically starts student containers on SSH connection
- Assigns deterministic ports based on student ID
- Mounts student home directories into containers
- Auto-stops idle containers after 24 hours
- Monitors system health and sends email alerts
- Works seamlessly with VS Code Remote-SSH

## Architecture

```
Student Laptop (VS Code)
    |
    | SSH with ProxyCommand
    v
Server (sc2) - SSH Auth
    |
    | Executes start-container.sh
    v
Docker Container (per student)
    |
    | Mounts /home/<userid>
    v
Student's Home Directory
```

## Directory Structure

```
/opt/docker-containers/          # Install scripts here
├── config.env                   # Configuration settings
├── generate-port.sh             # Port calculation
├── start-container.sh           # Container lifecycle management
├── stop-container.sh            # Manual container stop
├── cleanup-idle.sh              # Cron: stop idle containers
├── monitor-health.sh            # Cron: health monitoring & alerts
└── get-ssh-config.sh            # Generate student SSH config

/var/log/student-containers/     # Logs
├── <username>.log               # Per-student container logs
├── cleanup.log                  # Idle cleanup logs
└── monitor.log                  # Health monitoring logs

/tmp/student-containers/         # Temporary files
└── alert_state                  # Alert tracking (avoid spam)
```

## Installation

### 1. Install Scripts on Server

```bash
# Copy all files to /opt/docker-containers/
sudo mkdir -p /opt/docker-containers
sudo cp docker/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh

# Create required directories with correct permissions
sudo mkdir -p /var/log/student-containers
sudo mkdir -p /tmp/student-containers
sudo chmod 1777 /var/log/student-containers  # Writable by all users, sticky bit
sudo chmod 1777 /tmp/student-containers      # Sticky bit prevents users deleting others' files
```

### 2. Configure Settings

Edit `/opt/docker-containers/config.env`:

```bash
# Update these values for your environment
DOCKER_IMAGE="vnijs/rsm-msba-k8s:latest"
SERVER_HOSTNAME="sc2.yourdomain.edu"
ALERT_EMAIL="admin@yourdomain.edu"
MEMORY_LIMIT="16g"              # Per-container RAM limit
CPU_LIMIT="2"                   # Per-container CPU limit
```

### 3. Set Up Cron Jobs

Add to root's crontab (`sudo crontab -e`):

```cron
# Cleanup idle containers (24h timeout) - runs hourly
0 * * * * /opt/docker-containers/cleanup-idle.sh

# Health monitoring and alerts - runs hourly
0 * * * * /opt/docker-containers/monitor-health.sh
```

### 4. Configure Email Alerts

Ensure the server can send email:

```bash
# Install mailutils (Debian/Ubuntu)
sudo apt-get install mailutils

# Or postfix
sudo apt-get install postfix

# Test email
echo "Test from student container system" | mail -s "Test" admin@yourdomain.edu
```

### 5. Pull Docker Images

```bash
# Pull the base images (as root or docker group member)
sudo docker pull vnijs/rsm-msba-k8s:latest
sudo docker pull vnijs/rsm-msba-k8s-gpu:latest  # If using GPU containers
```

## Usage

### For Students

See [STUDENT_GUIDE.md](STUDENT_GUIDE.md) for student instructions.

**Quick summary:**
1. SSH to server: `ssh userid@sc2.yourdomain.edu`
2. Run: `/opt/docker-containers/get-ssh-config.sh`
3. Copy output to local `~/.ssh/config`
4. Connect via VS Code Remote-SSH

### For Administrators

#### View Running Containers

```bash
# List all student containers
docker ps --filter "name=rsm-msba-"

# View resource usage
docker stats --no-stream

# Check specific student
docker ps -f name=rsm-msba-aaa111
```

#### Manual Container Management

```bash
# Stop a student's container
/opt/docker-containers/stop-container.sh aaa111

# Stop all containers (emergency)
docker stop $(docker ps -q --filter "name=rsm-msba-")

# Remove stopped containers (cleanup)
docker container prune

# View container logs
docker logs rsm-msba-aaa111
```

#### Check Logs

```bash
# Per-student logs
tail -f /var/log/student-containers/aaa111.log

# Cleanup logs
tail -f /var/log/student-containers/cleanup.log

# Monitoring logs
tail -f /var/log/student-containers/monitor.log
```

#### Update Docker Images

```bash
# Pull new image
docker pull vnijs/rsm-msba-k8s:latest

# Students automatically get new image on next connect
# (start-container.sh detects image updates)
```

#### Port Assignments

Ports are deterministically assigned based on student ID:

- Regular containers: `20000 + numeric_suffix`
  - Example: `aaa111` → port `20111`
- GPU containers: `25000 + numeric_suffix`
  - Example: `aaa111` → port `25111`

Check a student's port:

```bash
/opt/docker-containers/generate-port.sh aaa111
# Output: 20111
```

#### Resource Monitoring

```bash
# Check RAM usage
free -h

# Check disk usage
df -h

# Docker disk usage
docker system df

# Top RAM-consuming containers
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | sort -k 2 -h
```

## Monitoring & Alerts

The `monitor-health.sh` script checks for:

1. **High RAM usage** (>90% threshold)
2. **High disk usage** (>90% threshold)
3. **Crashed containers** (exited state)
4. **Container restart loops** (instability)
5. **Docker daemon health**
6. **Port conflicts** (duplicate assignments)
7. **Container count** (informational)

Alerts are sent via email to `ALERT_EMAIL` (configured in `config.env`).

**Alert deduplication:** Same alert won't be sent more than once per hour.

## Troubleshooting

### Student Can't Connect

1. **Check if container is running:**
   ```bash
   docker ps -f name=rsm-msba-<userid>
   ```

2. **Check logs:**
   ```bash
   tail -20 /var/log/student-containers/<userid>.log
   ```

3. **Test SSH to container manually:**
   ```bash
   # Get student's port
   PORT=$(/opt/docker-containers/generate-port.sh <userid>)
   # Try connecting
   ssh -p $PORT jovyan@localhost
   ```

4. **Restart container:**
   ```bash
   docker restart rsm-msba-<userid>
   ```

### Container Won't Start

1. **Check Docker logs:**
   ```bash
   docker logs rsm-msba-<userid>
   ```

2. **Check resource limits:**
   ```bash
   # Verify enough RAM/disk available
   free -h
   df -h
   ```

3. **Remove and recreate:**
   ```bash
   docker stop rsm-msba-<userid>
   docker rm rsm-msba-<userid>
   # Student reconnects to auto-create
   ```

### Port Conflicts

If two students somehow get the same port:

```bash
# Check port conflicts
docker ps --format '{{.Names}} {{.Ports}}' | grep ":<PORT>->"

# Manually assign different port (edit script or container)
```

### High Resource Usage

```bash
# Find resource hogs
docker stats --no-stream | sort -k 4 -h

# Stop specific container
/opt/docker-containers/stop-container.sh <userid>

# Or reduce limits in config.env and recreate containers
```

## Capacity Planning

### Current Configuration
- **RAM per container:** 16GB limit, 8GB reservation
- **CPUs per container:** 2
- **Total server RAM:** 1TB

### Concurrent Capacity
- **Theoretical max:** 62 containers (1TB / 16GB)
- **Practical limit:** ~40-50 containers (accounting for overhead)
- **Comfortable target:** 20-25 concurrent users

### Monitoring Usage
```bash
# Current concurrent users
docker ps --filter "name=rsm-msba-" --format '{{.Names}}' | wc -l

# Total RAM in use by containers
docker stats --no-stream --format '{{.MemUsage}}' | awk '{sum+=$1} END {print sum " MB"}'
```

## Security Considerations

1. **Container Isolation:** Each container runs in its own namespace
2. **Home Directory Access:** Students only access their own home directory
3. **Resource Limits:** Memory/CPU limits prevent resource exhaustion
4. **SSH Key Auth:** Students use their GitHub SSH keys
5. **Network Isolation:** Containers are isolated by default

## Backup & Recovery

### Important Data Locations
- Student work: `/home/<userid>` (mounted into containers)
- Container configs: `/opt/docker-containers/`
- Logs: `/var/log/student-containers/`

### Backup Strategy
- **Student data:** Backed up as part of regular home directory backups
- **Container state:** Ephemeral - containers are disposable
- **Scripts:** Version controlled in git

### Disaster Recovery
1. Reinstall Docker
2. Copy scripts to `/opt/docker-containers/`
3. Pull Docker images
4. Set up cron jobs
5. Students reconnect - containers auto-create

## Migration from Kubernetes

If migrating from the old microk8s setup:

```bash
# Stop all K8s pods
microk8s kubectl delete deployment --all
microk8s kubectl delete service --all

# Stop microk8s (optional - can run both systems in parallel during migration)
microk8s stop

# Student data is preserved in home directories
# Students just need to update their SSH configs
```

## Performance Comparison

**Kubernetes (microk8s):**
- Overhead: ~2-4GB RAM for K8s itself
- Complexity: High (kubectl, yaml, scheduling, networking)
- Startup time: ~10-15 seconds per pod
- Debugging: Multi-layer (K8s + Docker)

**Plain Docker:**
- Overhead: Minimal (~100MB)
- Complexity: Low (standard Docker commands)
- Startup time: ~5-10 seconds per container
- Debugging: Single layer (Docker only)

## Future Enhancements

Possible improvements:

1. **Web Dashboard:** Real-time container status for students
2. **Auto-scaling:** Dynamic resource limits based on load
3. **Usage Analytics:** Track who's using what resources
4. **Self-service Portal:** Students can restart their own containers
5. **Automated Testing:** Health checks before new image rollout

## Support

For issues or questions:
- Check logs: `/var/log/student-containers/`
- Email: `admin@yourdomain.edu`
- Documentation: This README and STUDENT_GUIDE.md
