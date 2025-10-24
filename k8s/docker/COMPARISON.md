# Kubernetes vs Plain Docker Comparison

Decision guide for the student container system.

## Quick Recommendation

**Use Plain Docker** (the new system in this directory) because:
- ✅ Same user experience as K8s
- ✅ 90% less complexity
- ✅ Easier to debug and maintain
- ✅ Lower overhead (2-4GB RAM savings)
- ✅ Faster container startup
- ✅ Simpler updates and changes

Kubernetes is overkill for this use case unless you need features like auto-failover, multi-node clusters, or sophisticated scheduling.

---

## Detailed Comparison

| Aspect | Kubernetes (microk8s) | Plain Docker |
|--------|----------------------|--------------|
| **Complexity** | High - K8s concepts, kubectl, yaml | Low - standard Docker commands |
| **Resource Overhead** | 2-4GB RAM for K8s itself | ~100MB |
| **Installation** | microk8s install + addons | Docker only |
| **Maintenance** | K8s upgrades, API changes | Docker upgrades |
| **Container Startup** | 10-15 seconds | 5-10 seconds |
| **Debugging** | Multi-layer (K8s + Docker) | Single layer (Docker) |
| **Port Management** | NodePort (30000-32767) | Any port (we use 20000+) |
| **Logs** | kubectl logs | docker logs |
| **Updates** | Update Deployment, rollout | Pull image, recreate container |
| **Learning Curve** | Steep | Gentle |
| **Documentation** | K8s docs (complex) | Docker docs (standard) |
| **Student Experience** | SSH via ProxyCommand | SSH via ProxyCommand (same) |
| **Multi-node Support** | Yes (can scale across servers) | No (single server) |
| **Auto-failover** | Yes | No |
| **Resource Limits** | Yes (requests/limits) | Yes (--memory, --cpus) |
| **Scheduling** | Advanced (affinity, etc.) | Manual |

---

## Feature-by-Feature Analysis

### ✅ What Both Systems Do Equally Well

- Per-user container isolation
- Home directory mounting
- SSH access via ProxyCommand
- Resource limits (CPU, memory)
- Port assignment
- VS Code Remote-SSH compatibility
- Container lifecycle management
- Auto-start on connection

### 🎯 What Kubernetes Does Better

1. **Multi-node clusters:** Can distribute containers across multiple servers
   - *Do you need this?* **No** - single server (sc2) with 1TB RAM is sufficient

2. **Auto-failover:** If a container crashes, K8s automatically restarts it
   - *Do you need this?* **No** - student containers are stateless (data in home dir)

3. **Advanced scheduling:** Can place containers based on node resources, affinity rules
   - *Do you need this?* **No** - all containers run on same server

4. **Rolling updates:** Can update containers with zero downtime
   - *Do you need this?* **No** - containers can restart (students just reconnect)

5. **Service discovery:** Automatic DNS for containers
   - *Do you need this?* **No** - students connect directly via SSH port

6. **Load balancing:** Built-in load balancer for services
   - *Do you need this?* **No** - one container per student

### 🎯 What Plain Docker Does Better

1. **Simplicity:** Standard Docker commands everyone knows
   - `docker ps`, `docker logs`, `docker restart` vs `kubectl get pods`, `kubectl logs`, etc.

2. **Lower overhead:** No K8s control plane consuming resources
   - **Savings:** 2-4GB RAM, 1-2 CPU cores

3. **Faster startup:** No K8s scheduling overhead
   - **Time saved:** 3-5 seconds per container

4. **Easier debugging:** Single layer to troubleshoot
   - Docker logs + container exec vs K8s pods + deployments + services + networking

5. **Direct control:** No abstraction layer
   - Direct Docker API access

6. **Simpler updates:** Pull image, done
   - vs K8s: update deployment yaml, apply, manage rollout

---

## Real-World Scenarios

### Scenario 1: Student Can't Connect

