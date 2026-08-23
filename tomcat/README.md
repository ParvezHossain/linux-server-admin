# Comprehensive Guide: Developing & Deploying Spring Applications on Ubuntu + Apache Tomcat

> A practical reference for setting up Apache Tomcat as a dedicated system service, deploying a Spring WAR application, automating development deployments, debugging startup issues, and monitoring application health.

<!--
===============================================================================
TABLE OF CONTENTS
===============================================================================
1. Prerequisites & System Setup
2. Tomcat Installation & Dedicated System User
3. systemd Service Configuration
4. Tomcat Port Configuration & Permissions
5. Automated Development Workflow
6. Debugging & Troubleshooting
7. Server & Application Monitoring
8. Useful Operational Commands
   

---

## 1. Prerequisites & System Setup

This guide assumes:

* Ubuntu Server
* OpenJDK 25 (Java 17/21+ can also be used)
* Maven
* Git
* Apache Tomcat 10.1.x
* A Spring application packaged as a **WAR**
* `systemd` for Tomcat process management

### Verify Java

```bash
# Display the installed Java version.
# Confirm that Java is installed and that the expected JDK version is active.
java --version
```

### Install Maven and Git

```bash
# Refresh Ubuntu's package index so apt knows about the latest available packages.
sudo apt update

# Install Maven for building the Spring application and Git for source-code management.
sudo apt install maven git -y

# Verify Maven installation.
mvn --version

# Verify Git installation.
git --version
```

> **Note:** A Spring application running on Tomcat requires a compatible Java runtime. The Java version configured in `JAVA_HOME` should match the JDK used to build the application.

---

# 2. Tomcat Installation & Dedicated System User

Tomcat should **not** run as `root`.

A dedicated system account provides process isolation and limits the damage that could occur if the Tomcat process or deployed application were compromised.

## 2.1 Create a Dedicated Tomcat User

```bash
# Create a system user:
# -r            = create a system account
# -m            = create the user's home directory
# -U            = create a group with the same name
# -d            = use /opt/tomcat as the home directory
# -s            = prevent interactive shell login
sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat
```

Verify the account:

```bash
# Confirm that the tomcat user exists and inspect its account information.
id tomcat
```

---

## 2.2 Download Apache Tomcat

> **Version note:** The version below is an example. Before production use, select a currently supported Tomcat release and verify its compatibility with your application and Java version.

```bash
# Move to a temporary directory so the downloaded installation archive
# does not remain in the application or Tomcat directories.
cd /tmp/

# Download the selected Apache Tomcat 10.1.x release.
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.59/bin/apache-tomcat-10.1.59.tar.gz
```

Verify the archive exists:

```bash
# List the downloaded Tomcat archive and verify that it is available locally.
ls -lh apache-tomcat-10.1.59.tar.gz
```

For production environments, consider verifying the downloaded archive against Apache's published checksum or signature before installation.

---

## 2.3 Extract Tomcat

```bash
# Create the Tomcat installation directory if it does not already exist.
sudo mkdir -p /opt/tomcat

# Extract Tomcat directly into /opt/tomcat.
# --strip-components=1 removes the top-level apache-tomcat-* directory
# from the archive so the Tomcat files are placed directly under /opt/tomcat.
sudo tar xzvf apache-tomcat-10.1.59.tar.gz \
    -C /opt/tomcat \
    --strip-components=1
```

---

## 2.4 Secure Tomcat Ownership and Permissions

```bash
# Make the dedicated tomcat account the owner of the complete Tomcat installation.
# This allows Tomcat to read its configuration and write to directories such as
# logs, temp, work, and webapps when required.
sudo chown -R tomcat:tomcat /opt/tomcat

# Make Tomcat's shell scripts executable.
# The -R option applies the permission recursively to everything under bin/.
sudo chmod -R u+x /opt/tomcat/bin
```

Verify:

```bash
# Display the ownership and permissions of the Tomcat installation.
sudo ls -ld /opt/tomcat
sudo ls -l /opt/tomcat/bin/
```

---

# 3. systemd Service Configuration

Using `systemd` provides:

* Background execution
* Automatic startup after reboot
* Centralized service management
* Automatic restart configuration
* Standardized logging and status inspection

