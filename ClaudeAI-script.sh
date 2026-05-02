#!/usr/bin/env bash
# =============================================================================
# security_monitor.sh — Lightweight Security Monitor
# Compatible with: Ubuntu/Debian and CentOS/RHEL
# Usage:  sudo bash security_monitor.sh
# Output: /var/log/security_monitor.log
# =============================================================================

# Abort immediately if the script is not run as root — most log files and
# network tools require elevated privileges to read correctly.
[[ "$EUID" -ne 0 ]] && { echo "Run as root."; exit 1; }

REPORT="/var/log/security_monitor.log"  # Where the report is saved
ALERTS=0                                # Running count of issues found

# log()   — writes a normal message to stdout AND appends it to the report file
# alert() — same, but prefixes [ALERT] and increments the alert counter
log()   { echo "$*" | tee -a "$REPORT"; }
alert() { echo "[ALERT] $*" | tee -a "$REPORT"; (( ALERTS++ )); }

# -----------------------------------------------------------------------------
# OS DETECTION
# Ubuntu/Debian stores auth events in /var/log/auth.log
# CentOS/RHEL uses /var/log/secure instead
# We pick the right one based on whether /etc/debian_version exists.
# -----------------------------------------------------------------------------
[[ -f /etc/debian_version ]] && AUTH_LOG="/var/log/auth.log" || AUTH_LOG="/var/log/secure"

log "=== Security Monitor — $(date) ==="

# -----------------------------------------------------------------------------
# 1. FAILED SSH ATTEMPTS
# Searches the auth log for lines indicating a bad password or unknown user.
# A count of 5 or more is flagged as suspicious — tune this to your needs.
# -----------------------------------------------------------------------------
FAILS=$(grep -aE "Failed password|Invalid user" "$AUTH_LOG" 2>/dev/null | wc -l)
log "[SSH] Failed attempts: $FAILS"
(( FAILS >= 5 )) && alert "High SSH failures: $FAILS"

# -----------------------------------------------------------------------------
# 2. TOP OFFENDING IPs
# Extracts every IPv4 address from failed SSH lines, counts how many times
# each one appears, and shows the top 5 worst offenders.
# -----------------------------------------------------------------------------
log "[SSH] Top source IPs:"
grep -aE "Failed password|Invalid user" "$AUTH_LOG" 2>/dev/null \
  | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -rn | head -5 \
  | while read -r c ip; do log "  ${c}x  ${ip}"; done

# -----------------------------------------------------------------------------
# 3. LOGGED-IN USERS
# `who` lists every active session. A root session over a remote terminal
# (pts/*) can indicate an attacker or an admin who forgot to log out.
# -----------------------------------------------------------------------------
log "[USERS] Currently logged in:"
who | tee -a "$REPORT"
who | grep -q '^root' && alert "Root is currently logged in"

# -----------------------------------------------------------------------------
# 4. OPEN LISTENING PORTS
# `ss -tulnp` lists all TCP/UDP sockets in LISTEN state with the process name.
# Review this output for any service you don't recognise or didn't intentionally open.
# -----------------------------------------------------------------------------
log "[PORTS] Listening ports:"
ss -tulnp 2>/dev/null | tee -a "$REPORT"

# -----------------------------------------------------------------------------
# 5. SUMMARY
# Prints the total alert count so you can see at a glance whether anything
# needs immediate attention. Full details are in the report file.
# -----------------------------------------------------------------------------
log "=== $ALERTS alert(s) raised — full report: $REPORT ==="