**Kubernetes:**
```bash
# 1. Check pod status
microk8s kubectl get pods -l user=aaa111

# 2. Check pod details
microk8s kubectl describe pod rsm-msba-aaa111-xxxxx

# 3. Check service
microk8s kubectl get svc rsm-msba-ssh-aaa111

# 4. Check logs
microk8s kubectl logs rsm-msba-aaa111-xxxxx

# 5. Check events
microk8s kubectl get events --sort-by=.metadata.creationTimestamp

# 6. Possibly check K8s networking, CNI, etc.
```

**Docker:**
```bash
# 1. Check container
docker ps -f name=rsm-msba-aaa111

# 2. Check logs
docker logs rsm-msba-aaa111

# 3. Restart if needed
docker restart rsm-msba-aaa111
```

**Winner:** Docker (3 commands vs 6+ commands)

---

### Scenario 2: Update the Container Image

**Kubernetes:**
```bash
# 1. Pull new image
docker pull vnijs/rsm-msba-k8s:latest

# 2. Update deployment yaml or trigger rollout
microk8s kubectl set image deployment/rsm-msba-aaa111 rsm-msba-container=vnijs/rsm-msba-k8s:latest

# 3. Wait for rollout
microk8s kubectl rollout status deployment/rsm-msba-aaa111

# 4. Repeat for each student (or use labels)
# OR: delete all pods to force recreation
```

**Docker:**
```bash
# 1. Pull new image
docker pull vnijs/rsm-msba-k8s:latest

# 2. Students get new image automatically on next connect
# (start-container.sh detects image change and recreates container)
```

**Winner:** Docker (automatic vs manual for each student)

---

### Scenario 3: Check System Resource Usage

**Kubernetes:**
```bash
# 1. Check pod resources
microk8s kubectl top pods

# 2. Check node resources
microk8s kubectl top nodes

# 3. Check Docker (K8s uses Docker underneath)
docker stats

# Note: kubectl top requires metrics-server addon
```

**Docker:**
```bash
# 1. Check container resources
docker stats
```

**Winner:** Docker (simpler)

---

### Scenario 4: Add New Student

**Kubernetes:**
```bash
# 1. Student runs script
/opt/k8s/bin/start-pod.sh

# 2. Script creates deployment and service
microk8s kubectl apply -f /tmp/student-config.yaml

# 3. Wait for pod to be ready
# (handled by script)
```

**Docker:**
```bash
# 1. Student runs script
/opt/docker-containers/start-container.sh

# 2. Script creates container
docker run ...

# 3. Wait for SSH ready
# (handled by script)
```

**Winner:** Tie (both automated, similar workflow)

---

### Scenario 5: Server Crashes (Disaster Recovery)

**Kubernetes:**
```bash
# After reboot:
# 1. Start microk8s
microk8s start

# 2. Wait for K8s to be ready (30-60s)
microk8s status --wait-ready

# 3. Pods should auto-restart (if configured)
# 4. Or students reconnect to trigger recreation
```

**Docker:**
```bash
# After reboot:
# 1. Docker starts automatically (systemd)
# 2. Containers with --restart policy auto-start
# 3. Or students reconnect to trigger start
```

**Winner:** Tie (both recover automatically)

---

### Scenario 6: Scale to Multiple Servers

**Kubernetes:**
```bash
# Add new server to cluster
microk8s add-node
# Run join command on new server

# K8s automatically schedules pods across nodes
```

**Docker:**
```bash
# Need to:
# 1. Set up Docker Swarm or custom orchestration
# 2. Or manually distribute students across servers
# 3. Or use shared NFS for home directories + load balancer
```

**Winner:** Kubernetes (designed for this)

**However:** You have one server with 1TB RAM. Not needed.

---

## Cost-Benefit Analysis

### Kubernetes Costs
- **Time to learn:** 10-20 hours for non-K8s users
- **Time to maintain:** 1-2 hours/month (updates, troubleshooting)
- **Resource overhead:** 2-4GB RAM, 1-2 CPUs (2-3 fewer concurrent students)
- **Complexity:** Higher barrier for troubleshooting

### Kubernetes Benefits
- Multi-node scaling (not needed)
- Auto-failover (nice-to-have, not critical)
- Industry-standard orchestration (learning opportunity?)

