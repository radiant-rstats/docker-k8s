# Testing Guide: Deploy on sc2 for Admin/TA Testing

This guide will help you set up the system on sc2 for testing with yourself and TAs before rolling out to students.

## Testing Strategy

**Phase 1:** You + TAs (2-5 people)
**Phase 2:** Small student pilot group (5-10 students)
**Phase 3:** Full rollout (all 150 students)

---

## Phase 1: Admin/TA Testing Setup

### Step 1: SSH to sc2

```bash
ssh your-userid@sc2.yourdomain.edu
```

### Step 2: Copy Files to Server

From your local machine (or on sc2 if you have the git repo there):

```bash
# If you have the repo on sc2
cd /home/vnijs/gh/docker-k8s/k8s

# Copy to /opt/docker-containers (requires sudo)
sudo mkdir -p /opt/docker-containers
sudo cp docker/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh
```

**OR** if you need to transfer from your laptop:

```bash
# From your laptop, in this directory
scp docker/* your-userid@sc2.yourdomain.edu:/tmp/docker-test/

# Then on sc2
sudo mkdir -p /opt/docker-containers
sudo cp /tmp/docker-test/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh
```

### Step 3: Configure Settings

```bash
sudo nano /opt/docker-containers/config.env
```

Update these critical settings:

```bash
# Line 20: Update to sc2's actual hostname
SERVER_HOSTNAME="sc2.yourdomain.edu"  # Change to real hostname

# Line 22: Update to your admin email
ALERT_EMAIL="your-email@domain.edu"

# Leave other settings as defaults for now
```

Save and exit (Ctrl+X, Y, Enter).

### Step 4: Create Required Directories

```bash
sudo mkdir -p /var/log/student-containers
sudo mkdir -p /tmp/student-containers
sudo chmod 1777 /var/log/student-containers  # Writable by all users, sticky bit
sudo chmod 1777 /tmp/student-containers
```

### Step 5: Pull Docker Images

```bash
# Check if image exists
docker images | grep rsm-msba

# Pull if needed (this will take a few minutes - 19GB image)
sudo docker pull vnijs/rsm-msba-k8s:latest

# For GPU testing (if needed)
# sudo docker pull vnijs/rsm-msba-k8s-gpu:latest
```

### Step 6: Test Container Creation (As Yourself)

```bash
# Test the start script
/opt/docker-containers/start-container.sh

# You should see output like:
# Waiting for SSH to be ready...
# (after a few seconds)
```

Check the logs:

```bash
tail -20 /var/log/student-containers/$(whoami).log
```

Verify container is running:

```bash
docker ps -f name=rsm-msba-$(whoami)

# Should show your container with port mapping
```

### Step 7: Get Your SSH Config

```bash
/opt/docker-containers/get-ssh-config.sh
```

Copy the entire output (the `Host rsm-msba` block).

### Step 8: Set Up Local SSH Config

**On your laptop** (not on sc2), edit `~/.ssh/config`:

```bash
# Mac/Linux
nano ~/.ssh/config

# Windows: edit C:\Users\YourName\.ssh\config
```

Paste the config you copied from Step 7 at the end of the file. Save.

### Step 9: Test VS Code Connection

1. Open VS Code on your laptop
2. Install "Remote - SSH" extension (if not installed)
3. Click green button (bottom-left corner)
4. Select "Connect to Host..."
5. Choose "rsm-msba"
6. Wait for connection (10-30 seconds first time)

**Success indicators:**
- Green badge showing "SSH: rsm-msba" in bottom-left
- Terminal opens to `/home/jovyan`
- Your home directory files visible in Explorer

### Step 10: Test Basic Functionality

In the VS Code terminal connected to your container:

```bash
# Check you're in the container
whoami
# Should show: jovyan

# Check home directory is mounted
ls -la
# Should show your actual home directory files

# Test Python (if applicable)
python3 --version

# Test writing a file
echo "test" > test-container.txt
cat test-container.txt

# Check it persists in your actual home
exit
# Reconnect via VS Code
cat test-container.txt  # Should still exist
```

### Step 11: Test Container Lifecycle

```bash
# On sc2 (SSH session)

# Check container status
docker ps -f name=rsm-msba-$(whoami)

# Check resource usage
docker stats --no-stream rsm-msba-$(whoami)

# Test stopping
/opt/docker-containers/stop-container.sh

# Verify it stopped
docker ps -f name=rsm-msba-$(whoami)
# Should show nothing

# Reconnect via VS Code - should auto-start
```

### Step 12: Set Up Monitoring (Optional for Testing)

For now, you can test the monitoring script manually:

```bash
# Test cleanup script (won't stop anything - containers are new)
sudo /opt/docker-containers/cleanup-idle.sh
cat /var/log/student-containers/cleanup.log

# Test health monitoring
sudo /opt/docker-containers/monitor-health.sh
cat /var/log/student-containers/monitor.log
```

