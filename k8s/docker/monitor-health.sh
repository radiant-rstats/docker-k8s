#!/bin/bash
# Health monitoring script to check system status and send alerts
# Run this via cron hourly: 0 * * * * /opt/docker-containers/monitor-health.sh

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.env"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"
MONITOR_LOG="${LOG_DIR}/monitor.log"

# Alert tracking (to avoid duplicate emails)
ALERT_STATE_FILE="${TMP_DIR}/alert_state"
mkdir -p "$TMP_DIR"
touch "$ALERT_STATE_FILE"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$MONITOR_LOG"
}

# Alert function - sends email if issue is new or ongoing
send_alert() {
    local ALERT_TYPE="$1"
    local ALERT_MESSAGE="$2"
    local SEVERITY="$3"  # INFO, WARNING, CRITICAL

    log "$SEVERITY: $ALERT_TYPE - $ALERT_MESSAGE"

    # Check if we've already alerted about this issue recently (within last hour)
    LAST_ALERT=$(grep "^${ALERT_TYPE}:" "$ALERT_STATE_FILE" 2>/dev/null | cut -d: -f2)
    NOW=$(date +%s)

    if [ -n "$LAST_ALERT" ]; then
        TIME_SINCE_ALERT=$((NOW - LAST_ALERT))
        if [ $TIME_SINCE_ALERT -lt 3600 ]; then
            # Already alerted within last hour, skip
            return
        fi
    fi

    # Send email alert
    SUBJECT="[$SEVERITY] Docker Container System - $ALERT_TYPE"
    EMAIL_BODY="Server: $(hostname)
Time: $(date)
Alert Type: $ALERT_TYPE
Severity: $SEVERITY

$ALERT_MESSAGE

---
This is an automated alert from the student container monitoring system.
"

    # Send email (using mail command or sendmail)
    if command -v mail &> /dev/null; then
        echo "$EMAIL_BODY" | mail -s "$SUBJECT" "$ALERT_EMAIL"
    elif command -v sendmail &> /dev/null; then
        echo -e "Subject: $SUBJECT\n\n$EMAIL_BODY" | sendmail "$ALERT_EMAIL"
    else
        log "ERROR: Cannot send email - no mail command found"
    fi

    # Update alert state file
    sed -i "/^${ALERT_TYPE}:/d" "$ALERT_STATE_FILE"
    echo "${ALERT_TYPE}:${NOW}" >> "$ALERT_STATE_FILE"
}

log "Starting health monitoring"

ISSUES_FOUND=0

# ===== CHECK 1: System RAM Usage =====
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
USED_RAM=$(free -m | awk '/^Mem:/{print $3}')
RAM_PERCENT=$((USED_RAM * 100 / TOTAL_RAM))

log "RAM Usage: ${RAM_PERCENT}% (${USED_RAM}MB / ${TOTAL_RAM}MB)"

if [ $RAM_PERCENT -ge $RAM_WARNING_THRESHOLD ]; then
    send_alert "HIGH_RAM_USAGE" \
        "System RAM usage is at ${RAM_PERCENT}% (${USED_RAM}MB / ${TOTAL_RAM}MB)
Threshold: ${RAM_WARNING_THRESHOLD}%

Top RAM consumers:
$(docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}' | head -10)" \
        "WARNING"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# ===== CHECK 2: Disk Space Usage =====
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
DISK_INFO=$(df -h / | awk 'NR==2 {print $3 " used of " $2}')

log "Disk Usage: ${DISK_USAGE}% ($DISK_INFO)"

if [ $DISK_USAGE -ge $DISK_WARNING_THRESHOLD ]; then
    send_alert "HIGH_DISK_USAGE" \
        "Root filesystem usage is at ${DISK_USAGE}% ($DISK_INFO)
Threshold: ${DISK_WARNING_THRESHOLD}%

Disk space breakdown:
$(df -h)