### Plain Docker Costs
- No multi-node support (not needed)
- Manual intervention for some tasks (rare)

### Plain Docker Benefits
- **Time to learn:** 2-4 hours
- **Time to maintain:** 0.5-1 hour/month
- **Resource savings:** 2-4GB RAM (2-3 more concurrent students)
- **Simplicity:** Easier troubleshooting for you and TAs

---

## When to Choose Kubernetes

Choose K8s if you:
1. **Need multiple servers:** Distribute load across nodes
2. **Want high availability:** Auto-failover, self-healing
3. **Have K8s expertise:** Team already knows K8s well
4. **Need advanced scheduling:** Complex placement rules
5. **Want industry experience:** Teaching K8s concepts

## When to Choose Plain Docker

Choose Docker if you:
1. ✅ **Single server:** All containers on one machine (your case)
2. ✅ **Simple requirements:** Per-user isolation, SSH access (your case)
3. ✅ **Want simplicity:** Easy to understand and maintain (your case)
4. ✅ **Resource constrained:** Every GB of RAM counts (your case)
5. ✅ **Small team:** Limited admin time (your case)

---

## Migration Considerations

### Moving from K8s to Docker

**Effort:** Low (2-3 hours)

**Steps:**
1. Install new scripts on server
2. Test with one student
3. Stop K8s pods
4. Students update SSH config
5. Keep K8s running in parallel during transition (if needed)

**Rollback:** Easy (old K8s files preserved in `old/` directory)

### Staying with K8s

**Effort:** None (already working)

**Considerations:**
- Current setup works
- Team already familiar
- No migration risk

---

## Final Recommendation

**Switch to Plain Docker** because:

1. **Your requirements are simple:**
   - Single server
   - Per-student isolation
   - SSH access
   - Resource limits

2. **K8s features you don't need:**
   - Multi-node clustering
   - Service discovery
   - Advanced scheduling
   - Load balancing

3. **Benefits of switching:**
   - 2-4GB RAM savings (2-3 more concurrent students)
   - Faster troubleshooting
   - Easier for TAs to help
   - Less maintenance overhead
   - Simpler updates

4. **Low migration risk:**
   - Keep old K8s setup as backup
   - Test with small group first
   - Easy rollback if needed

5. **Same student experience:**
   - Still use VS Code Remote-SSH
   - Still use SSH ProxyCommand
   - Still get their own container
   - No learning curve for students

---

## Decision Matrix

| Criteria | Weight | K8s Score | Docker Score | Weighted |
|----------|--------|-----------|--------------|----------|
| Simplicity | 10 | 3 | 10 | K8s: 30, Docker: 100 |
| Resource Efficiency | 8 | 5 | 10 | K8s: 40, Docker: 80 |
| Maintenance Ease | 9 | 4 | 10 | K8s: 36, Docker: 90 |
| Troubleshooting | 8 | 4 | 9 | K8s: 32, Docker: 72 |
| Scalability | 3 | 10 | 4 | K8s: 30, Docker: 12 |
| High Availability | 2 | 10 | 3 | K8s: 20, Docker: 6 |
| Student Experience | 10 | 10 | 10 | K8s: 100, Docker: 100 |
| **TOTAL** | **50** | - | - | **K8s: 288, Docker: 460** |

**Winner:** Plain Docker (460 vs 288)

---

## Questions to Ask Yourself

1. **Do I plan to add more servers?**
   - If yes: K8s might be worth it
   - If no: Docker is simpler

2. **Do I have time to maintain K8s?**
   - If yes: K8s is fine
   - If no: Docker saves time

3. **Am I teaching K8s concepts?**
   - If yes: K8s has educational value
   - If no: Docker is more practical

4. **Do containers need auto-failover?**
   - If yes: K8s helps
   - If no: Docker is sufficient

5. **How often do I troubleshoot issues?**
   - Often: Docker will save hours
   - Rarely: Either works

---

**Conclusion:** For your use case (150 students, single server, SSH access, VS Code), **Plain Docker is the better choice**. It provides the same functionality with significantly less complexity and overhead.
