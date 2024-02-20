
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

Read the log file

    /var/log/fail2ban.log

## Lynis (Security Auditing Tool)

In Debian, as well as in various other Linux distributions, Lynis is a security auditing tool used to assess the security defenses of a system. It performs system checks, security scans, and compliance testing to identify potential vulnerabilities, weaknesses, and configuration issues within the system.

Lynis evaluates various aspects of the system, including:

- System configurations
- Installed software and packages
- User accounts and authentication mechanisms
- File systems and permissions
- Network settings
- Firewalls and ports
- Kernel security

Usage guideline

    sudo apt install -y lynis
    sudo lynis audit system
    cat /var/log/lynis.log
    /etc/lynis/default.conf

## APT-Listbugs

apt-listbugs is a tool used in Debian-based systems (including Ubuntu) to track and display critical bug reports associated with packages before they are installed or upgraded using the APT package manager.

When a package has known critical bugs reported in the Debian Bug Tracking System (BTS), apt-listbugs will alert the user before installing or upgrading that package. It helps prevent potential issues that might arise from known bugs in the software.

    sudo apt-get update
    sudo apt-get install apt-listbugs

## AIDE (Advance Instrusion Detection Environment)

AIDE, which stands for Advanced Intrusion Detection Environment, is an open-source and file integrity checking tool used in Unix-like operating systems, including Linux. It helps detect unauthorized changes to critical system files and directories by creating and maintaining a database of file signatures, permissions, and other attributes.

Key Features:

File Integrity Checking: AIDE compares the current state of files and directories against a previously generated database of known-good states. It identifies changes in file contents, permissions, and other attributes that might indicate unauthorized modifications.

Flexible Configuration: Users can customize what attributes and files to monitor by configuring AIDE's rules and settings based on their system's needs.

Scheduled Scans: AIDE can be scheduled to perform regular scans and comparisons between the current state of files and the stored database to track any alterations.

Notification of Changes: When AIDE detects changes, it notifies the system administrator, allowing them to investigate and take appropriate actions.

    sudo apt install -y aide
    aide --init
    aide --check
    /etc/aide/aide.conf

## ClamAV (Antivirus)

    sudo apt install -y clamav clamav-daemon

## Nmap (Network Scanner)

In Debian, nmap is a powerful open-source network scanning and security auditing tool used to discover hosts and services on a computer network. It's a command-line utility that provides various network exploration and security auditing functionalities.

    sudo apt install -y nmap
    nmap target_host
    nmap -p port1,port2,port3,target_host [Specific Port Scan]
    nmap 192.168.1.1-20 [Scan a Range of IPs]
    nmap -v target_host [verbose output]
    nmap -sV target_host [Service Version Detection]
    nmap -O target_host [Operating System Detection]
    nmap -oN output.txt target_host [Save Output to File]

## iftop (Network Bandwidth Monitoring)

iftop is a command-line network monitoring tool used to display bandwidth usage on an interface in real-time. It provides a visual representation of network traffic, showing information about active connections, their data transfer rates, and the destinations they are communicating with.

    sudo apt install -y iftop
    sudo iftop
    sudo iftop -i eth0 [Interface Selection]
    sudo iftop -F 192.168.1.2 [Filtering]

## Rkhunter (Rootkit hunter)

Rootkit Hunter (rkhunter) is a widely-used open-source security tool designed to detect rootkits, backdoors, and other possible security threats on Unix-like systems, including Debian.

###### Features:
* Rootkit Detection: Rkhunter searches for known rootkits by scanning the system's file system, checking for suspicious files, directories, and system commands.

* Suspicious Activity Detection: It examines common system binaries and files for modifications or suspicious changes that might indicate a security breach.

* Malware Detection: Rkhunter includes checks for common malware, trojans, and backdoors, aiming to identify potentially harmful software.

* System Health Check: It inspects system configurations, processes, and other attributes to ensure they align with expected or secure states.

    sudo apt install -y rkhunter
    sudo rkhunter --update [Update the Rkhunter database]
    sudo rkhunter --check [Perform a system scan using Rkhunter]
    /var/log/rkhunter.log

## ncdu (Disk Usage Analyzer)

    sudo apt install -y ncdu

## iotop (I/O Monitoring)

    sudo apt install -y iotop
    sudo iotop

# lsof (List of open files)

    sudo apt install -y lsof
    lsof -u username
    lsof -p PID
    lsof - [List Network Connections]

## tcpdump (Packer Analyzer)

tcpdump is a command-line network packet analyzer available on Unix-like operating systems, including Debian-based systems like Ubuntu and Debian itself. It allows users to capture and display network packets in real-time or save them to a file for later analysis.

    sudo apt install -y tcpdump
    sudo tcpdump

###### Features:
Packet Capture:

* tcpdump captures and displays network packets, providing detailed information such as source and destination IP addresses, port numbers, packet types, protocols, and packet content.

Filtering:

* Capture Interface: Specify the network interface to monitor (-i eth0).
* Capture Specific Protocols: Filter by protocol (e.g., tcp, udp, icmp).
* Capture Specific Hosts or Networks: Filter by source or destination IP addresses.

Output Control:

* Save to a File: Save captured packets to a file for later analysis (-w filename).
* Read from a File: Read packets from a saved file for analysis (-r filename).

Usage:

    sudo tcpdump -i eth0 [Capture on a Specific Interface]
    sudo tcpdump tcp [Capture Specific Protocol (e.g., TCP)]
    sudo tcpdump host 192.168.1.1 [Capture Specific Host]
    sudo tcpdump port 80 [Capture Specific Port]
    sudo tcpdump -i eth0 -w capture.pcap [Save to a File]
    sudo tcpdump -r capture.pcap [Read from a File]

## screen (Terminal Multiplexer)

    sudo apt install -y screen

# atop (Advance System Monitor)

    sudo apt install -y atop

## jq (JSON Processor)

    sudo apt install -y jq

## exa (Modern ls Command Replacement)

    sudo apt install exa

## fzf (Fuzzy File Finder)

    sudo apt install -y fzf

## gufw Firewall Configuration  Tool (GUI)

    sudo apt install -y gufw
    gufw

## Encryption Tools (GnuPG, VeraCrypt)

    sudo apt install -y gnupg

## Python
 
    sudo apt install -y python3 python3-pip

## Regular utility packages

    sudo add-apt-repository universe
    sudo apt install -y htop neofetch cmatrix net-tools vim nano curl wget git tree unzip
