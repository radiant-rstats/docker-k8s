# Installation Checklist

Quick reference for installing the Docker-based student container system on sc2.

## Pre-Installation

- [ ] Verify Docker is installed and running on sc2
- [ ] Verify you have root/sudo access
- [ ] Verify email sending capability (mailutils or sendmail)
- [ ] Confirm student home directories exist in `/home/<userid>/`

## Installation Steps

### 1. Copy Files to Server

```bash
# On sc2 server
sudo mkdir -p /opt/docker-containers
sudo cp /path/to/docker/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh
```

### 2. Create Required Directories

```bash
sudo mkdir -p /var/log/student-containers
sudo mkdir -p /tmp/student-containers
sudo chmod 1777 /var/log/student-containers  # Writable by all users, sticky bit
sudo chmod 1777 /tmp/student-containers  # Sticky bit for tmp
```

### 3. Configure Settings

Edit `/opt/docker-containers/config.env`:

```bash
sudo nano /opt/docker-containers/config.env
```

**Required changes:**
- `SERVER_HOSTNAME`: Update to your actual server hostname
- `ALERT_EMAIL`: Update to admin email address
- `DOCKER_IMAGE`: Verify image name is correct
- `MEMORY_LIMIT`: Adjust if needed (default: 16g)

### 4. Test Port Generation

```bash
# Test with a real student ID
/opt/docker-containers/generate-port.sh aaa111
# Should output a port number (e.g., 20111)

# Test with GPU flag
/opt/docker-containers/generate-port.sh aaa111 --gpu
# Should output a different port (e.g., 25111)
```

### 5. Pull Docker Images

```bash
# Pull base images (may take several minutes - 19GB image)
sudo docker pull vnijs/rsm-msba-k8s:latest

# If using GPU containers
sudo docker pull vnijs/rsm-msba-k8s-gpu:latest
```

### 6. Set Up Cron Jobs

```bash
sudo crontab -e
```

Add these lines:

```cron
# Cleanup idle containers (24h timeout) - runs every hour at :00
0 * * * * /opt/docker-containers/cleanup-idle.sh

# Health monitoring and alerts - runs every hour at :00
0 * * * * /opt/docker-containers/monitor-health.sh
```

Save and exit.

Verify cron jobs:
```bash
sudo crontab -l
```

### 7. Test Email Alerts

```bash
# Send test email
echo "Test from student container system on $(hostname)" | mail -s "Test Alert" your-email@domain.edu

# Check if received
```

If email doesn't work, install/configure:
```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install mailutils

# Configure postfix when prompted (select "Internet Site")
```

### 8. Test Container Creation (with a test user)

**Option A: Test as yourself**

```bash
# SSH to server as your own user
ssh your-userid@sc2.yourdomain.edu

# Test the start script
/opt/docker-containers/start-container.sh

# Check container was created
docker ps -f name=rsm-msba-$(whoami)

# Get SSH config
/opt/docker-containers/get-ssh-config.sh

# Clean up test container
docker stop rsm-msba-$(whoami)
docker rm rsm-msba-$(whoami)
```

**Option B: Test with a student account**

```bash
# As admin, test container creation for student aaa111
sudo -u aaa111 /opt/docker-containers/start-container.sh

# Verify container
docker ps -f name=rsm-msba-aaa111

# Check logs
tail /var/log/student-containers/aaa111.log

# Clean up
docker stop rsm-msba-aaa111
docker rm rsm-msba-aaa111
```

### 9. Test Monitoring Script

```bash
# Run monitoring manually
sudo /opt/docker-containers/monitor-health.sh

# Check log
cat /var/log/student-containers/monitor.log
```

### 10. Test Cleanup Script

```bash
# Run cleanup manually (shouldn't stop anything yet - containers are new)
sudo /opt/docker-containers/cleanup-idle.sh

# Check log
cat /var/log/student-containers/cleanup.log
```

## Student Onboarding

### For Each Student

1. **Verify SSH access:**
   ```bash
   ssh student-userid@sc2.yourdomain.edu
   ```

2. **Generate SSH config:**
   ```bash
   /opt/docker-containers/get-ssh-config.sh
   ```

3. **Follow STUDENT_GUIDE.md** for VS Code setup

### Batch Instructions

Send students:
- Link to [STUDENT_GUIDE.md](STUDENT_GUIDE.md)
- Server hostname: `sc2.yourdomain.edu`
- Their userid
- Reminder to use their GitHub SSH key

## Verification Checklist

After installation, verify:

- [ ] Scripts are in `/opt/docker-containers/`
- [ ] Scripts are executable (`chmod +x`)
- [ ] Config file has correct settings
- [ ] Log directories exist and are writable
- [ ] Cron jobs are installed (`sudo crontab -l`)
- [ ] Email sending works
- [ ] Docker images are pulled
- [ ] Test container can be created
- [ ] Port generation works for multiple students
- [ ] Monitoring script runs without errors
- [ ] At least one student can successfully connect via VS Code

## Common Installation Issues

### Docker not installed

```bash
# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add users to docker group (optional, for non-root access)
sudo usermod -aG docker $USER
```

### Permission denied errors

```bash
# Fix script permissions
sudo chmod +x /opt/docker-containers/*.sh

# Fix log directory permissions
sudo chmod 755 /var/log/student-containers

# Fix tmp directory permissions
sudo chmod 1777 /tmp/student-containers
```

### Email not working

```bash
# Install mailutils
sudo apt-get install mailutils postfix

# Test manually
echo "test" | mail -s "Test" your-email@domain.edu

# Check mail logs
sudo tail -f /var/log/mail.log
```

### Cron jobs not running

```bash
# Verify cron service is running
sudo systemctl status cron

# Check cron logs
sudo grep CRON /var/log/syslog

# Test manual execution
sudo /opt/docker-containers/monitor-health.sh
```

### Container start timeout

```bash
# Check Docker daemon
sudo systemctl status docker

# Check available resources
free -h
df -h

# Increase timeout in config.env
sudo nano /opt/docker-containers/config.env
# Change: CONTAINER_START_TIMEOUT=60
```

## Monitoring After Deployment

### Daily Checks (first week)

```bash
# Check running containers
docker ps --filter "name=rsm-msba-"

# Check system resources
free -h
df -h

# Check logs for errors
grep -i error /var/log/student-containers/*.log

# Check monitoring alerts
tail -20 /var/log/student-containers/monitor.log
```

### Weekly Checks

```bash
# Review cleanup activity
tail -50 /var/log/student-containers/cleanup.log

# Check disk usage by Docker
docker system df

# Clean up unused images/containers (optional)
docker system prune -f
```

## Rollback to Kubernetes

If you need to revert to the K8s setup:

```bash
# Old K8s files are in /path/to/k8s/old/
# Restart microk8s
microk8s start

# Students update their SSH configs back to old format
```

## Support

- **Documentation:** See [README.md](README.md) for admin guide
- **Student docs:** See [STUDENT_GUIDE.md](STUDENT_GUIDE.md)
- **Logs:** `/var/log/student-containers/`
- **Config:** `/opt/docker-containers/config.env`

---

**Installation Date:** _______________
**Installed By:** _______________
**Server:** sc2.yourdomain.edu
**Number of Students:** ~150