## 3.1 Create the Tomcat Service

```bash
# Create a dedicated systemd unit for Tomcat.
sudo nano /etc/systemd/system/tomcat.service
```

Use the following configuration:

```ini
[Unit]
# Human-readable name shown by systemctl.
Description=Apache Tomcat Web Application Container

# Start Tomcat after the basic network stack is available.
After=network.target


[Service]
# Tomcat's startup.sh starts Tomcat as a background process,
# so systemd treats the service as a forking process.
Type=forking

# Never run Tomcat as root.
# The dedicated account limits the privileges of the application server.
User=tomcat
Group=tomcat

# Java installation used by Tomcat.
# Verify this path with:
#   readlink -f "$(which java)"
# or:
#   update-alternatives --config java
Environment="JAVA_HOME=/usr/lib/jvm/default-java"

# PID file used by Tomcat/systemd to track the running process.
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"

# CATALINA_HOME identifies the Tomcat installation.
Environment="CATALINA_HOME=/opt/tomcat"

# CATALINA_BASE identifies the runtime instance.
# Keeping HOME and BASE identical is appropriate for a single-instance setup.
Environment="CATALINA_BASE=/opt/tomcat"

# JVM tuning:
# -Xms512M          = initial Java heap size
# -Xmx1024M         = maximum Java heap size
# -server           = use the server JVM configuration
# -XX:+UseG1GC      = enable the G1 garbage collector
#
# Adjust heap values according to the server's available memory and
# the application's actual workload.
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseG1GC"

# Command used to start Tomcat.
ExecStart=/opt/tomcat/bin/startup.sh

# Command used to gracefully stop Tomcat.
ExecStop=/opt/tomcat/bin/shutdown.sh

# Wait 10 seconds before attempting a restart.
RestartSec=10

# Automatically restart Tomcat if the service exits unexpectedly.
Restart=always


[Install]
# Start Tomcat as part of the normal multi-user boot target.
WantedBy=multi-user.target
```

> **Production note:** JVM memory values should not be copied blindly. `-Xmx1024M` means the JVM can use up to approximately 1 GB of Java heap, in addition to memory used outside the heap.

---

## 3.2 Reload systemd

```bash
# Tell systemd to discover the newly created or modified service unit.
sudo systemctl daemon-reload
```

---

## 3.3 Start Tomcat

```bash
# Start Tomcat immediately without rebooting the server.
sudo systemctl start tomcat
```

Check its status:

```bash
# Display the current Tomcat service state and recent service messages.
sudo systemctl status tomcat
```

---

## 3.4 Enable Tomcat at Boot

```bash
# Configure systemd to automatically start Tomcat after the server boots.
sudo systemctl enable tomcat
```

Verify:

```bash
# Confirm that the service is enabled for automatic startup.
sudo systemctl is-enabled tomcat
```

---

## 3.5 Common systemd Commands

```bash
# Start Tomcat.
sudo systemctl start tomcat

# Stop Tomcat gracefully.
sudo systemctl stop tomcat

# Restart Tomcat after configuration or application changes.
sudo systemctl restart tomcat

# Reload systemd unit definitions after modifying tomcat.service.
sudo systemctl daemon-reload

# Display detailed service status.
sudo systemctl status tomcat

# Show Tomcat's recent systemd journal entries.
sudo journalctl -u tomcat -n 100 --no-pager

# Follow Tomcat's systemd logs in real time.
sudo journalctl -u tomcat -f
```

---

# 4. Tomcat Port Configuration & Permissions

## 4.1 Change Tomcat's HTTP Port

Tomcat normally listens on port `8080`.

For this example, we will change it to `8090`.

Open:

```bash
# Edit Tomcat's primary server configuration file.
sudo nano /opt/tomcat/conf/server.xml
```

Locate the HTTP Connector and configure it similar to:

```xml
<!--
    HTTP connector used by the Spring application.

    port="8090"
        Makes Tomcat listen for HTTP traffic on TCP port 8090.

    connectionTimeout="20000"
        Closes an idle connection after 20 seconds.

    redirectPort="8443"
        Port Tomcat can use when redirecting HTTP requests to HTTPS.
-->
<Connector
    port="8090"
    protocol="HTTP/1.1"
    connectionTimeout="20000"
    redirectPort="8443" />
```

