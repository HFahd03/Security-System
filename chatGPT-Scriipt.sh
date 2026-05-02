#!/bin/bash

# ==========================================
# UFW Firewall Hardening Script
# Author: Your Name
# Purpose: Configure basic firewall security using UFW
# ==========================================

# ---- Check if script is run with sudo/root ----
# $EUID stores the effective user ID
# Root user has ID = 0
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)."
    exit 1   # stop execution if not root
fi

echo "✅ Running with root privileges..."

# ---- Define variables ----
# This variable stores the allowed IP range for SSH access
SSH_ALLOWED_RANGE="192.168.1.0/24"

# ---- Reset UFW ----
# This removes all existing rules and starts fresh
echo "🔄 Resetting UFW to default settings..."
ufw --force reset

# ---- Set default policies ----
# Deny all incoming traffic (secure default)
echo "🔒 Setting default policies..."
ufw default deny incoming

# Allow all outgoing traffic (normal system behavior)
ufw default allow outgoing

# ---- Allow SSH from specific IP range ----
# Only devices in this network can connect via SSH (port 22)
echo "🔑 Allowing SSH only from $SSH_ALLOWED_RANGE ..."
ufw allow from $SSH_ALLOWED_RANGE to any port 22 proto tcp

# ---- Allow HTTP ----
# Allow web traffic on port 80 (unencrypted web)
echo "🌐 Allowing HTTP traffic..."
ufw allow 80/tcp

# ---- Allow HTTPS ----
# Allow secure web traffic on port 443 (encrypted web)
echo "🔐 Allowing HTTPS traffic..."
ufw allow 443/tcp

# ---- Enable logging ----
# Logging helps monitor firewall activity and detect attacks
echo "📜 Enabling UFW logging..."
ufw logging on

# ---- Enable the firewall ----
# This activates UFW with all defined rules
echo "🚀 Enabling UFW firewall..."
ufw --force enable

# ---- Show firewall status ----
# Displays active rules and configuration
echo "📊 Firewall status:"
ufw status verbose

# ---- End message ----
echo "✅ Firewall hardening completed successfully."
