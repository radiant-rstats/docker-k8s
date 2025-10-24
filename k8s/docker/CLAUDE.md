# Docker-based Student Container System - SSH Connection Issues

## Context

We're setting up a Docker-based system to give 150 students their own containers accessible via VS Code Remote-SSH (replacing Kubernetes/microk8s). The system works but we hit SSH connection issues during testing.

## Current Status

### What Works ✅
1. Container creation and startup scripts
2. Port assignment (deterministic from userid)
3. Home directory mounting
4. Container lifecycle management
5. SSH daemon starts and reports "listening on port 22"
6. SSH config has correct HostKey directives (FIXED)
7. Direct container access works: `docker exec -it -u jovyan rsm-msba-vnijs /bin/zsh`

### What's Broken ❌
SSH connection hangs during protocol handshake:
- Client sends: `SSH-2.0-OpenSSH_10.0`
- Server never responds
- Connection times out

## Root Cause Analysis

### Issue 1: Kitty Terminal SSH Wrapper
The Kitty terminal uses `kitten ssh` which wraps SSH commands with shell integration features. This interferes with the SSH handshake. Evidence:
```
debug3: Started with: /usr/bin/ssh -v -v -v -t -o ControlMaster=auto -o ControlPath=/run/user/1000/kssh-937858-%C ...
```

### Issue 2: VS Code Terminal Restrictions
All previous debugging was done from VS Code's integrated terminal, which appears sandboxed:
- `sudo` doesn't work (no new privileges flag)
- Network/port forwarding might be restricted
- May not reflect actual system SSH behavior

### Issue 3: Fixed - Missing HostKey Directives
Original `/home/vnijs/gh/docker-k8s/files/sshd/sshd_config` was missing:
```
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
```
This has been FIXED in the currently running container.

## Current Running Container

```bash
docker ps -f name=rsm-msba-vnijs
# Name: rsm-msba-vnijs
# Port: 0.0.0.0:20229->22/tcp
# Image: vnijs/rsm-msba-k8s:latest
# Status: Running, SSH daemon active
```

SSH keys setup:
- Host key: `~/.ssh/id_container` (dedicated key created for container access)
- Public key: `~/.ssh/id_container.pub` (added to `~/.ssh/authorized_keys`)
- Container has both keys via home directory mount

SSH config in `~/.ssh/config`:
```
Host rsm-msba-local
    HostName localhost
    User jovyan
    Port 20229  # NOTE: May need to update if port changed
    IdentityFile ~/.ssh/id_container
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
```

## What Needs Testing NOW

### CRITICAL: Test from Regular Terminal (NOT Kitty, NOT VS Code)

Open a plain terminal (Konsole, xterm, GNOME Terminal, etc.) and test:

**Test 1: Plain SSH bypassing all wrappers**
```bash
/usr/bin/ssh -v -p 20229 jovyan@127.0.0.1 -i ~/.ssh/id_container
```

**Test 2: If Test 1 hangs, try IPv4 explicitly**
```bash
/usr/bin/ssh -v -4 -p 20229 jovyan@127.0.0.1 -i ~/.ssh/id_container
```

**Test 3: Check if port is reachable**
```bash
telnet localhost 20229
# OR
nc -zv localhost 20229
```

**Test 4: Check Docker port forwarding**
```bash
docker port rsm-msba-vnijs
# Should show: 22/tcp -> 0.0.0.0:20229
```

**Test 5: Verify SSH is actually listening inside container**
```bash
docker exec rsm-msba-vnijs ps aux | grep sshd
docker exec rsm-msba-vnijs sudo /usr/sbin/sshd -T | head -10
# Should NOT show "no hostkeys available" error
```

## If SSH Still Doesn't Work

### Debug Commands

```bash
# Check container logs
docker logs rsm-msba-vnijs | tail -50

# Check SSH logs inside container
docker exec rsm-msba-vnijs cat /var/log/sshd/sshd.log

# Test SSH handshake manually
timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/20229; echo "SSH-2.0-Test" >&3; head -1 <&3'
# If this hangs, Docker networking is broken

# Check iptables rules (may need real sudo, not from VS Code)
sudo iptables -t nat -L -n -v | grep 20229
# Should show DNAT rule for port forwarding
```

### Possible Solutions to Try

**Option A: Recreate container with simpler config**
```bash
docker stop rsm-msba-vnijs && docker rm rsm-msba-vnijs

# Create with minimal flags
docker run -d \
    --name rsm-msba-vnijs \
    -p 22222:22 \
    -e NB_UID=$(id -u) \
    -e NB_GID=$(id -g) \
    -e SKIP_PERMISSIONS=false \
    -v $HOME:/home/jovyan \
    vnijs/rsm-msba-k8s:latest

# Update ~/.ssh/config to use port 22222
# Then test: /usr/bin/ssh -p 22222 jovyan@127.0.0.1 -i ~/.ssh/id_container
```

