# Self-Hosted CI/CD Setup on Ubuntu Server 26.04

## Overview

This guide describes how to build a secure, maintainable, self-hosted CI/CD environment on an Ubuntu Server 26.04 machine running inside a local network.

The recommended architecture is:

```text
Developer Machine
       |
       | git push
       v
+-------------------+
|       Gitea       |
|                   |
| Git Repositories  |
| Pull Requests     |
| Actions           |
+---------+---------+
          |
          | CI/CD
          v
+-------------------+
|   Gitea Runner    |
|                   |
| Build             |
| Test              |
| Docker Build      |
+---------+---------+
          |
          | Docker Image
          v
+-------------------+
| Deployment Server |
|                   |
| Docker            |
| Docker Compose    |
| Nginx             |
+---------+---------+
          |
          +----------------------+
          |          |           |
          v          v           v
      Spring Boot   Node.js     PHP
```

The primary technologies used in this setup are:

| Component | Technology |
|---|---|
| Operating System | Ubuntu Server 26.04 |
| Git Server | Gitea |
| CI/CD | Gitea Actions |
| CI Runner | Gitea Runner / act_runner |
| Container Runtime | Docker |
| Application Management | Docker Compose |
| Reverse Proxy | Nginx |
| Firewall | UFW |
| Authentication | SSH |
| Application Packaging | Docker Images |
| Configuration | Environment Variables |
| Rollback | Versioned Docker Images |

---

# 1. Why This Architecture?

There are many ways to implement CI/CD:

- GitHub Actions
- GitLab CI/CD
- Jenkins
- Gitea Actions
- Git hooks
- systemd
- PM2
- Docker
- Kubernetes

For a home/lab/local-network server, the recommended approach is:

> **Gitea + Gitea Actions + Docker + Docker Compose + Nginx**

This provides a good balance between:

- Security
- Simplicity
- Automation
- Maintainability
- Extensibility
- Support for multiple programming languages

The goal is to avoid installing Java, Node.js, PHP, Maven, Composer, etc. directly on the host whenever possible.

Instead, applications are packaged into Docker images.

---

# 2. Final Architecture

The initial architecture can run everything on one Ubuntu server:

```text
+------------------------------------------------------+
|                  Ubuntu Server 26.04                 |
|                                                      |
|  +-------------+                                     |
|  |    Gitea    |                                     |
|  |             |                                     |
|  | Git Server  |                                     |
|  | Web UI      |                                     |
|  | Actions     |                                     |
|  +------+------+                                     |
|         |                                            |
|         v                                            |
|  +-------------+                                     |
|  | Gitea Runner|                                     |
|  +------+------+                                     |
|         |                                            |
|         v                                            |
|  +-----------------------------------------------+   |
|  |                    Docker                     |   |
|  |                                               |   |
|  |  +---------+  +---------+  +--------------+  |   |
|  |  |  Nginx  |  | Spring  |  | Node.js      |  |   |
|  |  |         |  | Boot    |  | Application  |  |   |
|  |  +---------+  +---------+  +--------------+  |   |
|  |                                               |   |
|  |             +----------------+                |   |
|  |             | PHP / PHP-FPM  |                |   |
|  |             +----------------+                |   |
|  +-----------------------------------------------+   |
|                                                      |
+------------------------------------------------------+
                       |
                       |
                  Local Network
                       |
          +------------+------------+
          |            |            |
        Laptop       Phone       Desktop
```

Later, the CI runner can be moved to a separate machine:

```text
+-------------+       +-------------+       +-------------+
|    Gitea    | ----> | CI Runner   | ----> | Production |
|             |       |             |       | Server      |
| Git Server  |       | Build/Test  |       | Docker      |
+-------------+       +-------------+       | Nginx       |
                                             | Applications|
                                             +-------------+
```

---

# 3. Important Security Consideration

A CI runner can execute arbitrary commands from CI workflows.

If the runner has access to:

```text
/var/run/docker.sock
```

then CI jobs may effectively have powerful control over the Docker host.

Therefore:

- Only run trusted repositories on this runner.
- Do not allow arbitrary users to execute workflows.
- Do not expose the CI runner directly to the Internet.
- Do not use this architecture for untrusted public pull requests.
- Eventually consider putting the CI runner on a separate machine.