Docker disk usage:
$(docker system df)" \
        "WARNING"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# ===== CHECK 3: Crashed/Unhealthy Containers =====
CRASHED_CONTAINERS=$(docker ps -a --filter "status=exited" --filter "name=${CONTAINER_PREFIX}-" --filter "name=${CONTAINER_PREFIX_GPU}-" --format '{{.Names}} (exited {{.Status}})')

if [ -n "$CRASHED_CONTAINERS" ]; then
    CRASH_COUNT=$(echo "$CRASHED_CONTAINERS" | wc -l)
    log "Found $CRASH_COUNT crashed container(s)"

    send_alert "CRASHED_CONTAINERS" \
        "Found $CRASH_COUNT student container(s) in exited state:

$CRASHED_CONTAINERS

These containers may have crashed or been manually stopped.
Students may experience connection issues." \
        "WARNING"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# ===== CHECK 4: Container Restart Count =====
# Check for containers that have restarted multiple times (indicates instability)
RESTART_ISSUES=$(docker ps --format '{{.Names}} {{.Status}}' --filter "name=${CONTAINER_PREFIX}-" --filter "name=${CONTAINER_PREFIX_GPU}-" | grep "Restarting\|restart" | head -5)

if [ -n "$RESTART_ISSUES" ]; then
    log "Found containers with restart issues"

    send_alert "CONTAINER_RESTART_LOOP" \
        "Some containers are experiencing restart issues:

$RESTART_ISSUES

This may indicate configuration problems or resource exhaustion." \
        "CRITICAL"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# ===== CHECK 5: Docker Daemon Health =====
if ! docker info &> /dev/null; then
    log "ERROR: Docker daemon is not responding"

    send_alert "DOCKER_DAEMON_DOWN" \
        "Docker daemon is not responding!
Cannot check container status.
Immediate attention required." \
        "CRITICAL"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    exit 1
fi

# ===== CHECK 6: Port Conflicts =====
# Check for duplicate port assignments
PORT_CONFLICTS=$(docker ps --format '{{.Ports}}' | grep -o '0.0.0.0:[0-9]*' | sort | uniq -d)

if [ -n "$PORT_CONFLICTS" ]; then
    log "WARNING: Found port conflicts"

    CONFLICT_DETAILS=$(docker ps --format '{{.Names}} {{.Ports}}' | grep -E "$(echo $PORT_CONFLICTS | sed 's/0.0.0.0://g' | tr ' ' '|')")

    send_alert "PORT_CONFLICTS" \
        "Found duplicate port assignments:

$CONFLICT_DETAILS

This indicates a serious configuration issue." \
        "CRITICAL"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# ===== CHECK 7: Running Container Count =====
RUNNING_COUNT=$(docker ps --filter "name=${CONTAINER_PREFIX}-" --filter "name=${CONTAINER_PREFIX_GPU}-" --format '{{.Names}}' | wc -l)
log "Running containers: $RUNNING_COUNT"

# Send informational summary if many containers running (no alert, just log)
if [ $RUNNING_COUNT -gt 20 ]; then
    log "INFO: High container count ($RUNNING_COUNT running)"
fi

# ===== CHECK 8: Image Update Available =====
# Check if the base image has been updated on Docker Hub (optional, can be slow)
# Uncomment if you want to check for image updates
# NEEDS_UPDATE=$(docker pull "$DOCKER_IMAGE" 2>&1 | grep -c "Downloaded newer image")
# if [ $NEEDS_UPDATE -gt 0 ]; then
#     log "INFO: New image available for $DOCKER_IMAGE"
# fi

# ===== Summary =====
if [ $ISSUES_FOUND -eq 0 ]; then
    log "Health check complete: All systems healthy"
else
    log "Health check complete: $ISSUES_FOUND issue(s) found and reported"
fi

# Clean up old monitor logs (keep last 30 days)
find "$LOG_DIR" -name "monitor.log.*" -type f -mtime +30 -delete 2>/dev/null

exit 0