**Skip cron setup** until you're ready to move to production.

---

## Phase 1: Testing Checklist

Test these scenarios with yourself and TAs:

### Basic Functionality
- [ ] Container starts automatically on first SSH connection
- [ ] VS Code Remote-SSH connects successfully
- [ ] Terminal works in VS Code
- [ ] Home directory is correctly mounted
- [ ] Files created in container persist after reconnect
- [ ] Port number is consistent (same port each time)

### Container Lifecycle
- [ ] Container restarts after being stopped
- [ ] Stopping container doesn't lose data
- [ ] Multiple reconnections work smoothly
- [ ] Container startup time is acceptable (<30s first time, <10s subsequent)

### Resource Management
- [ ] Container memory limit is enforced (check `docker stats`)
- [ ] Multiple containers can run simultaneously
- [ ] System resources are reasonable (check `free -h`, `df -h`)

### Error Handling
- [ ] Graceful error messages if something fails
- [ ] Logs are written to `/var/log/student-containers/`
- [ ] Can recover from container crash (`docker rm` and reconnect)

### VS Code Specific
- [ ] Extensions can be installed in container
- [ ] Port forwarding works (for Jupyter, web apps, etc.)
- [ ] Terminal multiplexing works
- [ ] File editing is responsive
- [ ] Git operations work

### Multi-User
- [ ] Each TA gets their own container
- [ ] Each TA gets a unique port
- [ ] Containers don't interfere with each other
- [ ] No port conflicts

---

## Phase 2: Small Student Pilot (5-10 Students)

Once Phase 1 testing is successful:

### Step 1: Select Pilot Students

Choose 5-10 students who:
- Are comfortable with technical setup
- Can provide good feedback
- Represent different skill levels

### Step 2: Send Pilot Instructions

Email pilot students:

---

**Subject: Pilot Testing - New Container System**

Hi [Student Names],

We're testing a new development environment system and would like your help! This will give you your own container on sc2 with all course software pre-installed, accessible via VS Code.

**Setup (5 minutes):**

1. SSH to sc2:
   ```
   ssh your-userid@sc2.yourdomain.edu
   ```

2. Run this command:
   ```
   /opt/docker-containers/get-ssh-config.sh
   ```

3. Copy the output and add it to your LOCAL `~/.ssh/config` file:
   - Windows: `C:\Users\YourName\.ssh\config`
   - Mac/Linux: `~/.ssh/config`

4. In VS Code:
   - Install "Remote - SSH" extension
   - Click green button (bottom-left)
   - "Connect to Host" → "rsm-msba"

**Feedback Requested:**

Please try the system for [1 week / until XX date] and report:
- Any connection issues
- Performance problems
- Confusing steps
- What worked well
- Suggestions for improvement

Reply to this email with your feedback by [date].

Thanks for helping us test!

---

### Step 3: Monitor Pilot Usage

```bash
# On sc2, check running containers
docker ps --filter "name=rsm-msba-"

# Check resource usage
docker stats --no-stream

# Check for errors
grep -i error /var/log/student-containers/*.log

# Check specific student's log
tail -50 /var/log/student-containers/aaa111.log
```

### Step 4: Collect Feedback

Create a feedback form or collect via email:

**Questions to ask:**
1. How easy was the setup process? (1-5 scale)
2. Did you encounter any errors? If so, what?
3. How fast is the connection?
4. How responsive is VS Code?
5. Did you lose any work?
6. Would you recommend this system?
7. Any suggestions for improvement?

### Step 5: Iterate Based on Feedback

Common issues and fixes:

**"Setup instructions were confusing"**
- Improve [STUDENT_GUIDE.md](STUDENT_GUIDE.md) based on feedback

**"Connection is slow"**
- Check: `docker stats` - are containers over-using resources?
- Consider reducing `MEMORY_LIMIT` in config.env

**"My container stopped unexpectedly"**
- Check logs: `/var/log/student-containers/username.log`
- Check if container crashed: `docker ps -a`

---

## Phase 3: Full Rollout (All 150 Students)

Once pilot is successful:

### Step 1: Set Up Cron Jobs (Production)

```bash
sudo crontab -e
```

Add:
```cron
0 * * * * /opt/docker-containers/cleanup-idle.sh
0 * * * * /opt/docker-containers/monitor-health.sh
```

### Step 2: Configure Email Alerts

Test email sending:

```bash
echo "Test from student container system on sc2" | mail -s "Test Alert" your-email@domain.edu
```

If it doesn't work:
```bash
sudo apt-get update
sudo apt-get install mailutils postfix
# Choose "Internet Site" during postfix setup
```

### Step 3: Send Student Instructions

Use the message from Phase 2 (pilot testing), but send to all students.