**Option B: Test with simple Alpine SSH container**
```bash
docker run -d --name test-ssh \
    -p 3333:22 \
    -e PUID=$(id -u) \
    -e PGID=$(id -g) \
    -e USER_PASSWORD=testpass \
    -e PUBLIC_KEY="$(cat ~/.ssh/id_container.pub)" \
    lscr.io/linuxserver/openssh-server:latest

# Wait 10 seconds for startup
sleep 10

# Test connection
/usr/bin/ssh -p 3333 testuser@127.0.0.1 -i ~/.ssh/id_container
# Password is "testpass" if key doesn't work
```

**Option C: Check for Docker network issues**
```bash
# Check Docker network mode
docker inspect rsm-msba-vnijs | grep -i network

# Try binding to 127.0.0.1 explicitly instead of 0.0.0.0
docker stop rsm-msba-vnijs && docker rm rsm-msba-vnijs
docker run -d --name rsm-msba-vnijs -p 127.0.0.1:20229:22 \
    -e NB_UID=$(id -u) -e NB_GID=$(id -g) -e SKIP_PERMISSIONS=false \
    -v $HOME:/home/jovyan vnijs/rsm-msba-k8s:latest
```

## File Locations

### Source Files (Need HostKey fix when working)
- `/home/vnijs/gh/docker-k8s/files/sshd/sshd_config` - Original config (NEEDS HostKey lines added)
- `/home/vnijs/gh/docker-k8s/files/install-sshd.sh` - SSH installation script
- `/home/vnijs/gh/docker-k8s/files/start-container.sh` - Container startup script

### Deployment Files (For sc2 server)
- `/home/vnijs/gh/docker-k8s/k8s/docker/` - All deployment scripts
- `/home/vnijs/gh/docker-k8s/k8s/docker/start-container.sh` - Has SKIP_PERMISSIONS=false ✅
- `/home/vnijs/gh/docker-k8s/k8s/old/` - Old Kubernetes files (preserved)

### Test Files
- `~/docker-containers/` - Local test directory
- `~/docker-logs/` - Local test logs
- `~/.ssh/id_container` - Dedicated SSH key for containers
- `~/.ssh/authorized_keys` - Contains id_container.pub

### Documentation
- `/home/vnijs/SSH_DEBUG_SUMMARY.md` - Comprehensive debug notes
- `/home/vnijs/gh/docker-k8s/k8s/docker/README.md` - Admin guide
- `/home/vnijs/gh/docker-k8s/k8s/docker/TESTING.md` - Testing guide

## System Info

- OS: Arch Linux 6.16.8-arch1-1
- Docker: Running and working
- User: vnijs (UID will vary)
- Home: /home/vnijs
- Default terminal: Kitty (has SSH wrapper issues)
- Server: sc2 (deployment target, not tested yet)

## Quick Command Reference

```bash
# Check what's running
docker ps

# View specific container
docker ps -f name=rsm-msba-vnijs

# Get shell in container (bypass SSH)
docker exec -it -u jovyan rsm-msba-vnijs /bin/zsh

# View logs
docker logs rsm-msba-vnijs
cat ~/docker-logs/vnijs.log

# Check SSH config inside container
docker exec rsm-msba-vnijs cat /etc/ssh/sshd_config | grep -E "^(Port|HostKey)"

# Test SSH config validity
docker exec rsm-msba-vnijs sudo /usr/sbin/sshd -T | head -20

# Stop and remove container
docker stop rsm-msba-vnijs && docker rm rsm-msba-vnijs
```

## Expected Behavior When Working

When SSH works correctly, you should see:
```bash
$ /usr/bin/ssh -v -p 20229 jovyan@127.0.0.1 -i ~/.ssh/id_container
...
debug1: Local version string SSH-2.0-OpenSSH_10.0
debug1: Remote protocol version 2.0, remote software version OpenSSH_X.X  # <-- This line should appear
debug1: compat_banner: match: OpenSSH_X.X pat OpenSSH* compat 0x04000000
...
debug1: Authentications that can continue: publickey
debug1: Next authentication method: publickey
debug1: Offering public key: /home/vnijs/.ssh/id_container ED25519
debug1: Server accepts key: /home/vnijs/.ssh/id_container ED25519
debug1: Authentication succeeded (publickey).
...
[jovyan@rsm-msba-vnijs ~]$  # <-- You get a shell prompt
```

Currently it hangs after "Local version string" - server never sends "Remote protocol version".

## Goal

Get SSH working locally first, then deploy to sc2 server for 150 students.

## Questions to Answer

1. Does `/usr/bin/ssh -p 20229 jovyan@127.0.0.1 -i ~/.ssh/id_container` work from a plain terminal?
2. If not, does `telnet localhost 20229` connect?
3. Does the simple Alpine SSH test container work?
4. Is there a firewall or Docker networking issue on this Arch system?

---

**Start here:** Open a plain terminal (NOT Kitty, NOT VS Code) and run Test 1 above.
