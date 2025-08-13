Automates core security hardening on Debian systems (VMs/servers) using systemd. The script:
- Disables 'root' SSH login
- Enforces strong password policies with 'pam_pwquality' and password aging
- Installs, enables, and configures 'auditd' with essential audit rules
- Stops and disables common 'unused services' to reduce attack surface


  1. Copy the script to your server:
   ```bash
   nano hardening.sh   # paste the script contents
   chmod +x hardening.sh
   sudo ./hardening.sh

   
