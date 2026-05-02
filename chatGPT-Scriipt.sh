#!/bin/bash

# ===============================
# Security Audit & Hardening Script
# Works on Ubuntu & CentOS/RHEL
# Author: Fahd (customizable)
# ===============================

# ---------- ROOT CHECK ----------
if [[ $EUID -ne 0 ]]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

echo "✅ Running as root..."

# ---------- OS DETECTION ----------
if [ -f /etc/debian_version ]; then
    OS="debian"
    PKG_UPDATE="apt update -y"
    PKG_INSTALL="apt install -y"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"
    PKG_UPDATE="yum update -y"
    PKG_INSTALL="yum install -y"
else
    echo "❌ Unsupported OS"
    exit 1
fi

echo "📦 Detected OS: $OS"

# ---------- UPDATE SYSTEM ----------
echo "🔄 Updating system..."
$PKG_UPDATE

# ---------- INSTALL SECURITY TOOLS ----------
echo "🔐 Installing security tools..."

if [ "$OS" = "debian" ]; then
    $PKG_INSTALL ufw fail2ban curl
elif [ "$OS" = "rhel" ]; then
    $PKG_INSTALL firewalld fail2ban curl
    systemctl enable firewalld
    systemctl start firewalld
fi

# ---------- FIREWALL CONFIG ----------
echo "🔥 Configuring firewall..."

if [ "$OS" = "debian" ]; then
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw logging on
    ufw --force enable

elif [ "$OS" = "rhel" ]; then
    firewall-cmd --permanent --set-default-zone=public
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

echo "✅ Firewall configured"

# ---------- FAIL2BAN ----------
echo "🛡️ Setting up Fail2ban..."

systemctl enable fail2ban
systemctl start fail2ban

# ---------- SSH HARDENING ----------
echo "🔑 Hardening SSH..."

SSHD_CONFIG="/etc/ssh/sshd_config"

cp $SSHD_CONFIG ${SSHD_CONFIG}.backup

sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' $SSHD_CONFIG
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' $SSHD_CONFIG
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' $SSHD_CONFIG
sed -i 's/^#X11Forwarding.*/X11Forwarding no/' $SSHD_CONFIG

systemctl restart sshd

echo "✅ SSH hardened"

# ---------- CHECK OPEN PORTS ----------
echo "🔍 Checking open ports..."
ss -tuln

# ---------- CHECK RUNNING SERVICES ----------
echo "📊 Running services..."
systemctl list-units --type=service --state=running

# ---------- AUDIT USERS ----------
echo "👤 Users with shell access:"
awk -F: '$7 ~ /(bash|sh)$/ {print $1}' /etc/passwd

# ---------- CHECK SUDO USERS ----------
echo "🔐 Sudo users:"
getent group sudo || getent group wheel

# ---------- REPORT ----------
REPORT="/var/log/security_audit.log"

echo "📝 Generating report..."

{
echo "==== SECURITY AUDIT REPORT ===="
date
echo ""
echo "OS: $OS"
echo ""
echo "Open Ports:"
ss -tuln
echo ""
echo "Running Services:"
systemctl list-units --type=service --state=running
echo ""
echo "Users:"
awk -F: '$7 ~ /(bash|sh)$/ {print $1}' /etc/passwd
} > $REPORT

echo "✅ Report saved at $REPORT"

echo "🎉 Hardening & audit completed successfully!"