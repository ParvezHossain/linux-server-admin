# Jenkins Installation and Configuration on Ubuntu

This document provides a step-by-step guide for installing **Jenkins LTS** on Ubuntu using the official Jenkins Debian/Ubuntu package repository.

The installation uses:

* **Jenkins LTS**
* **Java 21+**
* **APT package manager**
* **systemd** for Jenkins service management
* Default Jenkins port: **8080**
* Optional custom Jenkins port: **8082**

> **Important:** Do not install Jenkins using Snap if you want to follow this documentation. This guide uses the official Jenkins `.deb` package through APT.

---

## 1. Prerequisites

Before installing Jenkins, make sure:

* Ubuntu is installed and updated.
* You have `sudo` privileges.
* Port `8080` or your desired Jenkins port is available.
* Internet access is available.
* Java 21 or later is installed.

Jenkins currently requires **Java 21 or later** for the current Linux package.

---

# 2. Install Java

Update the APT package index:

```bash
sudo apt update
```

Install Java 21 and Fontconfig:

```bash
sudo apt install fontconfig openjdk-21-jre -y
```

Verify the Java installation:

```bash
java -version
```

Example:

```text
openjdk version "21.x.x"
```

> **Note:** If your system has a newer supported Java version, such as Java 25, `java -version` may show that version instead. Make sure the installed Java version is supported by the Jenkins version you are installing.

---

# 3. Add the Official Jenkins LTS Repository

We will use the official **Jenkins LTS Debian repository**.

## 3.1 Create the APT keyring directory

```bash
sudo mkdir -p /etc/apt/keyrings
```

## 3.2 Download the Jenkins signing key

Use the current Jenkins repository signing key:

```bash
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
```

> **Important:** Jenkins changed its Linux repository signing key in 2026. Use the current key from the official Jenkins repository rather than an old tutorial's key.

## 3.3 Add the Jenkins LTS repository

```bash
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
```

You can verify the repository file:

```bash
cat /etc/apt/sources.list.d/jenkins.list
```

Expected output:

```text
deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/
```

---

# 4. Install Jenkins

Update the APT package index:

```bash
sudo apt update
```

Install Jenkins:

```bash
sudo apt install jenkins -y
```

The `.deb` installation creates a normal **systemd service** and a dedicated **jenkins user**.

The default Jenkins home directory is:

```text
/var/lib/jenkins
```

---

# 5. Enable Jenkins at System Startup

Enable Jenkins so that it automatically starts when Ubuntu boots:

```bash
sudo systemctl enable jenkins
```

Start Jenkins:

```bash
sudo systemctl start jenkins
```

Check the Jenkins service:

```bash
sudo systemctl status jenkins
```

You should see:

```text
Active: active (running)
```

Press `q` to exit the status screen.

---

# 6. Verify the Jenkins Port

By default, Jenkins runs on port:

```text
8080
```

Check whether Jenkins is listening on port 8080:

```bash
sudo lsof -i :8080
```

Alternatively:

```bash
sudo ss -ltnp | grep :8080
```

Example:

```text
LISTEN 0 50 0.0.0.0:8080 0.0.0.0:*
```

If Jenkins is listening on port 8080, open the following URL in your browser:

```text
http://localhost:8080
```

For a remote server:

```text
http://SERVER_IP:8080
```

---

# 7. Unlock Jenkins

When Jenkins is opened for the first time, you will see:

```text
Unlock Jenkins
```

Jenkins generates an initial administrator password during installation.

Get the password using:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy the generated password and paste it into the **Administrator password** field.

---

# 8. Complete Initial Jenkins Setup

After entering the administrator password:

1. Select **Install suggested plugins**.
2. Wait for the plugins to install.
3. Create the first Jenkins administrator account.
4. Confirm the Jenkins URL.
5. Finish the setup.

After completing the setup, Jenkins will be ready to use.

---

# 9. Jenkins Installation Structure

After installation, the environment should look approximately like this:

```text
Ubuntu
│
├── Java
│     └── Java 21 or later
│
├── Jenkins
│     ├── Installed via: APT (.deb)
│     ├── Service: systemd
│     ├── User: jenkins
│     ├── Home: /var/lib/jenkins
│     └── Default Port: 8080
│
└── Repository
      └── Jenkins LTS
```

---

# 10. Useful Jenkins Commands

## Start Jenkins

```bash
sudo systemctl start jenkins
```

## Stop Jenkins

```bash
sudo systemctl stop jenkins
```

## Restart Jenkins

```bash
sudo systemctl restart jenkins
```

## Check Jenkins Status

```bash
sudo systemctl status jenkins
```

## Enable Jenkins at Boot

```bash
sudo systemctl enable jenkins
```

## Disable Jenkins at Boot

```bash
sudo systemctl disable jenkins
```

---

# 11. Jenkins Logs

View Jenkins logs:

```bash
sudo journalctl -u jenkins
```

Follow Jenkins logs in real time:

```bash
sudo journalctl -u jenkins -f
```

View the latest 100 log entries:

```bash
sudo journalctl -u jenkins -n 100 --no-pager
```

---

# 12. Get the Initial Administrator Password

If you need the initial password again:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

> **Note:** This password is primarily needed during the initial Jenkins setup. After creating the administrator account, Jenkins uses the credentials you configured.

---

# 13. Change Jenkins Port

By default, Jenkins uses:

```text
8080
```

For this example, we will change Jenkins to:

```text
8082
```

## 13.1 Create the systemd override directory

