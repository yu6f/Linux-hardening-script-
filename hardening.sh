#!/bin/bash

# Hardening script for Debian systems
# Run this script with sudo: sudo ./hardening.sh

echo "Starting Debian hardening script..."

# Step 1: Disable root SSH login
echo "Disabling root SSH login..."
if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
  sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
else
  echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config
fi
sudo systemctl restart sshd
echo "Root SSH login disabled."

# Step 2: Enforce strong password policies
echo "Enforcing strong password policies..."

sudo apt-get update
sudo apt-get install -y libpam-pwquality

# Backup common-password file
sudo cp /etc/pam.d/common-password /etc/pam.d/common-password.bak

# Update pam_pwquality settings
if grep -q "^password\s*requisite\s*pam_pwquality.so" /etc/pam.d/common-password; then
  sudo sed -i 's/^password\s*requisite\s*pam_pwquality.so.*/password requisite pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1 enforce_for_root/' /etc/pam.d/common-password
else
  echo "password requisite pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1 enforce_for_root" | sudo tee -a /etc/pam.d/common-password
fi

# Set password aging policies
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   10/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs

echo "Strong password policies enforced."

# Step 3: Install and enable auditd
echo "Installing and enabling auditd..."
sudo apt-get install -y auditd audispd-plugins
sudo systemctl enable auditd
sudo systemctl start auditd

# Add basic audit rules
echo "Adding basic audit rules..."
sudo tee /etc/audit/rules.d/hardening.rules > /dev/null << 'EOF'
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/gshadow -p wa -k gshadow_changes
-w /var/log/auth.log -p wa -k auth_logs
EOF

sudo augenrules --load
echo "auditd installed and configured."

# Step 4: Disable unused services
echo "Disabling unused services..."
services=("telnet" "rpcbind" "avahi-daemon" "cups" "nfs-server")

for svc in "${services[@]}"
do
  if systemctl list-unit-files | grep -q "^${svc}.service"; then
    if systemctl is-active --quiet "$svc"; then
      echo "Stopping $svc service..."
      sudo systemctl stop "$svc"
    fi
    echo "Disabling $svc service..."
    sudo systemctl disable "$svc"
  else
    echo "Service $svc not found, skipping."
  fi
done

echo "Unused services locked down."

echo "Debian hardening script completed successfully."
