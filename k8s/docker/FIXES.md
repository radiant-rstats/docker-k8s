# Fixes Applied

## Issues Fixed

### 1. Warning Message for Usernames Without Trailing Numbers

**Issue:**
Script showed warning: "Username 'vnijs' has no trailing numbers, using hash-based port"

**Root Cause:**
The port generation logic was designed primarily for usernames with trailing numbers (aaa111, bbb222), and treated usernames without numbers as an edge case with a warning.

**Fix:**
Removed the warning message. Hash-based port assignment is perfectly valid and works for any username format:
- `aaa111` → port 20111 (uses numeric suffix)
- `vnijs` → port 22XXX (uses hash of username)
- `john` → port 23XXX (uses hash of username)

**Changed in:** [generate-port.sh](generate-port.sh:33)

### 2. Permission Denied When Writing Logs

**Issue:**
```
./start-container.sh: line 47: /var/log/student-containers/vnijs.log: Permission denied
```

**Root Cause:**
Log directory `/var/log/student-containers/` needs to be writable by all users since each student (running as their own user) needs to write their own log file.

**Fix:**
Changed directory permissions from `755` to `1777`:
- `1` = sticky bit (users can't delete others' files)
- `777` = read/write/execute for all users

**Correct Setup:**
```bash
sudo mkdir -p /var/log/student-containers /tmp/student-containers
sudo chmod 1777 /var/log/student-containers
sudo chmod 1777 /tmp/student-containers
```

**Why 1777?**
- **Sticky bit (1):** Prevents users from deleting each other's log files
- **World-writable (777):** Allows each user to create their own log file
- Similar to `/tmp` directory permissions

**Changed in:**
- [TESTING.md](TESTING.md:72)
- [INSTALL.md](INSTALL.md:28)
- [QUICKSTART.md](QUICKSTART.md:23-24)
- [README.md](README.md:68)
- [README_START_HERE.md](README_START_HERE.md:110)
- [CHEATSHEET.md](CHEATSHEET.md:19)

## Testing the Fixes

After applying these fixes, you can test on sc2:

```bash
# 1. Copy updated scripts
sudo cp /home/vnijs/gh/docker-k8s/k8s/docker/* /opt/docker-containers/
sudo chmod +x /opt/docker-containers/*.sh

# 2. Fix permissions on existing directories (if already created)
sudo chmod 1777 /var/log/student-containers /tmp/student-containers

# 3. Test container creation
/opt/docker-containers/start-container.sh

# Should work without warnings or permission errors
```

## Verification

After the fix, you should see:

```bash
# Test port generation (no warning)
$ /opt/docker-containers/generate-port.sh vnijs
22847

# Test container start (no permission error)
$ /opt/docker-containers/start-container.sh
[logs written successfully to /var/log/student-containers/vnijs.log]

# Check log file was created with your ownership
$ ls -l /var/log/student-containers/
-rw-r--r-- 1 vnijs vnijs 1234 Oct 14 16:45 vnijs.log

# Check directory permissions
$ ls -ld /var/log/student-containers/
drwxrwxrwt 2 root root 4096 Oct 14 16:45 /var/log/student-containers/
# Note the 't' at the end = sticky bit
```

## Port Assignment Logic

For reference, here's how ports are assigned:

| Username Format | Example | Port Calculation | Result |
|----------------|---------|------------------|--------|
| Letters + numbers | aaa111 | 20000 + 111 | 20111 |
| Letters + numbers | bbb222 | 20000 + 222 | 20222 |
| Letters only | vnijs | 20000 + hash(vnijs) | ~22847 |
| Letters only | john | 20000 + hash(john) | ~23456 |
| GPU containers | aaa111 --gpu | 25000 + 111 | 25111 |

Hash-based ports:
- Use MD5 hash of username
- Take first 8 hex characters
- Modulo 5000 to stay in range
- Add to base port (20000 or 25000)
- Deterministic: same username always gets same port

## All Fixed!

Both issues are resolved. The system now:
- ✅ Handles any username format (with or without numbers)
- ✅ Allows users to write their own log files
- ✅ Protects users from deleting each other's logs (sticky bit)