Restart Tomcat:

```bash
# Restart Tomcat so the modified server.xml configuration is loaded.
sudo systemctl restart tomcat
```

Verify the port:

```bash
# Confirm that a process is listening on TCP port 8090.
sudo ss -tuln | grep 8090
```

---

## 4.2 Configure UFW

Only open the port if external access is actually required.

```bash
# Allow inbound TCP connections to Tomcat's HTTP port.
sudo ufw allow 8090/tcp

# Reload UFW so the new firewall rule becomes active.
sudo ufw reload

# Display the active firewall rules.
sudo ufw status
```

### Security Recommendation

For a production deployment, consider placing Tomcat behind a reverse proxy such as Nginx or Apache HTTP Server.

In that architecture:

```text
Internet
   |
   v
HTTPS :443
   |
   v
Reverse Proxy
   |
   v
Tomcat :8090
   |
   v
Spring Application
```

This allows public traffic to use HTTPS while Tomcat remains bound to an internal interface or protected network.

---

# 5. Tomcat File & Directory Permissions

Tomcat needs appropriate access to its runtime directories.

If permission errors occur, inspect ownership first:

```bash
# Check ownership and permissions of the main Tomcat runtime directories.
sudo ls -ld \
    /opt/tomcat/conf \
    /opt/tomcat/logs \
    /opt/tomcat/temp \
    /opt/tomcat/work \
    /opt/tomcat/webapps
```

If ownership was accidentally changed, restore it:

```bash
# Restore Tomcat ownership to the directories used for configuration,
# deployed applications, logs, temporary files, and generated work files.
sudo chown -R tomcat:tomcat \
    /opt/tomcat/conf \
    /opt/tomcat/webapps \
    /opt/tomcat/logs \
    /opt/tomcat/temp \
    /opt/tomcat/work
```

> **Important:** Avoid blindly applying broad write permissions such as `chmod -R 777`. Correct ownership and the minimum required permissions are safer.

---

# 6. Spring Application Deployment

A Spring application deployed to external Tomcat should generally be packaged as a **WAR** rather than an executable JAR.

Your project should look approximately like:

```text
spring-project/
├── pom.xml
├── deploy.sh
└── src/
    ├── main/
    │   ├── java/
    │   ├── resources/
    │   └── webapp/
    └── test/
```

The Maven build should produce:

```text
target/
└── ROOT.war
```

If the WAR is named:

```text
myapp.war
```

Tomcat normally exposes it under:

```text
http://server:8090/myapp/
```

If the WAR is named:

```text
ROOT.war
```

the application is deployed at the root context:

```text
http://server:8090/
```

---

# 7. Automated Development Workflow

Repeatedly running Maven, copying the WAR, changing permissions, and checking logs is inefficient during development.

A small deployment script can automate the routine workflow.

Create the script beside `pom.xml`:

```bash
# Create the deployment automation script in the Spring project root.
nano deploy.sh
```

Use:

```bash
#!/bin/bash

# ==============================================================================
# Script Name: deploy.sh
#
# Purpose:
#   Build the Spring application, deploy the generated WAR to Tomcat,
#   fix deployment ownership, and stream the Tomcat log.
#
# Expected project layout:
#   project/
#   ├── pom.xml
#   ├── deploy.sh
#   └── target/
#
# Expected WAR:
#   target/ROOT.war
# ==============================================================================

# Exit immediately when a command fails.
# This prevents the script from continuing with a broken deployment.
set -e

echo "=========================================="
echo "[1/3] Building Spring Application"
echo "=========================================="

# Remove previous build artifacts and create a fresh WAR package.
# The -q flag is intentionally not used so build errors remain visible.
mvn clean package

echo "=========================================="
echo "[2/3] Deploying WAR to Tomcat"
echo "=========================================="

# Verify that the expected WAR file was actually produced.
# This provides a clearer error than a failed cp command.
if [ ! -f "target/ROOT.war" ]; then
    echo "ERROR: target/ROOT.war was not created."
    exit 1
fi

# Copy the freshly built WAR into Tomcat's deployment directory.
# ROOT.war maps the application to the root context (/).
sudo cp target/ROOT.war /opt/tomcat/webapps/

# Ensure Tomcat owns the deployed application archive.
sudo chown tomcat:tomcat /opt/tomcat/webapps/ROOT.war

echo "=========================================="
echo "[3/3] Deployment Complete"
echo "=========================================="

# Display the latest Tomcat messages and continue following new log entries.
# This is useful for immediately detecting Spring startup exceptions.
sudo tail -n 50 -f /opt/tomcat/logs/catalina.out
```