For a personal/home/lab environment where you control all repositories, running Gitea, the runner, and applications on the same server is a reasonable starting point.

---

# 4. Prepare Ubuntu Server

## 4.1 Update the System

```bash
sudo apt update
sudo apt full-upgrade -y
```

Reboot:

```bash
sudo reboot
```

Check the Ubuntu version:

```bash
cat /etc/os-release
```

---

# 5. Create an Administrative User

If necessary, create a dedicated administrator:

```bash
sudo adduser deployadmin
```

Add the user to the sudo group:

```bash
sudo usermod -aG sudo deployadmin
```

Switch to the new user:

```bash
su - deployadmin
```

From this point forward, administrative commands should generally use:

```bash
sudo
```

instead of logging in as root.

---

# 6. Configure a Static LAN Address

The server should have a stable IP address.

For example:

```text
192.168.1.50
```

The preferred approach for a home network is usually to create a DHCP reservation in the router.

For example:

```text
Ubuntu Server
MAC Address: XX:XX:XX:XX:XX:XX
Reserved IP: 192.168.1.50
```

This prevents the server's IP address from changing.

---

# 7. Install Basic Packages

Install the basic tools:

```bash
sudo apt install -y \
    git \
    curl \
    wget \
    openssh-server \
    ca-certificates \
    gnupg \
    ufw \
    unzip \
    vim
```

Enable SSH:

```bash
sudo systemctl enable --now ssh
```

Check SSH:

```bash
sudo systemctl status ssh
```

From another computer:

```bash
ssh deployadmin@192.168.1.50
```

---

# 8. Configure UFW Firewall

Assume the local network is:

```text
192.168.1.0/24
```

Set the default firewall policy:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow SSH from the LAN:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
```

Later, allow HTTP:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 80 proto tcp
```

Allow HTTPS:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 443 proto tcp
```

Gitea web interface:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 3000 proto tcp
```

Gitea SSH:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 2222 proto tcp
```

Enable the firewall:

```bash
sudo ufw enable
```

Check:

```bash
sudo ufw status verbose
```

> Make sure SSH is allowed before enabling UFW so that you do not lock yourself out.

---

# 9. Install Docker

Docker should be installed from Docker's official repository.

Install prerequisites:

```bash
sudo apt update
sudo apt install -y ca-certificates curl
```

Create the Docker keyring directory:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

Download Docker's GPG key:

```bash
sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
```

Set permissions:

```bash
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Add Docker's repository:

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

Update package information:

```bash
sudo apt update
```

Install Docker:

```bash
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

Check Docker:

```bash
sudo docker version
```

Check Docker Compose:

```bash
docker compose version
```

Test Docker:

```bash
sudo docker run hello-world
```

---

# 10. Add Your User to the Docker Group

Optionally:

```bash
sudo usermod -aG docker $USER
```

Log out and log back in.

Then:

```bash
docker ps
```

You should no longer need:

```bash
sudo docker ps
```

## Security Warning

Membership in the Docker group effectively provides highly privileged access to the server.

Only add trusted users to this group.

---

# 11. Create the Server Directory Structure

Create the main directories:

```bash
sudo mkdir -p /opt/gitea
sudo mkdir -p /opt/runner
sudo mkdir -p /opt/apps
sudo mkdir -p /opt/infrastructure
sudo mkdir -p /opt/infrastructure/scripts
sudo mkdir -p /opt/infrastructure/nginx
```

The final structure will eventually look like:

```text
/opt/
├── gitea/
│
├── runner/
│
├── apps/
│   ├── spring-demo/
│   ├── node-demo/
│   └── php-demo/
│
└── infrastructure/
    ├── nginx/
    └── scripts/
```

---

# 12. Install Gitea

Gitea will run in Docker.

Go to the Gitea directory:

```bash
cd /opt/gitea
```

Create:

```bash
nano compose.yml
```

Add:

```yaml
services:
  gitea:
    image: docker.gitea.com/gitea:latest
    container_name: gitea
    restart: unless-stopped

    environment:
      USER_UID: 1000
      USER_GID: 1000

    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro

    ports:
      - "3000:3000"
      - "2222:22"
