# Admin Cheat Sheet

Quick reference for common tasks.

## Installation (One-Time Setup)

```bash
# 1. Copy files
sudo mkdir -p /opt/docker-containers
sudo cp docker/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh

# 2. Edit config
sudo nano /opt/docker-containers/config.env
# Change: SERVER_HOSTNAME and ALERT_EMAIL

# 3. Create directories with correct permissions
sudo mkdir -p /var/log/student-containers /tmp/student-containers
sudo chmod 1777 /var/log/student-containers /tmp/student-containers

# 4. Pull image
sudo docker pull vnijs/rsm-msba-k8s:latest

# 5. Set up cron (for production)
sudo crontab -e
# Add:
# 0 * * * * /opt/docker-containers/cleanup-idle.sh
# 0 * * * * /opt/docker-containers/monitor-health.sh
```

## Common Admin Tasks

### Check System Status

```bash
# How many containers running?
docker ps --filter "name=rsm-msba-" | wc -l

# System resources
free -h && df -h

# Container resource usage
docker stats --no-stream

# Check for errors
grep -i error /var/log/student-containers/*.log | tail -20
```

### Manage Student Containers

```bash
# View specific student's container
docker ps -f name=rsm-msba-aaa111

# View student's logs
tail -50 /var/log/student-containers/aaa111.log

# Stop student's container
/opt/docker-containers/stop-container.sh aaa111

# Restart student's container
docker restart rsm-msba-aaa111

# Remove student's container (will be recreated on next connect)
docker stop rsm-msba-aaa111 && docker rm rsm-msba-aaa111
```

### Check Logs

```bash
# Monitoring log
tail -f /var/log/student-containers/monitor.log

# Cleanup log
tail -f /var/log/student-containers/cleanup.log

# Specific student log
tail -f /var/log/student-containers/aaa111.log

# Docker container log
docker logs rsm-msba-aaa111
```

### Update Docker Image

```bash
# Pull new image
sudo docker pull vnijs/rsm-msba-k8s:latest

# Students automatically get new image on next connect
# (start-container.sh detects image updates)

# Or force update for specific student
docker stop rsm-msba-aaa111
docker rm rsm-msba-aaa111
# Student reconnects - gets new image
```

### Emergency Actions

```bash
# Stop ALL student containers
docker stop $(docker ps -q --filter "name=rsm-msba-")

# Remove stopped containers
docker container prune -f

# Check Docker disk usage
docker system df

# Clean up unused images/containers (be careful!)
docker system prune -a
```

## Common Student Support Tasks

### Student Can't Connect

```bash
# 1. Verify their container exists
docker ps -a -f name=rsm-msba-USERNAME

# 2. Check their logs
tail -50 /var/log/student-containers/USERNAME.log

# 3. Check their port
/opt/docker-containers/generate-port.sh USERNAME

# 4. Test container creation
sudo -u USERNAME /opt/docker-containers/start-container.sh

# 5. If all else fails, recreate container
docker stop rsm-msba-USERNAME && docker rm rsm-msba-USERNAME
# Student reconnects to auto-create
```

### Student Says Container is Slow

```bash
# Check their container's resource usage
docker stats rsm-msba-USERNAME

# Check system-wide resources
free -h
df -h

# Check how many containers running
docker ps --filter "name=rsm-msba-" | wc -l
```

### Student Lost Their SSH Config

```bash
# They run this on sc2 after SSH'ing in:
/opt/docker-containers/get-ssh-config.sh
```

## Testing/Development

### Test Container Creation (As Yourself)

```bash
# Start your own container
/opt/docker-containers/start-container.sh

# Check it's running
docker ps -f name=rsm-msba-$(whoami)

# Get your SSH config
/opt/docker-containers/get-ssh-config.sh

# Clean up
docker stop rsm-msba-$(whoami)
docker rm rsm-msba-$(whoami)
```

### Test Monitoring Scripts