Make it executable:

```bash
# Add execute permission so the script can be launched directly.
chmod +x deploy.sh
```

Run it:

```bash
# Build, deploy, and follow Tomcat logs using one command.
./deploy.sh
```

---

## 7.1 Improved Deployment Script With Tomcat Restart

For environments where automatic WAR redeployment is unreliable or where you want deterministic restarts, use:

```bash
#!/bin/bash

# ==============================================================================
# Script Name: deploy.sh
# Purpose: Build the Spring WAR and perform a controlled Tomcat deployment.
# ==============================================================================

# Stop execution when a command fails.
set -e

echo "=========================================="
echo "[1/4] Building Application"
echo "=========================================="

# Clean previous Maven artifacts and create a new WAR.
mvn clean package

# Stop immediately if the expected WAR was not generated.
if [ ! -f "target/ROOT.war" ]; then
    echo "ERROR: target/ROOT.war does not exist."
    exit 1
fi

echo "=========================================="
echo "[2/4] Stopping Tomcat"
echo "=========================================="

# Stop Tomcat before replacing the deployed WAR.
sudo systemctl stop tomcat

echo "=========================================="
echo "[3/4] Installing WAR"
echo "=========================================="

# Copy the freshly built application archive into Tomcat.
sudo cp target/ROOT.war /opt/tomcat/webapps/ROOT.war

# Give Tomcat ownership of the WAR file.
sudo chown tomcat:tomcat /opt/tomcat/webapps/ROOT.war

echo "=========================================="
echo "[4/4] Starting Tomcat"
echo "=========================================="

# Start Tomcat with the newly deployed application.
sudo systemctl start tomcat

# Show the current service state.
sudo systemctl status tomcat --no-pager

echo "=========================================="
echo "Deployment completed successfully."
echo "=========================================="

# Follow the Tomcat application/server log.
sudo tail -n 50 -f /opt/tomcat/logs/catalina.out
```

### Which version should you use?

| Approach                    | Best for                          |
| --------------------------- | --------------------------------- |
| WAR copy only               | Fast development                  |
| Stop → copy → start         | Predictable deployments           |
| CI/CD pipeline              | Staging/production                |
| Docker/container deployment | Modern containerized environments |

---

# 8. Debugging & Troubleshooting Spring on Tomcat

## 8.1 Follow Tomcat Logs

```bash
# Follow catalina.out in real time.
# Useful when watching Spring's startup sequence or diagnosing runtime errors.
sudo tail -f /opt/tomcat/logs/catalina.out
```

Show recent entries:

```bash
# Display the last 100 lines without continuously following the file.
sudo tail -n 100 /opt/tomcat/logs/catalina.out
```

Search for common failures:

```bash
# Search the Tomcat log for exceptions and common application failures.
sudo grep -Ei "exception|error|failed|severe" /opt/tomcat/logs/catalina.out
```

---

## 8.2 Inspect the Deployed Application

When Tomcat deploys:

```text
ROOT.war
   |
   v
ROOT/
└── WEB-INF/
    └── classes/
```

Inspect compiled classes:

```bash
# Confirm that the deployed application contains compiled Java classes.
sudo ls -lah /opt/tomcat/webapps/ROOT/WEB-INF/classes/
```

Inspect the deployed application:

```bash
# Display the top-level contents of the expanded ROOT application.
sudo find /opt/tomcat/webapps/ROOT -maxdepth 2 -type f | head -50
```

---

## 8.3 Common 404 Problem

A `404` response does not necessarily mean Tomcat is down.

Check:

```bash
# Verify that Tomcat is running.
sudo systemctl status tomcat

# Verify that Tomcat is listening on the expected HTTP port.
sudo ss -tuln | grep 8090

# Check whether the application was expanded.
sudo ls -lah /opt/tomcat/webapps/

# Inspect the latest deployment/startup errors.
sudo tail -n 200 /opt/tomcat/logs/catalina.out
```

Also verify the URL.

For `ROOT.war`:

```text
http://SERVER_IP:8090/
```

For `myapp.war`:

```text
http://SERVER_IP:8090/myapp/
```

---

# 9. Remote JPDA Debugging

Remote debugging is useful during development when an IDE such as IntelliJ IDEA or Eclipse needs to attach to the JVM running on the Ubuntu server.

> **Security warning:** Never expose a JPDA/debug port publicly. Restrict it with a firewall/security group or use an SSH tunnel.

Configure JPDA:

```bash
# Configure the TCP port used by the Java debugger.
export JPDA_ADDRESS="8000"

# Use Java's socket-based debugging transport.
export JPDA_TRANSPORT="dt_socket"
```

Start Tomcat in JPDA mode:

```bash
# Start Tomcat with the Java Platform Debugger Architecture enabled.
sudo /opt/tomcat/bin/catalina.sh jpda start
```

Verify the debug port:

```bash
# Confirm that the JVM is listening for debugger connections on port 8000.
sudo ss -tuln | grep 8000
```

### Safer Remote Debugging

Instead of exposing port `8000` to the Internet, create an SSH tunnel from your development machine:

```bash
# Forward local port 8000 to the remote Tomcat server's port 8000.
# This keeps the debugger port inaccessible from the public network.
ssh -L 8000:localhost:8000 user@SERVER_IP
```

Your IDE can then connect to:

```text
localhost:8000
```

---

# 10. Server Health & Application Monitoring

## 10.1 Check the Tomcat Process

```bash
# Search the process list for Tomcat-related processes.
ps aux | grep '[t]omcat'
```

Monitor the Tomcat user's processes:

```bash
# Display CPU and memory usage for processes owned by the tomcat user.
top -u tomcat
```

---

## 10.2 Check Port Binding

```bash
# Verify that Tomcat is listening on TCP port 8090.
sudo ss -tuln | grep 8090
```

A successful result should contain a listening socket similar to:

```text
LISTEN 0 100 0.0.0.0:8090 0.0.0.0:*
```

---

## 10.3 HTTP Health Check

```bash
# Send an HTTP HEAD request to verify that the application responds.
# Replace /hello with an endpoint that actually exists in your application.
curl -I http://localhost:8090/hello
```

For a normal GET request:

```bash
# Request the endpoint and print the HTTP response body.
curl http://localhost:8090/hello
```

For verbose troubleshooting:

```bash
# Display request/response details including connection and HTTP headers.
curl -v http://localhost:8090/hello
```

---

# 11. Recommended Spring Actuator Health Check

If Spring Boot Actuator is enabled, a dedicated health endpoint is preferable to testing an arbitrary application endpoint.

For example:

```text
http://localhost:8090/actuator/health
```

Test it with:

```bash
# Query Spring Boot Actuator's health endpoint.
# A healthy application normally responds with HTTP 200.
curl -i http://localhost:8090/actuator/health
```

A typical response may look like:

```json
{
  "status": "UP"
}
```

> **Production note:** Do not expose sensitive Actuator endpoints publicly without appropriate authentication and authorization.

---

# 12. Useful One-Line Diagnostics

## Check Java

```bash
# Verify the active Java runtime.
java --version
```

## Check Maven

```bash
# Verify Maven and the Java runtime Maven is using.
mvn --version
```

## Check Tomcat

```bash
# Display Tomcat service state.
sudo systemctl status tomcat --no-pager
```

## Check Tomcat Logs

```bash
# Follow the latest Tomcat log output.
sudo tail -f /opt/tomcat/logs/catalina.out
```

## Check Listening Ports

```bash
# Display all TCP/UDP listening sockets.
sudo ss -tuln
```

## Check Only Port 8090

```bash
# Verify whether Tomcat is listening on port 8090.
sudo ss -tuln | grep ':8090'
```