```

Start Gitea:

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

Open the Gitea web interface:

```text
http://192.168.1.50:3000
```

---

# 13. Configure Gitea

During the initial Gitea setup, use:

## Database

For a small home/lab installation:

```text
SQLite3
```

is acceptable.

For a larger installation:

```text
PostgreSQL
```

is recommended.

Start with SQLite unless you have a reason to use PostgreSQL.

## Server Address

Initially:

```text
192.168.1.50
```

## Gitea HTTP Port

```text
3000
```

## Gitea SSH Port

```text
2222
```

---

# 14. Create a Gitea Organization

For example:

```text
home-lab
```

Repositories:

```text
home-lab/
├── spring-demo
├── node-demo
└── php-demo
```

Future repositories might include:

```text
home-lab/
├── spring-demo
├── node-demo
├── php-demo
├── frontend
├── backend
├── infrastructure
└── documentation
```

---

# 15. Configure SSH Authentication

On your development computer:

```bash
ssh-keygen -t ed25519
```

Display the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the public key.

In Gitea:

```text
Settings
→ SSH / GPG Keys
→ Add Key
```

Paste the public key.

Test:

```bash
ssh -p 2222 git@192.168.1.50
```

You should receive a Gitea-related SSH response.

---

# 16. Clone a Repository

A repository can be cloned using:

```bash
git clone ssh://git@192.168.1.50:2222/home-lab/spring-demo.git
```

Or configure SSH aliases to make this cleaner.

For example:

```text
~/.ssh/config
```

```sshconfig
Host gitea
    HostName 192.168.1.50
    Port 2222
    User git
```

Then:

```bash
git clone gitea:home-lab/spring-demo.git
```

---

# 17. Use Separate CI/CD SSH Keys

Do not use your personal SSH private key for CI/CD.

Create a dedicated key:

```bash
ssh-keygen -t ed25519 \
    -f ~/.ssh/gitea_deploy \
    -C "ci-deployment"
```

This produces:

```text
~/.ssh/gitea_deploy
~/.ssh/gitea_deploy.pub
```

The public key can be configured as a deployment key where appropriate.

The private key should never be committed to Git.

---

# 18. Application Directory Structure

Each application should have its own directory.

Example:

```text
/opt/apps/
├── spring-demo/
│   ├── compose.yml
│   ├── .env
│   └── releases/
│
├── node-demo/
│   ├── compose.yml
│   ├── .env
│   └── releases/
│
└── php-demo/
    ├── compose.yml
    ├── .env
    └── releases/
```

---

# 19. Why Docker Should Manage the Applications

Avoid installing these directly on the server unless necessary:

```text
Java
Node.js
PHP
Maven
npm
Composer
PM2
```

Instead:

```text
Git Repository
      |
      v
CI Runner
      |
      v
Docker Build
      |
      v
Docker Image
      |
      v
Production Container
```

This provides:

- Reproducible builds
- Isolated dependencies
- Easier upgrades
- Easier rollback
- Consistent environments
- Support for multiple programming languages

---

# 20. Spring Boot Application

Example repository:

```text
spring-demo/
├── pom.xml
├── mvnw
├── .mvn/
├── src/
└── Dockerfile
```

Example Dockerfile:

```dockerfile
FROM eclipse-temurin:21-jdk AS build

WORKDIR /build

COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

RUN ./mvnw dependency:go-offline

COPY src src

RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=build /build/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

Adjust the Java version according to your application.

---

# 21. Spring Boot Compose Configuration

Create:

```text
/opt/apps/spring-demo/compose.yml
```

```yaml
services:
  app:
    image: registry.home.arpa/home-lab/spring-demo:${APP_VERSION:-latest}

    container_name: spring-demo

    restart: unless-stopped

    env_file:
      - .env

    ports:
      - "127.0.0.1:8081:8080"
```

The application listens internally on:

```text
8080
```

The host exposes it only on:

```text
127.0.0.1:8081
```

Nginx will later proxy requests to it.

---

# 22. Spring Boot Health Check

Configure Spring Boot Actuator in the application.

The desired endpoint is:

```text
/actuator/health
```

The deployment process can test:

```bash
curl --fail http://127.0.0.1:8081/actuator/health
```

A successful response should indicate that the application is healthy.

---

# 23. Node.js Application

Example repository:

```text
node-demo/
├── package.json
├── package-lock.json
├── src/
├── Dockerfile
└── ...
```

Example Dockerfile:

```dockerfile
FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

FROM node:22-alpine

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./

RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/server.js"]
```

Adjust the build/start commands according to your application.

---

# 24. Node.js Compose Configuration

```yaml
services:
  app:
    image: registry.home.arpa/home-lab/node-demo:${APP_VERSION:-latest}

    container_name: node-demo

    restart: unless-stopped

    env_file:
      - .env

    ports:
      - "127.0.0.1:8082:3000"
```

The application internally uses:

```text
3000
```

while the host uses:

```text
127.0.0.1:8082
```

---

# 25. PHP Application

A typical PHP architecture is:

```text
Nginx
  |
  v
PHP-FPM
```

Example Dockerfile:

```dockerfile
FROM php:8.4-fpm-alpine

WORKDIR /var/www/html

COPY . .

RUN docker-php-ext-install \
    pdo \
    pdo_mysql

RUN chown -R www-data:www-data /var/www/html
```

For Laravel, Symfony, WordPress, or another framework, install the extensions required by that framework.

---

# 26. PHP Compose Configuration

```yaml
services:
  php:
    build: .
    container_name: php-demo
    restart: unless-stopped

    volumes:
      - .:/var/www/html

  nginx:
    image: nginx:alpine

    container_name: php-demo-nginx

    restart: unless-stopped

    volumes:
      - .:/var/www/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro

    ports:
      - "127.0.0.1:8083:80"

    depends_on:
      - php
```

---

# 27. Nginx Configuration for PHP

Example:

```nginx
server {
    listen 80;

    root /var/www/html/public;

    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        fastcgi_pass php:9000;
    }
}
```

Adjust the configuration according to the PHP framework being used.

---

# 28. Reverse Proxy Architecture

The preferred architecture is:

```text
LAN
 |
 v
Nginx :80 / :443
 |
 +-------------------+
 |                   |
 v                   v
Spring              Node
:8080               :3000

 |
 v
PHP
```

Applications should not normally be exposed directly to the LAN.

For example:

```yaml
ports:
  - "127.0.0.1:8081:8080"
```

is preferable to:

```yaml
ports:
  - "8081:8080"
```

The first option limits access to the local host.

---

# 29. Nginx Virtual Hosts

Example Spring configuration:

```nginx
server {
    listen 80;

    server_name spring.home.arpa;

    location / {
        proxy_pass http://spring-demo:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Example Node configuration:

```nginx
server {
    listen 80;

    server_name node.home.arpa;

    location / {
        proxy_pass http://node-demo:3000;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

# 30. Local DNS

Eventually configure local DNS names such as:

```text
gitea.home.arpa
spring.home.arpa
node.home.arpa
php.home.arpa
```

Possible solutions include:

- Router DNS
- Pi-hole
- AdGuard Home
- dnsmasq
- Internal DNS server

For example:

```text
spring.home.arpa → 192.168.1.50
node.home.arpa   → 192.168.1.50
php.home.arpa    → 192.168.1.50
gitea.home.arpa  → 192.168.1.50
```

Nginx then decides which application receives the request.

---

# 31. HTTPS

For a purely local environment, HTTP may initially be sufficient:

```text
http://spring.home.arpa
```

For a more advanced setup, use HTTPS:

```text
https://spring.home.arpa
```

For internal-only services, consider an internal Certificate Authority.

Do not assume that a public certificate authority should be used for private-only hostnames.

---

# 32. Environment Variables

Do not commit secrets to Git.

Bad:

```env
DB_PASSWORD=my-secret-password
JWT_SECRET=my-secret
API_KEY=123456
```

inside the repository.

Instead, keep secrets on the deployment server:

```text
/opt/apps/spring-demo/.env
```

Example:

```env
SPRING_PROFILES_ACTIVE=production

DB_HOST=database
DB_NAME=myapp
DB_USER=myapp
DB_PASSWORD=change-me

JWT_SECRET=change-me
```

Add `.env` to `.gitignore`:

```gitignore
.env
```

---

# 33. Protect Environment Files

For example:

```bash
sudo chown root:deployadmin /opt/apps/spring-demo/.env
sudo chmod 640 /opt/apps/spring-demo/.env
```

Never commit:

```text
.env
```

to Git.

Instead commit:

```text
.env.example
```

Example:

```env
SPRING_PROFILES_ACTIVE=production
DB_HOST=
DB_NAME=
DB_USER=
DB_PASSWORD=
JWT_SECRET=
```

---

# 34. Gitea Actions

Create the workflow directory:

```text
.gitea/workflows/
```

Create:

```text
.gitea/workflows/deploy.yml
```

Example:

```yaml
name: Deploy Spring Application

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run tests
        run: |
          ./mvnw test

      - name: Build Docker image
        run: |
          docker build \
            -t spring-demo:${{ gitea.sha }} .

      - name: Deploy
        run: |
          echo "Deploy application here"
```

The exact runner label depends on your Gitea runner configuration.

---

# 35. CI/CD Pipeline

The desired pipeline is:

```text
git push
   |
   v
Checkout
   |
   v
Install Dependencies
   |
   v
Lint
   |
   v
Run Tests
   |
   v
Build Application
   |
   v
Build Docker Image
   |
   v
Tag Image With Git SHA
   |
   v
Push Image To Registry
   |
   v
Deploy
   |
   v
Health Check
   |
   +--------+
   |        |
 SUCCESS   FAILURE
   |        |
   v        v
Finish    Rollback
```

---

# 36. Version Docker Images With Git Commit SHA

Do not rely exclusively on:

```text
latest
```

Instead use:

```text
spring-demo:abc1234
```

where:

```text
abc1234
```

is the Git commit SHA.

For example:

```text
registry.home.arpa/home-lab/spring-demo:abc1234
```

This makes rollback much easier.

---

# 37. Container Registry

A private container registry can be added later.

Example:

```text
registry.home.arpa
```

Images:

```text
registry.home.arpa/home-lab/spring-demo:abc1234
registry.home.arpa/home-lab/node-demo:def5678
registry.home.arpa/home-lab/php-demo:9876543
```

The CI runner builds and pushes the image.

The deployment server pulls the required version.

---

# 38. Deployment Script

Create:

```text
/opt/infrastructure/scripts/deploy-spring.sh
```

Example:

```bash
#!/usr/bin/env bash

set -euo pipefail

APP_DIR="/opt/apps/spring-demo"

cd "$APP_DIR"

echo "Pulling application image..."

docker compose pull

echo "Starting application..."

docker compose up -d --remove-orphans

echo "Waiting for application..."

sleep 10

echo "Running health check..."

curl --fail \
    http://127.0.0.1:8081/actuator/health

echo "Deployment successful."
```

Make it executable:

```bash
chmod +x /opt/infrastructure/scripts/deploy-spring.sh
```

---

# 39. Deployment Safety

A production-oriented deployment should perform:

1. Pull the new image.
2. Start the new container.
3. Wait for startup.
4. Run a health check.
5. Confirm the application is healthy.
6. Mark deployment as successful.
7. Roll back if the health check fails.

Example:

```text
Old Version
    |
    v
Deploy New Version
    |
    v
Health Check
    |
    +--------+
    |        |
   PASS     FAIL
    |        |
    v        v
 Success   Rollback
```

---

# 40. Docker Health Checks

Example Spring Boot health check:

```yaml
services:
  app:
    image: registry.home.arpa/home-lab/spring-demo:${APP_VERSION}

    healthcheck:
      test:
        [
          "CMD",
          "wget",
          "--spider",
          "-q",
          "http://localhost:8080/actuator/health"
        ]

      interval: 10s
      timeout: 5s
      retries: 5
```

For Node.js:

```yaml
healthcheck:
  test:
    [
      "CMD",
      "wget",
      "--spider",
      "-q",
      "http://localhost:3000/health"
    ]

  interval: 10s
  timeout: 5s
  retries: 5
```

Applications should ideally expose a simple health endpoint:

```text
GET /health
```

---

# 41. Rollback Strategy

Suppose:

```text
Version A
abc1111
```

is currently running.

You deploy:

```text
Version B
def2222
```

but Version B fails.

The deployment system should restore:

```text
abc1111
```

The Compose file might use:

```env
APP_VERSION=abc1111
```

Then:

```bash
docker compose pull
docker compose up -d
```

The application returns to the previous version.

---

# 42. Why Versioned Images Are Better Than `git pull`

Avoid:

```text
Production
   |
   v
git pull
   |
   v
npm install
   |
   v
npm build
   |
   v
restart application
```

This can result in:

- Partially updated files
- Different dependency versions
- Difficult rollback
- Host dependency conflicts
- Non-reproducible builds

Instead:

```text
Git
 |
 v
CI
 |
 v
Docker Build
 |
 v
Versioned Image
 |
 v
Production
```

is more reliable.

---

# 43. systemd

systemd should primarily manage host-level services.

For example:

```text
systemd
   |
   v
Docker
   |
   v
Docker Compose
   |
   v
Applications
```

Docker containers can use:

```yaml
restart: unless-stopped
```

For example:

```yaml
services:
  app:
    restart: unless-stopped
```

After a server reboot:

```text
Ubuntu boots
    |
    v
Docker starts
    |
    v
Containers start
    |
    v
Nginx starts
    |
    v
Applications start
```

There is normally no need to create a separate systemd service for every application.

---

# 44. Why Not PM2?

PM2 is useful for Node.js applications.

However, if all applications are containerized:

```text
Node.js
Spring Boot
PHP
```

can all be managed using the same operational model:

```bash
docker compose up -d
docker compose down
docker compose restart
docker compose logs
```

This makes the infrastructure more consistent.

---

# 45. Application Logs

Docker logs:

```bash
docker logs spring-demo
```

Follow logs:

```bash
docker logs -f spring-demo
```

Compose logs:

```bash
docker compose logs -f
```

Last 100 lines:

```bash
docker compose logs --tail=100
```

Check running containers:

```bash
docker ps
```

Check resource usage:

```bash
docker stats
```

Host service logs:

```bash
journalctl -u docker
```

SSH logs:

```bash
journalctl -u ssh
```

---

# 46. Configure Docker Log Rotation

Create or edit:

```text
/etc/docker/daemon.json
```

Example:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
```

Restart Docker:

```bash
sudo systemctl restart docker
```

This prevents container logs from consuming unlimited disk space.

---

# 47. Backups

Backups are extremely important.

Back up:

```text
Gitea repositories
Gitea database
Gitea configuration
Application databases
Persistent application data
Environment/secrets
Important infrastructure configuration
```

Do not waste backup space on reproducible files such as:

```text
node_modules/
target/
build/
Docker build cache
Docker images
temporary logs
```

A good home-lab backup strategy is:

```text
Ubuntu Server
      |
      v
External Disk / NAS
      |
      v
Off-site Backup
```

---

# 48. Automatic Security Updates

Install:

```bash
sudo apt install -y unattended-upgrades
```

Configure automatic security updates appropriately.

Keep the Ubuntu host and Docker installation updated.

---

# 49. Docker and UFW

Be aware that Docker-published ports can interact with firewall rules in ways that may bypass normal UFW expectations.

Therefore, avoid exposing application ports directly whenever possible.

Prefer:

```yaml
ports:
  - "127.0.0.1:8081:8080"
```

instead of:

```yaml
ports:
  - "8081:8080"
```

Architecture:

```text
LAN
 |
 v
Nginx :80/:443
 |
 +---- Spring
 |
 +---- Node
 |
 +---- PHP
```

Only Nginx needs to be exposed to the LAN for normal web traffic.

---

# 50. Recommended Network Ports

Example:

| Port | Service | Access |
|---:|---|---|
| 22 | Ubuntu SSH | LAN |
| 80 | Nginx HTTP | LAN |
| 443 | Nginx HTTPS | LAN |
| 3000 | Gitea Web | LAN |
| 2222 | Gitea SSH | LAN |
| 8081 | Spring | Localhost only |
| 8082 | Node | Localhost only |
| 8083 | PHP | Localhost only |

Applications should normally remain inaccessible directly from the LAN.

---

# 51. Do Not Expose the Server Directly to the Internet

For the initial setup:

```text
Internet
   X
   |
Router
   |
   v
Ubuntu Server
   |
   v
LAN
```

Do not configure router port forwarding for:

```text
22
2222
3000
8081
8082
8083
```

If remote access is eventually required, consider using a VPN such as WireGuard instead of exposing administrative services directly.

---

# 52. Branch Strategy

Keep Git simple.

Use:

```text
main
```

as the production branch.

Feature development:

```text
feature/login
feature/payment
feature/api
```

Merge into:

```text
main
```

Deployment can then automatically occur when code is pushed to `main`.

Example:

```text
feature/login
      |
      v
Pull Request
      |
      v
Tests
      |
      v
Merge
      |
      v
main
      |
      v
Production Deployment
```

---

# 53. CI and CD

CI means:

```text
Continuous Integration
```

It answers:

> Does the code build and pass its tests?

CD means:

```text
Continuous Deployment
```

It answers:

> Should this version be deployed?

A complete workflow is:

```text
git push
    |
    v
Checkout
    |
    v
Dependencies
    |
    v
Lint
    |
    v
Tests
    |
    v
Build
    |
    v
Docker Image
    |
    v
Registry
    |
    v
Deployment
    |
    v
Health Check
    |
    v
Application Running
```

---

# 54. Gitea Runner

Install/register a Gitea Actions runner.

The runner connects to Gitea:

```text
Gitea
   |
   | workflow
   v
Gitea Runner
```

The runner executes:

```text
Checkout
Test
Build
Docker Build
Deploy
```

The runner should be registered at the repository, organization, or instance level depending on your requirements.

For a small personal installation, an organization-level runner can be a convenient option.

---

# 55. Runner Security Rules

The runner should:

- Run only trusted repositories.
- Not be exposed to the Internet.
- Use dedicated credentials.
- Avoid storing unnecessary secrets.
- Have minimal access to deployment resources.
- Be moved to a separate server when the environment becomes more important.

Do not run arbitrary untrusted workflows on a runner that has access to your production Docker host.

---

# 56. Future Production Architecture

When the system grows, use three logical components:

```text
                 +-------------+
                 |    Gitea    |
                 +------+------+
                        |
                        v
                 +-------------+
                 | CI Runner   |
                 |             |
                 | Build/Test  |
                 +------+------+
                        |
                        v
                 +-------------+
                 |   Registry  |
                 +------+------+
                        |
                        v
                 +-------------+
                 | Deployment  |
                 | Server      |
                 |             |
                 | Nginx       |
                 | Applications|
                 +-------------+
```

This separates:

- Source control
- CI
- Production

and provides a stronger security boundary.

---

# 57. Monitoring

Initially, the following commands are sufficient:

```bash
docker ps
docker stats
docker compose logs
df -h
free -h
uptime
```

Later, add:

```text
Prometheus
Grafana
```

for:

- CPU
- RAM
- Disk
- Container health
- HTTP metrics
- Application metrics
- Spring Boot metrics

Do not install a complete monitoring stack on day one unless you actually need it.

---

# 58. What Not to Install Initially

Avoid installing all of these immediately:

```text
Jenkins
GitLab
Kubernetes
Helm
ArgoCD
Prometheus
Grafana
Loki
Vault
Harbor
Terraform
Ansible
Traefik
```

They can all be useful, but they add complexity.

Start with:

```text
Ubuntu
Docker
Gitea
Gitea Runner
Docker Compose
Nginx
UFW
```

Then add components only when a real requirement appears.

---

# 59. Recommended Technology Stack

The final recommended stack is:

| Layer | Technology |
|---|---|
| OS | Ubuntu Server 26.04 |
| SSH | OpenSSH |
| Firewall | UFW |
| Git | Gitea |
| CI/CD | Gitea Actions |
| Runner | Gitea Runner |
| Containers | Docker |
| Orchestration | Docker Compose |
| Reverse Proxy | Nginx |
| Java | Docker |
| Node.js | Docker |
| PHP | Docker + PHP-FPM |
| Configuration | `.env` |
| Secrets | Gitea Secrets + Server-side Secrets |
| Logs | Docker Logs |
| Health Checks | Docker Healthcheck |
| Deployment | Versioned Docker Images |
| Rollback | Previous Image Version |
| DNS | Local DNS |
| HTTPS | Internal CA |
| Monitoring | Prometheus/Grafana later |

---

# 60. Complete End-to-End Example

Suppose you have a Spring Boot project:

```text
spring-demo
```

You make a change:

```bash
git add .
git commit -m "Add user profile API"
git push origin main
```

The complete process is:

```text
Developer
    |
    | git push
    v
Gitea
    |
    | Push event
    v
Gitea Actions
    |
    v
CI Runner
    |
    +--> Checkout source
    |
    +--> Install dependencies
    |
    +--> Run tests
    |
    +--> Build application
    |
    +--> Build Docker image
    |
    +--> Tag image:
    |       spring-demo:abc1234
    |
    +--> Push image to registry
    |
    v
Deployment Server
    |
    +--> Pull image
    |
    +--> Stop/replace old container
    |
    +--> Start new container
    |
    +--> Health check
    |
    v
Application Running
    |
    v
Nginx
    |
    v
spring.home.arpa
    |
    v
Laptop / Phone / Desktop
```

If the health check succeeds:

```text
Deployment SUCCESS
```

If the health check fails:

```text
Deployment FAILED
       |
       v
Rollback
       |
       v
Previous Version
```

---

# 61. Example Final Server Layout

The finished server could look like:

```text
/opt/
│
├── gitea/
│   ├── compose.yml
│   └── data/
│
├── runner/
│   ├── compose.yml
│   └── data/
│
├── apps/
│   │
│   ├── spring-demo/
│   │   ├── compose.yml
│   │   ├── .env
│   │   └── releases/
│   │
│   ├── node-demo/
│   │   ├── compose.yml
│   │   ├── .env
│   │   └── releases/
│   │
│   └── php-demo/
│       ├── compose.yml
│       ├── .env
│       └── releases/
│
└── infrastructure/
    │
    ├── nginx/
    │   ├── compose.yml
    │   └── conf.d/
    │
    └── scripts/
        ├── deploy-spring.sh
        ├── deploy-node.sh
        └── deploy-php.sh
```

---

# 62. Recommended Implementation Order

Implement the system in this order.

## Phase 1 - Ubuntu

- [ ] Update Ubuntu
- [ ] Create administrative user
- [ ] Configure stable LAN IP
- [ ] Install SSH
- [ ] Configure UFW

## Phase 2 - Docker

- [ ] Install Docker
- [ ] Install Docker Compose plugin
- [ ] Test Docker
- [ ] Configure Docker logging

## Phase 3 - Gitea

- [ ] Install Gitea
- [ ] Create administrator
- [ ] Create organization
- [ ] Create repository
- [ ] Configure SSH authentication

## Phase 4 - Applications

- [ ] Create Spring Boot Docker image
- [ ] Create Node.js Docker image
- [ ] Create PHP Docker image
- [ ] Create Docker Compose configurations

## Phase 5 - Nginx

- [ ] Install Nginx
- [ ] Configure reverse proxy
- [ ] Configure application hostnames
- [ ] Configure local DNS

## Phase 6 - CI/CD

- [ ] Install Gitea Runner
- [ ] Register runner
- [ ] Create workflow
- [ ] Run tests
- [ ] Build Docker image
- [ ] Push Docker image
- [ ] Deploy automatically

## Phase 7 - Reliability

- [ ] Add health checks
- [ ] Add deployment validation
- [ ] Add rollback
- [ ] Configure log rotation
- [ ] Configure backups
- [ ] Configure automatic security updates

## Phase 8 - Advanced

- [ ] Private container registry
- [ ] HTTPS
- [ ] Internal Certificate Authority
- [ ] Monitoring
- [ ] Separate CI runner
- [ ] Separate production server

---

# 63. Final Recommendation

For this home/lab environment, use:

```text
Ubuntu Server 26.04
        +
      Docker
        +
      Gitea
        +
   Gitea Actions
        +
   Gitea Runner
        +
  Docker Compose
        +
      Nginx
```

The most important design principle is:

```text
DO NOT:

Git
 |
 v
Production
 |
 v
git pull
 |
 v
restart
```

Instead use:

```text
Git
 |
 v
Gitea
 |
 v
CI
 |
 +--> Test
 |
 +--> Build
 |
 +--> Docker Image
 |
 v
Versioned Artifact
 |
 v
Deployment
 |
 v
Health Check
 |
 +------+
 |      |
PASS   FAIL
 |      |
 v      v
Live  Rollback
```