```bash
# Run monitoring manually
sudo /opt/docker-containers/monitor-health.sh
cat /var/log/student-containers/monitor.log

# Run cleanup manually
sudo /opt/docker-containers/cleanup-idle.sh
cat /var/log/student-containers/cleanup.log
```

## Configuration Changes

### Adjust Memory Limits

```bash
sudo nano /opt/docker-containers/config.env
# Change: MEMORY_LIMIT="12g"  # Instead of 16g
# Existing containers keep old limit until recreated
```

### Change Idle Timeout

```bash
sudo nano /opt/docker-containers/config.env
# Change: IDLE_TIMEOUT=43200  # 12 hours instead of 24
```

### Change Alert Email

```bash
sudo nano /opt/docker-containers/config.env
# Change: ALERT_EMAIL="new-email@domain.edu"
```

## Monitoring & Alerts

### Check Email Alerts Work

```bash
echo "Test from $(hostname)" | mail -s "Test" your-email@domain.edu
```

### Review Recent Alerts

```bash
tail -100 /var/log/student-containers/monitor.log | grep -i warning
tail -100 /var/log/student-containers/monitor.log | grep -i critical
```

### Check Alert State

```bash
cat /tmp/student-containers/alert_state
```

## Useful One-Liners

```bash
# List all students with running containers
docker ps --filter "name=rsm-msba-" --format '{{.Names}}' | sed 's/rsm-msba-//'

# Count containers by status
docker ps -a --filter "name=rsm-msba-" --format '{{.Status}}' | cut -d' ' -f1 | sort | uniq -c

# Total RAM used by all containers
docker stats --no-stream --format '{{.MemUsage}}' | awk -F'/' '{sum+=$1} END {print sum " MB total"}'

# Find containers using most RAM
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | grep rsm-msba | sort -k2 -h | tail -10

# Find oldest running containers
docker ps --filter "name=rsm-msba-" --format '{{.Names}} {{.RunningFor}}' | sort -k2

# Check port assignments for all users
for user in aaa111 bbb222 ccc333; do echo "$user: $(/opt/docker-containers/generate-port.sh $user)"; done
```

## Student Instructions (What to Tell Them)

### Initial Setup

```
1. SSH to server: ssh your-userid@sc2.yourdomain.edu
2. Run: /opt/docker-containers/get-ssh-config.sh
3. Copy output to your LOCAL ~/.ssh/config
4. In VS Code: Install Remote-SSH extension → Connect to Host → rsm-msba
```

### Reconnecting

```
Just open VS Code → Connect to Host → rsm-msba
Container starts automatically if stopped.
```

### If They Have Issues

```
1. Try disconnecting and reconnecting
2. Check with classmates
3. Email instructor with error message
```

## File Locations

| What | Where |
|------|-------|
| Scripts | `/opt/docker-containers/` |
| Config | `/opt/docker-containers/config.env` |
| Logs | `/var/log/student-containers/` |
| Temp files | `/tmp/student-containers/` |
| Student data | `/home/USERNAME/` (mounted in container) |
| Container name | `rsm-msba-USERNAME` |
| GPU container | `rsm-msba-gpu-USERNAME` |

## Port Ranges

| Type | Range | Example |
|------|-------|---------|
| Regular | 20000+ | aaa111 → 20111 |
| GPU | 25000+ | aaa111 → 25111 |

## Resource Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| RAM limit | 16GB | Per container |
| RAM reservation | 8GB | Soft limit |
| CPUs | 2 | Per container |
| Idle timeout | 24 hours | Auto-stop |

## Help & Documentation

| Document | Purpose |
|----------|---------|
| [TESTING.md](TESTING.md) | Testing/staging deployment |
| [QUICKSTART.md](QUICKSTART.md) | 10-minute setup |
| [README.md](README.md) | Complete admin guide |
| [STUDENT_GUIDE.md](STUDENT_GUIDE.md) | Student instructions |
| [COMPARISON.md](COMPARISON.md) | K8s vs Docker analysis |
| [INSTALL.md](INSTALL.md) | Detailed installation |

---

**Save this file for quick reference during daily operations!**