## Check the Deployed WAR

```bash
# Verify that the expected ROOT WAR exists and inspect its ownership.
sudo ls -lh /opt/tomcat/webapps/ROOT.war
```

## Check Expanded Deployment

```bash
# Confirm that Tomcat has expanded ROOT.war.
sudo ls -ld /opt/tomcat/webapps/ROOT
```

---

# 13. Recommended Deployment Architecture

For a production-style deployment, a typical architecture is:

```text
                       Internet
                           |
                           | HTTPS :443
                           v
                  +-------------------+
                  | Reverse Proxy     |
                  | Nginx / Apache    |
                  +-------------------+
                           |
                           | HTTP
                           v
                  +-------------------+
                  | Apache Tomcat    |
                  | :8090            |
                  +-------------------+
                           |
                           v
                  +-------------------+
                  | Spring Application|
                  | ROOT.war          |
                  +-------------------+
                           |
                           v
                  +-------------------+
                  | Database / Redis  |
                  +-------------------+
```

### Why this architecture?

* HTTPS termination can happen at the reverse proxy.
* Tomcat does not need to be directly exposed to the Internet.
* The public application can use standard ports `80/443`.
* Reverse-proxy rules can provide routing and additional security controls.
* Tomcat remains responsible for running the Java application.

---

# 14. Production Checklist

Before considering the deployment production-ready, verify:

* [ ] Tomcat does not run as `root`.
* [ ] Java version is compatible with the application and Tomcat.
* [ ] Tomcat is managed by `systemd`.
* [ ] Tomcat starts automatically after reboot.
* [ ] The application is packaged as a WAR when external Tomcat deployment is intended.
* [ ] `ROOT.war` ownership belongs to the Tomcat service account.
* [ ] Firewall rules expose only the required ports.
* [ ] Tomcat's management/debug ports are not publicly exposed.
* [ ] JPDA debugging is disabled outside development.
* [ ] HTTPS is enabled for public traffic.
* [ ] Tomcat is preferably behind a reverse proxy.
* [ ] Application health checks are available.
* [ ] Logs are monitored and rotated appropriately.
* [ ] JVM heap values are sized according to available server memory.
* [ ] Database credentials and secrets are not committed to Git.
* [ ] Production configuration is separated from development configuration.
* [ ] Automated CI/CD is considered instead of manually copying WAR files.

---

# 15. Final Development Workflow

Once the server has been configured, the day-to-day development workflow can be reduced to:

```bash
# 1. Modify your Spring source code.
# 2. Save your changes.
# 3. Build and deploy the application.
./deploy.sh
```

The script then:

```text
Source Code
    |
    v
Maven Clean
    |
    v
Maven Package
    |
    v
target/ROOT.war
    |
    v
/opt/tomcat/webapps/ROOT.war
    |
    v
Tomcat
    |
    v
Spring Application
    |
    v
HTTP :8090
```

For troubleshooting:

```bash
# Check the service.
sudo systemctl status tomcat

# Follow the application/server logs.
sudo tail -f /opt/tomcat/logs/catalina.out

# Verify that Tomcat is listening.
sudo ss -tuln | grep 8090

# Test the application.
curl -i http://localhost:8090/
```

---

## Summary

This setup provides a clean foundation for running a Spring application on Ubuntu with Apache Tomcat:

1. **Dedicated Linux user** — isolates Tomcat from other system processes.
2. **systemd service** — manages startup, shutdown, restarts, and boot-time execution.
3. **Explicit JVM configuration** — provides predictable memory and garbage-collection settings.
4. **Controlled permissions** — prevents unnecessary filesystem access.
5. **Automated deployment script** — reduces repetitive development deployment work.
6. **Centralized troubleshooting commands** — makes startup and runtime failures easier to diagnose.
7. **Health monitoring** — verifies both the Tomcat process and HTTP application availability.
8. **Reverse-proxy architecture** — provides a stronger foundation for production deployments.

> **Disclaimer:** Commands and version numbers in this README are examples. Validate Java/Tomcat compatibility, security settings, firewall rules, JVM sizing, and Apache Tomcat release versions before using the configuration in production.
