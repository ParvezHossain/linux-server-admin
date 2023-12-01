
## Security and Monitoring

    sudo apt install -y ufw fail2ban

Edit the Fail2ban configuration file for SSH (/etc/fail2ban/jail.local or /etc/fail2ban/jail.d/ssh.conf). You can create or edit a specific configuration file for SSH rules:
      
    sudo nano /etc/fail2ban/jail.local

Add the following configuration (or modify it if it exists):

    [sshd]
    enabled = true
    port = ssh
    filter = sshd
    logpath = /var/log/auth.log
    maxretry = 3
    bantime = 3600

Restart the service after modification

    sudo systemctl start fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl status fail2ban

## Lynis (Security Auditing Tool)

    sudo apt install -y lynis

AIDE (Advance Instrusion Detection Environment)

    sudo apt install -y aide

ClamAV (Antivirus)

    sudo apt install -y clamav clamav-daemon

Nmap (Network Scanner)

    sudo apt install -y nmap

Rkhunter (Rootkit hunter)

    sudo apt install -y rkhunter

iftop (Network Bandwidth Monitoring)

    sudo apt install -y iftop

ncdu (Disk Usage Analyzer)

    sudo apt install -y ncdu

iotop (I/O Monitoring)

    sudo apt install -y iotop

lsof (List of open files)

    sudo apt install -y lsof

tcpdump (Packer Analyzer)

    sudo apt install -y tcpdump

screen (Terminal Multiplexer)

    sudo apt install -y screen

atop (Advance System Monitor)

    sudo apt install -y atop

jq (JSON Processor)

    sudo apt install -y jq

exa (Modern ls Command Replacement)

    sudo apt install exa

fzf (Fuzzy File Finder)

    sudo apt install -y fzf

Firewall Configuration  Tool (GUI)

    sudo apt install -y gufw

Encryption Tools (GnuPG, VeraCrypt)

    sudo apt install -y gnupg

Python
    
    sudo apt install -y python3 python3-pip

Regular utility packages

    sudo add-apt-repository universe
    sudo apt install -y htop neofetch cmatrix net-tools vim nano curl wget git tree unzip
    