```bash
sudo mkdir -p /etc/systemd/system/jenkins.service.d
```

## 13.2 Create the override configuration

Open the configuration file:

```bash
sudo nano /etc/systemd/system/jenkins.service.d/override.conf
```

Add:

```ini
[Service]
Environment="JENKINS_PORT=8082"
```

Save the file:

* `Ctrl + O`
* Press `Enter`
* `Ctrl + X`

---

# 14. Verify the Port Configuration

Check the override file:

```bash
sudo cat /etc/systemd/system/jenkins.service.d/override.conf
```

Expected output:

```ini
[Service]
Environment="JENKINS_PORT=8082"
```

---

# 15. Reload systemd

After changing a systemd configuration, reload the systemd configuration:

```bash
sudo systemctl daemon-reload
```

---

# 16. Restart Jenkins

Restart Jenkins:

```bash
sudo systemctl restart jenkins
```

Check the service:

```bash
sudo systemctl status jenkins
```

The expected status is:

```text
Active: active (running)
```

---

# 17. Verify the New Jenkins Port

Check port 8082:

```bash
sudo lsof -i :8082
```

Or:

```bash
sudo ss -ltnp | grep :8082
```

If Jenkins is listening on port 8082, open:

```text
http://localhost:8082
```

For a remote server:

```text
http://SERVER_IP:8082
```

---

# 18. Verify systemd Received the Configuration

Run:

```bash
sudo systemctl show jenkins --property=Environment
```

Expected output:

```text
Environment=JENKINS_PORT=8082
```

This confirms that systemd has received the custom Jenkins port configuration.

---

# 19. Verify the Complete Jenkins Configuration

The following commands are useful for troubleshooting:

### Check Jenkins service

```bash
sudo systemctl status jenkins
```

### Check systemd configuration

```bash
sudo systemctl cat jenkins
```

### Check Jenkins environment variables

```bash
sudo systemctl show jenkins --property=Environment
```

### Check port

```bash
sudo lsof -i :8082
```

### Check listening ports

```bash
sudo ss -ltnp | grep :8082
```

### Check recent logs

```bash
sudo journalctl -u jenkins -n 100 --no-pager
```

---

# 20. Final Configuration

After changing the port, the final environment looks like:

```text
Ubuntu
│
├── Java
│     └── Java 21+
│
├── Jenkins
│     ├── Installation: APT (.deb)
│     ├── Service: systemd
│     ├── User: jenkins
│     ├── Home: /var/lib/jenkins
│     └── Port: 8082
│
└── Jenkins URL
      └── http://localhost:8082
```

---

# 21. Quick Reference

| Task                  | Command                                                  |
| --------------------- | -------------------------------------------------------- |
| Start Jenkins         | `sudo systemctl start jenkins`                           |
| Stop Jenkins          | `sudo systemctl stop jenkins`                            |
| Restart Jenkins       | `sudo systemctl restart jenkins`                         |
| Check status          | `sudo systemctl status jenkins`                          |
| Enable at boot        | `sudo systemctl enable jenkins`                          |
| Disable at boot       | `sudo systemctl disable jenkins`                         |
| View logs             | `sudo journalctl -u jenkins`                             |
| Follow logs           | `sudo journalctl -u jenkins -f`                          |
| Initial password      | `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` |
| Check port 8080       | `sudo lsof -i :8080`                                     |
| Check port 8082       | `sudo lsof -i :8082`                                     |
| Check listening ports | `sudo ss -ltnp`                                          |
| Check environment     | `sudo systemctl show jenkins --property=Environment`     |
| View service config   | `sudo systemctl cat jenkins`                             |

---

# 22. Troubleshooting

## Jenkins is not starting

Check the status:

```bash
sudo systemctl status jenkins
```

Then check the logs:

```bash
sudo journalctl -u jenkins -n 100 --no-pager
```

---

## Port 8082 is already in use

Check:

```bash
sudo lsof -i :8082
```

If another application is using the port, choose another available port.

For example:

```ini
[Service]
Environment="JENKINS_PORT=8083"
```

Then reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

---

## Jenkins is still using port 8080

Check the systemd environment:

```bash
sudo systemctl show jenkins --property=Environment
```

It should contain:

```text
Environment=JENKINS_PORT=8082
```

Also check the override:

```bash
sudo cat /etc/systemd/system/jenkins.service.d/override.conf
```

It should contain:

```ini
[Service]
Environment="JENKINS_PORT=8082"
```

Then run:

```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

---

# 23. Security Notes

Jenkins is a powerful automation server and should not be exposed publicly without appropriate security controls.

For production environments:

* Use HTTPS.
* Use a reverse proxy such as Nginx.
* Restrict access using firewall rules.
* Use strong administrator credentials.
* Keep Jenkins and plugins updated.
* Avoid exposing Jenkins directly to the public internet.
* Do not store passwords, API keys, tokens, or other secrets directly in this documentation.
* Use Jenkins Credentials for sensitive values.

For local development, accessing Jenkins through:

```text
http://localhost:8082
```

is generally sufficient.

---

## Official Jenkins Documentation

Jenkins Linux installation documentation:

[https://www.jenkins.io/doc/book/installing/linux/](https://www.jenkins.io/doc/book/installing/linux/)

Jenkins systemd service documentation:

[https://www.jenkins.io/doc/book/system-administration/systemd-services/](https://www.jenkins.io/doc/book/system-administration/systemd-services/)

Jenkins Debian repository:

[https://pkg.jenkins.io/debian-stable/](https://pkg.jenkins.io/debian-stable/)
