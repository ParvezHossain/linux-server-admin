# Secure Remote Access to Ubuntu 22.04/24.04 LTS from Windows

A production-oriented guide for securely administering an Ubuntu Desktop system from a Windows client over a trusted Local Area Network (LAN).

This guide covers two complementary remote-access methods:

1. **SSH** — secure, headless command-line administration.
2. **Native GNOME Remote Desktop over RDP** — graphical desktop access using Ubuntu/GNOME's native Wayland-compatible remote desktop stack.

> **Scope:** This guide is primarily intended for Ubuntu Desktop 22.04/24.04 LTS systems using GNOME. Commands and capabilities can vary slightly with the installed GNOME Remote Desktop version.

---

## Table of Contents

* [Architecture](#architecture)
* [Prerequisites](#prerequisites)
* [1. Network Connectivity](#1-network-connectivity)
* [2. SSH Remote Access](#2-ssh-remote-access)

    * [Install OpenSSH Server](#21-install-openssh-server)
    * [Verify SSH](#22-verify-ssh)
    * [Find the Ubuntu IP Address](#23-find-the-ubuntu-ip-address)
    * [Connect from Windows](#24-connect-from-windows)
    * [Production SSH Hardening](#25-production-ssh-hardening)
* [3. Native GNOME RDP Remote Desktop](#3-native-gnome-rdp-remote-desktop)

    * [Understand the Two GNOME RDP Modes](#31-understand-the-two-gnome-rdp-modes)
    * [Remove xrdp Conflicts](#32-remove-xrdp-conflicts)
    * [Install GNOME Remote Desktop](#33-install-gnome-remote-desktop)
    * [Configure Remote Login](#34-configure-remote-login)
    * [Configure TLS](#35-configure-tls)
    * [Configure RDP Credentials](#36-configure-rdp-credentials)
    * [Enable the Service](#37-enable-the-service)
    * [Verify RDP](#38-verify-rdp)
    * [Connect from Windows](#39-connect-from-windows)
* [4. Firewall Configuration](#4-firewall-configuration)
* [5. Verification Checklist](#5-verification-checklist)
* [6. Troubleshooting](#6-troubleshooting)
* [7. Security Recommendations](#7-security-recommendations)
* [8. Operational Commands](#8-operational-commands)
* [9. Architecture Summary](#9-architecture-summary)

---

# Architecture

The recommended architecture for a local-network Ubuntu workstation is:

```text
+----------------------------+             +-----------------------------+
|       Windows Client       |             |       Ubuntu Host           |
|                            |             |                             |
| PowerShell / OpenSSH       | -- SSH ---> | OpenSSH Server               |
|                            |   TCP/22    |                             |
| mstsc.exe                  |             | GNOME Remote Desktop        |
| Remote Desktop Connection  | -- RDP ---> | Wayland / GNOME              |
|                            |  TCP/3389   |                             |
+----------------------------+             +-----------------------------+
             |                                           |
             +------------- Trusted LAN -----------------+
                         Example:
                     192.168.1.0/24
```

### Ports

| Service | Protocol |   Port | Purpose                     |
| ------- | -------: | -----: | --------------------------- |
| SSH     |      TCP |   `22` | Command-line administration |
| RDP     |      TCP | `3389` | Graphical remote desktop    |

---

# Prerequisites

## Ubuntu Host

Recommended:

* Ubuntu Desktop 24.04 LTS
* GNOME desktop environment
* Wayland session
* Network connectivity
* `sudo` privileges

Ubuntu 22.04 LTS may also work, but GNOME Remote Desktop capabilities depend on the installed GNOME version.

## Windows Client

Windows 10/11 with:

* OpenSSH Client
* Remote Desktop Connection (`mstsc.exe`)
* Network connectivity to the Ubuntu host

## Network

Both machines should be reachable over the same LAN/Wi-Fi network.

Example:

```text
Windows: 192.168.1.20
Ubuntu:  192.168.1.50
Subnet:  192.168.1.0/24
```

Before configuring remote services, verify basic connectivity from Windows:

```powershell
ping 192.168.1.50
```

> **Security note:** This guide assumes a trusted LAN. Do not expose SSH or RDP directly to the public Internet merely by forwarding ports `22` or `3389` from your router. For Internet-based access, prefer a VPN, bastion host, or another controlled remote-access architecture.

---

# 1. Network Connectivity

First determine the Ubuntu host's IP address.

Run on Ubuntu:

```bash
ip -4 addr show
```

A more concise option is:

```bash
hostname -I
```

Example:

```text
192.168.1.50
```

You can also inspect the routing table:

```bash
ip route
```

Look for the interface associated with the default route.

Example:

```text
default via 192.168.1.1 dev wlp2s0
```

The active interface in this example is:

```text
wlp2s0
```

---

# 2. SSH Remote Access

SSH is the preferred mechanism for remote administration because it provides an encrypted command-line session and is lightweight.

## 2.1 Install OpenSSH Server

On the Ubuntu host:

```bash
sudo apt update
sudo apt install -y openssh-server
```

Enable SSH at boot and start it immediately:

```bash
sudo systemctl enable --now ssh
```

---

## 2.2 Verify SSH

Check the service:

```bash
sudo systemctl status ssh --no-pager
```

Expected state:

```text
Active: active (running)
```

Confirm that the server is listening on TCP port `22`:

```bash
sudo ss -lntp | grep ':22'
```

Typical output:

```text
LISTEN 0 128 0.0.0.0:22 0.0.0.0:*
LISTEN 0 128    [::]:22    [::]:*
```

---

## 2.3 Find the Ubuntu IP Address

Run:

```bash
hostname -I
```

Example:

```text
192.168.1.50
```

Assume the Ubuntu host is:

```text
192.168.1.50
```

and the Ubuntu username is:

```text
parvez
```

---

## 2.4 Connect from Windows

Open PowerShell:

```powershell
ssh parvez@192.168.1.50
```

For a first connection, Windows may display a host-key confirmation similar to:

```text
The authenticity of host '192.168.1.50' can't be established.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Verify the host fingerprint when possible, then enter:

```text
yes
```

After authentication, you should receive a shell on the Ubuntu machine.

Verify the remote system:

```bash
hostname
```

```bash
whoami
```

```bash
uname -a
```

---

## 2.5 Production SSH Hardening

Password authentication is convenient for initial setup but should generally not be the preferred long-term authentication mechanism.

### Generate an Ed25519 key on Windows

Run from PowerShell:

```powershell
ssh-keygen -t ed25519 -C "windows-client"
```

Accept the default location or specify a dedicated key.

The public key will typically be stored as:

```text
C:\Users\<username>\.ssh\id_ed25519.pub
```

### Copy the public key to Ubuntu

If `ssh-copy-id` is available:

```bash
ssh-copy-id parvez@192.168.1.50
```

Alternatively, from Windows PowerShell:

```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh parvez@192.168.1.50 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Test key-based authentication:

```powershell
ssh parvez@192.168.1.50
```

Only disable password authentication **after confirming that key-based login works successfully**.

Edit:

```bash
sudo nano /etc/ssh/sshd_config
```

Recommended hardening:

```text
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
```

Before restarting SSH, validate the configuration:

```bash
sudo sshd -t
```

If no errors are reported:

```bash
sudo systemctl restart ssh
```

> **Important:** Keep your existing SSH session open while testing the new configuration. If the new configuration is invalid, the existing session gives you a way to recover.

---

# 3. Native GNOME RDP Remote Desktop

Ubuntu's GNOME desktop includes **GNOME Remote Desktop**, which provides native RDP support and integrates with modern GNOME/Wayland sessions.

This is different from `xrdp`.

The important distinction is:

```text
xrdp
  |
  +-- Separate RDP server
  +-- Often used for Xorg-based sessions
  +-- Can conflict with GNOME's native RDP service

GNOME Remote Desktop
  |
  +-- Native GNOME component
  +-- RDP support
  +-- Wayland/GNOME integration
  +-- Supports remote assistance and remote login
```

GNOME Remote Desktop officially supports remote assistance and a system-wide **headless multi-user remote login** mode. The latter integrates with GDM and allows an RDP client to reach the graphical login screen before selecting a Linux user account.

---

## 3.1 Understand the Two GNOME RDP Modes

This distinction is important.

### Mode A — Remote Assistance / Existing Session

The RDP connection attaches to an already active GNOME graphical session.

Conceptually:

```text
Windows
   |
   | RDP
   v
GNOME Remote Desktop
   |
   v
Existing GNOME session
```

This mode is appropriate when a user is already logged into the Ubuntu desktop.

### Mode B — Remote Login / Headless

The RDP connection reaches the GNOME login screen, allowing the remote user to authenticate into a graphical session.

Conceptually:

```text
Windows
   |
   | RDP
   v
GNOME Remote Desktop
   |
   v
GDM Login Screen
   |
   v
Ubuntu User Session
```

This is the better option for a machine that should be remotely accessible without requiring someone to be physically logged in first.

GNOME documents this as **headless multi-user remote login**.

---

# 3.2 Remove xrdp Conflicts

If `xrdp` was previously installed, it may compete with GNOME Remote Desktop for TCP port `3389`.

Check:

```bash
systemctl status xrdp --no-pager
```

If you want to use native GNOME RDP instead, stop and disable `xrdp`:

```bash
sudo systemctl disable --now xrdp
```

If `xrdp` is no longer required, it can also be removed:

```bash
sudo apt remove -y xrdp
```

Then verify that nothing unexpected owns port `3389`:

```bash
sudo ss -lntp | grep ':3389'
```

---

# 3.3 Install GNOME Remote Desktop

On Ubuntu Desktop, GNOME Remote Desktop is normally already installed.

Verify:

```bash
dpkg -l | grep gnome-remote-desktop
```

If necessary:

```bash
sudo apt update
sudo apt install -y gnome-remote-desktop
```

Verify the installed version:

```bash
gnome-remote-desktop --version
```

Check available configuration options:

```bash
grdctl --help
```

---

# 3.4 Configure Remote Login

For a machine that should be accessible from the Windows RDP client even when nobody is logged into GNOME, configure the **system-wide** GNOME Remote Desktop instance.

The critical distinction is the `--system` option:

```bash
grdctl --system ...
```

This configures the system daemon rather than the current user's GNOME session.

Enable the RDP backend:

```bash
sudo grdctl --system rdp enable
```

Enable GDM and GNOME Remote Desktop:

```bash
sudo systemctl enable --now gdm.service
sudo systemctl enable --now gnome-remote-desktop.service
```

GNOME's upstream documentation uses this system-wide configuration model for remote login.

---

# 3.5 Configure TLS

GNOME Remote Desktop uses TLS for RDP.

For a production environment, configure a persistent certificate and private key rather than relying on an undocumented or temporary configuration.

The GNOME system service uses the following directory under its service account:

```text
~gnome-remote-desktop/.local/share/gnome-remote-desktop/
```

Create the directory:

```bash
sudo -u gnome-remote-desktop \
  mkdir -p ~gnome-remote-desktop/.local/share/gnome-remote-desktop
```

A convenient way to generate a self-signed RDP certificate is FreeRDP's certificate utility:

```bash
sudo -u gnome-remote-desktop \
  winpr-makecert3 -silent -rdp \
  -path ~gnome-remote-desktop/.local/share/gnome-remote-desktop tls
```

Depending on the installed FreeRDP version, the utility may be named:

```text
winpr-makecert
```

instead of:

```text
winpr-makecert3
```

Check availability:

```bash
command -v winpr-makecert3
command -v winpr-makecert
```

Configure the generated certificate and key:

```bash
sudo grdctl --system rdp set-tls-key \
  ~gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.key
```

```bash
sudo grdctl --system rdp set-tls-cert \
  ~gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.crt
```

GNOME's upstream documentation explicitly documents configuring the system RDP service with a TLS key and certificate.

### Self-signed certificate warning

A self-signed certificate provides encryption but does not establish public trust.

Windows may therefore display a certificate warning.

For a home lab or trusted LAN, this may be acceptable.

For a managed enterprise environment, use a certificate issued by an appropriate internal or public CA and configure the corresponding certificate and private key.

---

# 3.6 Configure RDP Credentials

GNOME Remote Desktop requires RDP authentication credentials.

For security, avoid placing passwords directly in shell history or command-line process arguments.

Use:

```bash
sudo grdctl --system rdp set-credentials
```

Follow the interactive prompts.

The system-level RDP credentials are the credentials required to access the remote-login gateway. They are **not necessarily the same credentials as the Linux account used after the graphical login screen appears**. GNOME's documented remote-login architecture uses system-wide RDP credentials to reach the login screen, followed by the user's normal Linux credentials.

You can inspect the current configuration with:

```bash
sudo grdctl --system status
```

Some versions also support:

```bash
sudo grdctl --system status --show-credentials
```

Do not expose the output of the latter in logs, screenshots, GitHub issues, or documentation if it contains authentication information.

---

# 3.7 Enable the RDP Service

Enable the RDP backend:

```bash
sudo grdctl --system rdp enable
```

Ensure the services start automatically:

```bash
sudo systemctl enable --now gdm.service
sudo systemctl enable --now gnome-remote-desktop.service
```

Restart GNOME Remote Desktop after major configuration changes:

```bash
sudo systemctl restart gnome-remote-desktop.service
```

Check the service:

```bash
sudo systemctl status gnome-remote-desktop.service --no-pager
```

Expected state:

```text
Active: active (running)
```

---

# 3.8 Verify RDP

Check GNOME Remote Desktop configuration:

```bash
sudo grdctl --system status
```

Verify port `3389`:

```bash
sudo ss -lntp | grep ':3389'
```

Expected:

```text
LISTEN ... :3389 ...
```

You can also inspect the service logs:

```bash
sudo journalctl -u gnome-remote-desktop.service -n 100 --no-pager
```

For live troubleshooting:

```bash
sudo journalctl -u gnome-remote-desktop.service -f
```

---

# 4. Firewall Configuration

Ubuntu commonly uses `ufw` as its firewall management interface.

Check whether it is enabled:

```bash
sudo ufw status verbose
```

If `ufw` is active, allow SSH:

```bash
sudo ufw allow 22/tcp comment 'OpenSSH'
```

Allow RDP:

```bash
sudo ufw allow 3389/tcp comment 'GNOME Remote Desktop'
```

Reload:

```bash
sudo ufw reload
```

Verify:

```bash
sudo ufw status numbered
```

---

## Restrict Access to the Local Network

For a trusted LAN, a better firewall rule is to restrict access to the local subnet instead of allowing the entire network interface.

For example, if the LAN is:

```text
192.168.1.0/24
```

use:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp comment 'SSH from LAN'
```

```bash
sudo ufw allow from 192.168.1.0/24 to any port 3389 proto tcp comment 'RDP from LAN'
```

Then remove broad rules if they are no longer required:

```bash
sudo ufw status numbered
```

Delete the appropriate rule by number:

```bash
sudo ufw delete <rule-number>
```

> **Do not blindly delete firewall rules by copying the example rule number.** Always inspect `ufw status numbered` first.

---

# 5. Verification Checklist

Run the following checks on the Ubuntu host.

### Operating system

```bash
lsb_release -a
```

### Desktop session

```bash
echo "$XDG_SESSION_TYPE"
```

For a native Wayland desktop session, the expected result is:

```text
wayland
```

### SSH

```bash
sudo systemctl is-active ssh
```

Expected:

```text
active
```

### GNOME Remote Desktop

```bash
sudo systemctl is-active gnome-remote-desktop
```

Expected:

```text
active
```

### RDP configuration

```bash
sudo grdctl --system status
```

### Listening ports

```bash
sudo ss -lntp | grep -E ':(22|3389)\b'
```

Expected services:

```text
TCP/22
TCP/3389
```

### Firewall

```bash
sudo ufw status verbose
```

---

# 6. Connect from Windows

## 6.1 SSH

Open PowerShell:

```powershell
ssh <ubuntu-username>@<ubuntu-ip>
```

Example:

```powershell
ssh parvez@192.168.1.50
```

---

## 6.2 RDP

Press:

```text
Win + R
```

Enter:

```text
mstsc
```

Press **Enter**.

In the **Computer** field enter:

```text
192.168.1.50
```

Click:

```text
Connect
```

Enter the RDP credentials configured using:

```bash
sudo grdctl --system rdp set-credentials
```

If remote login is configured correctly, GNOME/GDM should provide the graphical login flow.

Authenticate with the appropriate Ubuntu user account.

---

# 7. Troubleshooting

## 7.1 SSH: Connection Refused

### Symptoms

```text
ssh: connect to host 192.168.1.50 port 22: Connection refused
```

### Check SSH

```bash
sudo systemctl status ssh --no-pager
```

Restart if necessary:

```bash
sudo systemctl restart ssh
```

Check port:

```bash
sudo ss -lntp | grep ':22'
```

Check firewall:

```bash
sudo ufw status verbose
```

---

## 7.2 SSH: Connection Timeout

A timeout usually indicates a network path or firewall problem rather than an authentication problem.

From Windows:

```powershell
Test-NetConnection 192.168.1.50 -Port 22
```

For RDP:

```powershell
Test-NetConnection 192.168.1.50 -Port 3389
```

Check:

* Ubuntu IP address
* Wi-Fi/LAN connectivity
* Router isolation
* AP/client isolation
* Ubuntu firewall
* Windows firewall/network policy
* VLAN/subnet configuration

---

## 7.3 RDP: Port 3389 Already in Use

Check:

```bash
sudo ss -lntp | grep ':3389'
```

Identify the process:

```bash
sudo lsof -iTCP:3389 -sTCP:LISTEN
```

If `xrdp` owns the port:

```bash
sudo systemctl disable --now xrdp
```

Then restart GNOME Remote Desktop:

```bash
sudo systemctl restart gnome-remote-desktop.service
```

---

## 7.4 RDP: Service Is Not Running

Check:

```bash
sudo systemctl status gnome-remote-desktop.service --no-pager
```

View recent logs:

```bash
sudo journalctl -u gnome-remote-desktop.service -n 100 --no-pager
```

Restart:

```bash
sudo systemctl restart gnome-remote-desktop.service
```

Then verify:

```bash
sudo ss -lntp | grep ':3389'
```

---

## 7.5 RDP: Authentication Fails

Check the system configuration:

```bash
sudo grdctl --system status
```

Reset the RDP credentials interactively:

```bash
sudo grdctl --system rdp set-credentials
```

Restart the service:

```bash
sudo systemctl restart gnome-remote-desktop.service
```

Make sure you distinguish between:

```text
RDP system credentials
        |
        v
Access to GNOME/GDM remote login
        |
        v
Ubuntu user credentials
        |
        v
Actual desktop session
```

The system RDP credentials and the Linux user's credentials serve different roles in the remote-login architecture.

---

## 7.6 RDP: Black Screen or Session Problems

First determine whether you are using:

```text
Remote Assistance
```

or:

```text
Remote Login
```

These are different GNOME Remote Desktop modes.

Check:

```bash
sudo grdctl --system status
```

Also inspect:

```bash
loginctl
```

and:

```bash
loginctl list-sessions
```

If you are using the system remote-login configuration, verify that GDM is running:

```bash
sudo systemctl status gdm.service --no-pager
```

Check GNOME Remote Desktop logs:

```bash
sudo journalctl -u gnome-remote-desktop.service -n 200 --no-pager
```

---

## 7.7 RDP: Certificate Warning

A self-signed certificate is expected to produce a trust warning in many clients.

The warning does **not** necessarily mean that the connection is unencrypted.

The important distinction is:

```text
Self-signed certificate
        |
        +-- Encryption: Yes
        |
        +-- Public/CA trust: No
```

For production environments, use a certificate issued by a trusted CA.

---

## 7.8 Windows Cannot Reach Ubuntu

From Windows:

```powershell
ping 192.168.1.50
```

Then:

```powershell
Test-NetConnection 192.168.1.50 -Port 22
```

and:

```powershell
Test-NetConnection 192.168.1.50 -Port 3389
```

If both fail, investigate the network before changing SSH/RDP configuration.

Common causes include:

* Incorrect IP address
* Different VLANs
* Wi-Fi client isolation
* Router AP isolation
* Firewall rules
* Incorrect subnet
* Ubuntu connected to a different network
* Windows connected through a VPN that changes routing

---

# 8. Security Recommendations

## 8.1 Do Not Expose RDP Directly to the Internet

Avoid:

```text
Internet
   |
   +--> TCP 3389
```

Directly exposing RDP increases attack surface significantly.

Prefer:

```text
Internet
   |
   v
VPN
   |
   v
Private LAN
   |
   +--> RDP 3389
```

For remote administration, SSH can similarly be protected behind a VPN or bastion host.

---

## 8.2 Prefer SSH Keys

For SSH:

```text
Ed25519 key
     |
     v
Public key -> Ubuntu authorized_keys
     |
     v
Private key remains on Windows
```

Never copy the private key to the Ubuntu server.

---

## 8.3 Disable Root SSH Login

In:

```text
/etc/ssh/sshd_config
```

use:

```text
PermitRootLogin no
```

---

## 8.4 Disable Password Authentication After Testing Keys

Recommended:

```text
PubkeyAuthentication yes
PasswordAuthentication no
```

Always validate first:

```bash
sudo sshd -t
```

Then:

```bash
sudo systemctl restart ssh
```

Keep an existing administrative session open until the new configuration has been successfully tested.

---

## 8.5 Restrict Firewall Rules

Instead of:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 3389/tcp
```

prefer LAN-restricted rules where appropriate:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
```

```bash
sudo ufw allow from 192.168.1.0/24 to any port 3389 proto tcp
```

Replace `192.168.1.0/24` with your actual trusted subnet.

---

## 8.6 Use DHCP Reservation

For a workstation or home server, configure a DHCP reservation on the router so that the Ubuntu host receives the same address after reboot.

Example:

```text
Ubuntu Host
MAC Address: xx:xx:xx:xx:xx:xx
Reserved IP: 192.168.1.50
```

This is generally preferable to manually configuring a static IP on the host when the network is managed by DHCP.

---

## 8.7 Protect RDP Credentials

Do not store commands containing real credentials in:

* Git repositories
* Shell history
* README files
* Screenshots
* CI logs
* Public documentation
* Issue trackers

Prefer interactive credential configuration:

```bash
sudo grdctl --system rdp set-credentials
```

This is particularly important because passing a password directly as a command-line argument can expose it through process inspection on affected systems.

---

## 8.8 Keep Ubuntu Updated

Regularly apply security updates:

```bash
sudo apt update
sudo apt upgrade
```

For unattended security updates, consider:

```bash
sudo apt install -y unattended-upgrades
```

Then review your organization's update policy before enabling automatic package changes on critical systems.

---

# 9. Operational Commands

## SSH

### Start

```bash
sudo systemctl start ssh
```

### Stop

```bash
sudo systemctl stop ssh
```

### Restart

```bash
sudo systemctl restart ssh
```

### Status

```bash
sudo systemctl status ssh
```

### Verify port

```bash
sudo ss -lntp | grep ':22'
```

---

## GNOME Remote Desktop

### Start

```bash
sudo systemctl start gnome-remote-desktop
```

### Stop

```bash
sudo systemctl stop gnome-remote-desktop
```

### Restart

```bash
sudo systemctl restart gnome-remote-desktop
```

### Status

```bash
sudo systemctl status gnome-remote-desktop
```

### RDP status

```bash
sudo grdctl --system status
```

### Enable RDP

```bash
sudo grdctl --system rdp enable
```

### Disable RDP

```bash
sudo grdctl --system rdp disable
```

### View logs

```bash
sudo journalctl -u gnome-remote-desktop.service -n 100 --no-pager
```

### Follow logs

```bash
sudo journalctl -u gnome-remote-desktop.service -f
```

### Verify RDP port

```bash
sudo ss -lntp | grep ':3389'
```

---

# 10. Final Production Checklist

Before considering the system ready for regular remote administration, verify all of the following:

* [ ] Ubuntu is fully updated.
* [ ] Ubuntu has a predictable LAN address through DHCP reservation or equivalent network management.
* [ ] OpenSSH Server is installed.
* [ ] SSH is enabled and running.
* [ ] SSH key-based authentication has been tested.
* [ ] Root SSH login is disabled.
* [ ] Password-based SSH authentication is disabled after successful key testing.
* [ ] GNOME Remote Desktop is installed.
* [ ] `xrdp` is disabled/removed if native GNOME RDP is being used.
* [ ] RDP is configured for the intended GNOME mode.
* [ ] TLS certificate and private key are configured.
* [ ] RDP credentials are configured securely.
* [ ] GDM is enabled for remote-login scenarios.
* [ ] GNOME Remote Desktop is enabled at boot.
* [ ] TCP `22` is reachable from the trusted network.
* [ ] TCP `3389` is reachable from the trusted network.
* [ ] UFW rules are restricted to the appropriate network where possible.
* [ ] RDP is not directly exposed to the public Internet.
* [ ] Real passwords/secrets are not present in Git history or documentation.
* [ ] SSH and GNOME Remote Desktop logs have been checked after configuration.
* [ ] Remote access has been tested after a full system reboot.

---

# 11. Reference Architecture

The resulting production-oriented LAN setup should look like this:

```text
                         TRUSTED LAN
                    192.168.1.0/24
                            |
            +---------------+---------------+
            |                               |
            |                               |
   +--------v---------+             +-------v--------+
   |  Windows Client  |             |  Ubuntu Host   |
   |                  |             |                |
   | PowerShell       |             | OpenSSH        |
   | ssh              |-----------> | TCP 22         |
   |                  |             |                |
   | mstsc.exe        |-----------> | GNOME RDP      |
   | Remote Desktop   |   TCP 3389  | TCP 3389       |
   +------------------+             |                |
                                    | GNOME / GDM    |
                                    | Wayland        |
                                    +----------------+
```

The recommended separation of responsibilities is:

```text
SSH
 |
 +-- Server administration
 +-- Package management
 +-- Configuration
 +-- Logs
 +-- Development
 +-- Automation
 +-- Emergency recovery

RDP
 |
 +-- GUI applications
 +-- GNOME desktop
 +-- Graphical administration
 +-- Desktop-only workflows
```

For routine system administration, **SSH should remain the primary management interface**. RDP should be treated as the graphical access layer rather than a replacement for SSH.

---

## Summary

For a modern Ubuntu GNOME workstation, the preferred architecture is:

```text
                Windows
                   |
          +--------+--------+
          |                 |
       SSH/22            RDP/3389
          |                 |
          v                 v
      OpenSSH         GNOME Remote
       Server            Desktop
          |                 |
          |             GDM / GNOME
          |                 |
          +--------+--------+
                   |
             Ubuntu Host
```

Use **OpenSSH with Ed25519 keys** for secure command-line administration and automation.

Use **GNOME Remote Desktop with native RDP** when graphical access is required.

Keep both services restricted to trusted networks, avoid exposing ports `22` and `3389` directly to the Internet, use persistent TLS configuration for RDP, and keep authentication secrets out of source control.

### Official References

* [GNOME Remote Desktop](https://github.com/GNOME/gnome-remote-desktop)
* [Ubuntu `grdctl` manual](https://manpages.ubuntu.com/manpages/latest/man1/grdctl.1.html)
* [Ubuntu Documentation](https://documentation.ubuntu.com/)
