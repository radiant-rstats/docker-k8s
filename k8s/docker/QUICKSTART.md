# Quick Start Guide

**TL;DR:** Get the system running in 10 minutes.

## Prerequisites Checklist

- [ ] Docker installed on sc2
- [ ] Root/sudo access
- [ ] Student home directories exist (`/home/userid/`)
- [ ] Email sending works (`mail` command)

## 5-Step Installation

### 1. Copy Files (2 min)

```bash
# On sc2 server
sudo mkdir -p /opt/docker-containers
sudo cp /path/to/this/directory/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh

# Create log directories with correct permissions
sudo mkdir -p /var/log/student-containers /tmp/student-containers
sudo chmod 1777 /var/log/student-containers /tmp/student-containers
```

### 2. Configure (2 min)

```bash
sudo nano /opt/docker-containers/config.env
```

Change these lines:
```bash
SERVER_HOSTNAME="sc2.yourdomain.edu"  # Your actual hostname
ALERT_EMAIL="your-email@domain.edu"   # Your admin email
```

Save and exit (Ctrl+X, Y, Enter).

### 3. Pull Images (3 min)

```bash
sudo docker pull vnijs/rsm-msba-k8s:latest
```

Wait for download to complete (19GB image).

### 4. Set Up Cron (1 min)

```bash
sudo crontab -e
```

Add these two lines at the end:
```cron
0 * * * * /opt/docker-containers/cleanup-idle.sh
0 * * * * /opt/docker-containers/monitor-health.sh
```

Save and exit.

### 5. Test (2 min)

```bash
# SSH to server as a student (or yourself)
ssh your-userid@sc2.yourdomain.edu

# Test container creation
/opt/docker-containers/start-container.sh

# Verify it worked
docker ps -f name=rsm-msba-$(whoami)

# Get your SSH config
/opt/docker-containers/get-ssh-config.sh
```

## Student Onboarding (5 min per student)

Send students this message:

---

**Subject: VS Code Container Access Setup**

Hi everyone,

To access your development container via VS Code:

1. SSH to the server:
   ```
   ssh your-userid@sc2.yourdomain.edu
   ```

2. Run this command:
   ```
   /opt/docker-containers/get-ssh-config.sh
   ```

3. Copy the output and paste it into your **local** `~/.ssh/config` file
   - Windows: `C:\Users\YourName\.ssh\config`
   - Mac/Linux: `~/.ssh/config`

4. In VS Code:
   - Install "Remote - SSH" extension
   - Click green button (bottom-left)
   - "Connect to Host" → "rsm-msba"

Full guide: [Link to STUDENT_GUIDE.md]

Let me know if you have any issues!

---

## Monitoring (ongoing)

### Daily (first week)

```bash
# Check how many students are using it
docker ps --filter "name=rsm-msba-" | wc -l

# Check for errors
grep -i error /var/log/student-containers/*.log
```

### Weekly

```bash
# Check system resources
free -h
df -h

# Check logs
tail -50 /var/log/student-containers/monitor.log
tail -50 /var/log/student-containers/cleanup.log
```

## Common Issues & Fixes

### "Permission denied" when students connect

```bash
# Fix script permissions
sudo chmod +x /opt/docker-containers/*.sh
```

### Email alerts not working

```bash
# Install mail command
sudo apt-get install mailutils

# Test it
echo "test" | mail -s "Test" your-email@domain.edu
```

### Container won't start

```bash
# Check Docker is running
sudo systemctl status docker

# Check logs
tail -50 /var/log/student-containers/username.log
```

### Running out of RAM

```bash
# Check usage
docker stats --no-stream

# Reduce per-container limit in config.env
sudo nano /opt/docker-containers/config.env
# Change: MEMORY_LIMIT="12g"  # Instead of 16g
```

## Next Steps

- Read [README.md](README.md) for detailed admin guide
- Read [STUDENT_GUIDE.md](STUDENT_GUIDE.md) for student instructions
- Read [COMPARISON.md](COMPARISON.md) for K8s vs Docker analysis
- Read [INSTALL.md](INSTALL.md) for detailed installation checklist

## Need Help?

1. Check logs: `/var/log/student-containers/`
2. Review documentation in this directory
3. Test with a single student first before rolling out to all 150

---

**That's it! The system is ready to use.**

Students connect → Container auto-starts → They work → Container auto-stops after 24h idle.

Simple, effective, and maintainable.
