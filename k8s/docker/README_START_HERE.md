# 🚀 START HERE

Welcome! This directory contains a complete Docker-based student container system.

## What Is This?

A simple alternative to Kubernetes for giving 150 students their own Docker containers accessible via VS Code Remote-SSH.

**Key Features:**
- ✅ Simpler than Kubernetes (90% less complexity)
- ✅ Auto-start containers on SSH connection
- ✅ VS Code "Connect to Host" integration
- ✅ 24-hour idle timeout with email alerts
- ✅ Automatic image updates
- ✅ Same student experience as K8s setup

## Quick Links

**Choose your path:**

1. **📖 I want to understand the decision** → Read [COMPARISON.md](COMPARISON.md)
   - K8s vs Docker analysis
   - Should you switch?

2. **🧪 I want to test this on sc2** → Read [TESTING.md](TESTING.md)
   - Phase 1: Test with yourself and TAs
   - Phase 2: Pilot with 5-10 students
   - Phase 3: Full rollout

3. **⚡ I want to deploy quickly** → Read [QUICKSTART.md](QUICKSTART.md)
   - 10-minute setup guide
   - Fast path to production

4. **📋 I want detailed installation steps** → Read [INSTALL.md](INSTALL.md)
   - Complete installation checklist
   - Verification steps

5. **📚 I want full documentation** → Read [README.md](README.md)
   - Complete admin guide
   - Troubleshooting
   - Monitoring

6. **💡 I need quick commands** → Read [CHEATSHEET.md](CHEATSHEET.md)
   - Common admin tasks
   - One-liners
   - Support tasks

7. **👨‍🎓 I need student instructions** → Read [STUDENT_GUIDE.md](STUDENT_GUIDE.md)
   - Send this to students
   - Setup guide
   - FAQ

## Recommended Path for Testing on sc2

```
1. Read TESTING.md (5 min)
   ↓
2. Deploy to sc2 (10 min)
   ↓
3. Test with yourself (10 min)
   ↓
4. Test with TAs (1-2 days)
   ↓
5. Pilot with students (1 week)
   ↓
6. Full rollout (when ready)
```

## Files in This Directory

| File | Purpose | Read If... |
|------|---------|------------|
| **README_START_HERE.md** | This file | You're new here |
| **TESTING.md** | Testing guide | You want to test on sc2 |
| **QUICKSTART.md** | Fast setup | You want quick production deploy |
| **INSTALL.md** | Installation | You want detailed steps |
| **README.md** | Admin guide | You want full documentation |
| **COMPARISON.md** | K8s vs Docker | You're deciding to switch |
| **STUDENT_GUIDE.md** | Student docs | You're onboarding students |
| **CHEATSHEET.md** | Quick reference | You need command help |
| **config.env** | Configuration | Settings and tuning |
| **generate-port.sh** | Script | Port assignment logic |
| **start-container.sh** | Script | Auto-start containers |
| **stop-container.sh** | Script | Stop containers |
| **cleanup-idle.sh** | Script | Cron: stop idle containers |
| **monitor-health.sh** | Script | Cron: health monitoring |
| **get-ssh-config.sh** | Script | Generate student SSH config |

## TL;DR - Test It Now

Want to try it immediately on sc2? Here's the fastest path:

```bash
# 1. SSH to sc2
ssh your-userid@sc2.yourdomain.edu

# 2. Copy files (adjust path to where you have this repo)
sudo mkdir -p /opt/docker-containers
sudo cp /home/vnijs/gh/docker-k8s/k8s/docker/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh

# 3. Edit config
sudo nano /opt/docker-containers/config.env
# Change: SERVER_HOSTNAME="sc2.yourdomain.edu"
# Change: ALERT_EMAIL="your-email@domain.edu"
# Save and exit

# 4. Create directories with correct permissions
sudo mkdir -p /var/log/student-containers /tmp/student-containers
sudo chmod 1777 /var/log/student-containers /tmp/student-containers

# 5. Pull image (if not already present)
sudo docker pull vnijs/rsm-msba-k8s:latest

# 6. Test it yourself
/opt/docker-containers/start-container.sh

# 7. Get your SSH config
/opt/docker-containers/get-ssh-config.sh
# Copy the output

# 8. On your laptop, add to ~/.ssh/config
# Paste what you copied above

# 9. Connect via VS Code
# Open VS Code → Remote-SSH → Connect to Host → rsm-msba

# 10. Success! 🎉
```

Full details in [TESTING.md](TESTING.md).

## Need Help?

- **Testing on sc2:** Read [TESTING.md](TESTING.md)
- **Student setup:** Read [STUDENT_GUIDE.md](STUDENT_GUIDE.md)
- **Troubleshooting:** Read [README.md](README.md) → Troubleshooting section
- **Quick commands:** Read [CHEATSHEET.md](CHEATSHEET.md)

## What Happened to Kubernetes?

The old K8s files are safely preserved in `../old/` directory. You can switch back anytime if needed.

## Questions?

All common questions are answered in the documentation files above. Start with the file that matches your goal!

---

**Ready to test?** → Start with [TESTING.md](TESTING.md)

**Want to decide first?** → Start with [COMPARISON.md](COMPARISON.md)