Include link to full [STUDENT_GUIDE.md](STUDENT_GUIDE.md).

### Step 4: Monitor System

**First Week - Daily Checks:**

```bash
# How many students are using it?
docker ps --filter "name=rsm-msba-" | wc -l

# System resources
free -h
df -h

# Check for errors
grep -i error /var/log/student-containers/*.log | tail -20

# Check monitoring log
tail -50 /var/log/student-containers/monitor.log
```

**Ongoing - Weekly Checks:**

```bash
# Review cleanup activity
tail -100 /var/log/student-containers/cleanup.log

# Check Docker disk usage
docker system df

# Review health monitoring
tail -100 /var/log/student-containers/monitor.log

# Check peak usage
docker ps --filter "name=rsm-msba-" | wc -l  # during class time
```

---

## Troubleshooting During Testing

### TA Can't Connect

1. **Check their SSH works:**
   ```bash
   ssh ta-userid@sc2.yourdomain.edu
   ```

2. **Check container exists:**
   ```bash
   docker ps -a -f name=rsm-msba-ta-userid
   ```

3. **Check logs:**
   ```bash
   tail -50 /var/log/student-containers/ta-userid.log
   ```

4. **Try manual start:**
   ```bash
   sudo -u ta-userid /opt/docker-containers/start-container.sh
   ```

5. **Check port assignment:**
   ```bash
   /opt/docker-containers/generate-port.sh ta-userid
   ```

### Container Won't Start

```bash
# Check Docker daemon
sudo systemctl status docker

# Check available resources
free -h
df -h

# Try creating manually
sudo -u userid /opt/docker-containers/start-container.sh

# Check detailed logs
tail -100 /var/log/student-containers/userid.log
docker logs rsm-msba-userid
```

### Port Conflict

```bash
# Check which container is using the port
docker ps --format '{{.Names}} {{.Ports}}' | grep :PORT

# If conflict, manually assign different port
# (or fix the port generation logic)
```

### Running Out of Resources

```bash
# Check what's using resources
docker stats --no-stream | head -20

# Stop idle containers manually
docker stop $(docker ps -q --filter "name=rsm-msba-")

# Or adjust limits in config.env
sudo nano /opt/docker-containers/config.env
# Reduce MEMORY_LIMIT="12g" instead of 16g
```

---

## Testing Metrics to Track

Keep track of these metrics during testing:

| Metric | Target | How to Check |
|--------|--------|--------------|
| Container start time | <30s first time | Time from VS Code connect to ready |
| Reconnect time | <10s | Time for subsequent connections |
| Concurrent users | 20-25 | `docker ps \| wc -l` during peak |
| Memory per container | ~8-12GB actual | `docker stats` |
| Disk usage growth | <10GB/week | `df -h` weekly |
| Crash rate | <5% | Check logs for unexpected exits |
| User satisfaction | >4/5 | Feedback forms |

---

## Rollback Plan

If you need to revert to Kubernetes:

```bash
# Stop all Docker containers
docker stop $(docker ps -q --filter "name=rsm-msba-")

# Restart microk8s (if it was stopped)
microk8s start

# Students revert their SSH config to old format
# (old configs are in your k8s/old/ directory)
```

---

## Success Criteria

Consider testing successful when:

**Phase 1 (Admin/TA):**
- [ ] All TAs can connect via VS Code
- [ ] No major bugs or errors
- [ ] Performance is acceptable
- [ ] System is manageable

**Phase 2 (Pilot):**
- [ ] >80% of pilot students successfully connect
- [ ] <5% error rate
- [ ] Positive feedback (avg >3.5/5)
- [ ] No data loss incidents

**Phase 3 (Full Rollout):**
- [ ] >90% of students successfully connect
- [ ] System handles peak load (20+ concurrent)
- [ ] <1% crash rate
- [ ] Manageable support burden

---

## Next Steps After Testing

1. **Document any changes** made during testing
2. **Update STUDENT_GUIDE.md** based on feedback
3. **Tune config.env** based on actual usage patterns
4. **Set up monitoring dashboard** (optional - Grafana/Prometheus)
5. **Create FAQ** from common student questions
6. **Train TAs** on troubleshooting procedures

---

## Quick Reference Commands

```bash
# Check your container
docker ps -f name=rsm-msba-$(whoami)

# View your logs
tail -f /var/log/student-containers/$(whoami).log

# Restart your container
/opt/docker-containers/stop-container.sh
# Then reconnect via VS Code

# Check system resources
free -h
df -h
docker stats --no-stream

# Check all running containers
docker ps --filter "name=rsm-msba-"

# Get your SSH config
/opt/docker-containers/get-ssh-config.sh
```

---

**Ready to start testing!** Begin with Phase 1 (yourself and TAs), then move to Phase 2 (pilot students) once you're confident.
