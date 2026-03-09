# Developer Documentation - Inception

This documentation is intended for developers who need to set up, modify, or maintain the Inception infrastructure.

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Project Architecture](#project-architecture)
3. [Building and Launching](#building-and-launching)
4. [Container Management](#container-management)
5. [Volume Management](#volume-management)
6. [Network Configuration](#network-configuration)
7. [Configuration Files](#configuration-files)
8. [Development Workflow](#development-workflow)
9. [Testing](#testing)
10. [Debugging](#debugging)

---

## Environment Setup

### Prerequisites

**System Requirements:**
- Linux OS (Ubuntu 20.04+ recommended or Debian 11+)
- Minimum 2GB RAM
- 10GB free disk space
- Sudo privileges

**Required Software:**
```bash
# Docker
sudo apt update
sudo apt install docker.io docker-compose

# Verify installation
docker --version        # Should be 20.10+
docker compose version  # Should be 2.0+

# Add user to docker group (avoid sudo for docker commands)
sudo usermod -aG docker $USER
newgrp docker

# Make utility (usually pre-installed)
make --version
```

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Create config placeholders (secrets + .env):**
   ```bash
   make secrets
   ```
   This creates missing files without overwriting existing values:
   - `secrets/db_password.txt`
   - `secrets/db_user_password.txt`
   - `secrets/wp_admin_password.txt`
   - `secrets/wp_user_password.txt`
   - `srcs/.env`

3. **Fill generated files with real values:**
   ```bash
   vim srcs/.env
   vim secrets/db_password.txt
   vim secrets/db_user_password.txt
   vim secrets/wp_admin_password.txt
   vim secrets/wp_user_password.txt
   ```

4. **Validate configuration before build/up:**
   ```bash
   make check_config
   ```

5. **TLS certificates:**
   ```bash
   # Self-signed certificates are generated during nginx image build.
   # Rebuild nginx if needed:
   docker compose -f srcs/docker-compose.yml build nginx
   ```

6. **Configure hosts file:**
   ```bash
   echo "127.0.0.1  inicoara.42.fr" | sudo tee -a /etc/hosts
   ```

---

## Project Architecture

### Directory Structure

```
inception/
├── Makefile                        # Build automation
├── README.md                       # Project overview
├── USER_DOC.md                     # User documentation
├── DEV_DOC.md                      # This file
├── TODO.md                         # Project checklist
├── secrets/                        # Sensitive credentials (gitignored)
│   ├── db_password.txt
│   ├── db_user_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── docker-compose.yml          # Service orchestration
    ├── .env                        # Environment variables
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile          # MariaDB image definition
        │   ├── config.sh           # Initialization script
        │   └── zz-network.cnf      # MariaDB configuration
        ├── nginx/
        │   ├── Dockerfile          # NGINX image definition
        │   ├── nginx.conf          # NGINX configuration
      │   └── (certificates generated during image build)
        └── wordpress/
            ├── Dockerfile          # WordPress image definition
            └── script.sh           # WordPress initialization script
```

### Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Host Machine                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              /etc/hosts: 127.0.0.1 → inicoara.42.fr   │ │
│  └────────────────────────────────────────────────────────┘ │
│                               │                              │
│                               ↓                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │            Port 443 (HTTPS) → NGINX Container          │ │
│  └────────────────────────────────────────────────────────┘ │
│                               │                              │
│  ┌────────────────────────────┴────────────────────────────┐│
│  │           Docker Network: custom (bridge)                ││
│  │                                                          ││
│  │  ┌──────────────┐   ┌──────────────┐   ┌────────────┐ ││
│  │  │    NGINX     │   │  WordPress   │   │  MariaDB   │ ││
│  │  │   (Alpine)   │   │  + PHP-FPM   │   │  (Alpine)  │ ││
│  │  │              │   │   (Alpine)   │   │            │ ││
│  │  │  Port: 443   │   │  Port: 9000  │   │ Port: 3306 │ ││
│  │  │              │   │              │   │            │ ││
│  │  │  SSL/TLS     │→→→│   FastCGI    │→→→│  Database  │ ││
│  │  │  Reverse     │   │   WP-CLI     │   │            │ ││
│  │  │  Proxy       │   │              │   │            │ ││
│  │  └──────┬───────┘   └──────┬───────┘   └─────┬──────┘ ││
│  │         │                  │                  │        ││
│  │         ↓                  ↓                  ↓        ││
│  │  ┌──────────────────────────────────────────────────┐ ││
│  │  │              Docker Volumes (Named)              │ ││
│  │  │  wp_data: /var/www/html   db_data: /var/lib/mysql││
│  │  └──────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
│                               │                              │
│                               ↓                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │    Host Data Directory: /home/inicoara/data/           │ │
│  │    ├── mariadb/  (MariaDB data)                        │ │
│  │    └── wordpress/ (WordPress files)                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Client Request:**
   - Browser → `https://inicoara.42.fr` → `/etc/hosts` → `127.0.0.1:443`

2. **NGINX Processing:**
   - Receives HTTPS request
   - Terminates SSL/TLS
   - Routes to WordPress via FastCGI on `wordpress:9000`

3. **WordPress Processing:**
   - PHP-FPM receives request
   - Executes PHP code
   - Queries MariaDB on `mariadb:3306`

4. **MariaDB Response:**
   - Returns query results to WordPress

5. **Response Chain:**
   - WordPress generates HTML
   - NGINX encrypts response with TLS
   - Client receives HTTPS response

---

## Building and Launching

### Makefile Commands

The project uses a Makefile for all build and management operations:

```makefile
make          # Complete setup: creates directories, builds, and starts
make setup    # Create data directories only
make secrets  # Create secrets/*.txt and srcs/.env if missing
make check_config # Validate secrets and required env vars are non-empty
make build    # Build Docker images
make up       # Start containers (detached mode)
make down     # Stop and remove containers
make stop     # Stop containers (keep them)
make start    # Start stopped containers
make restart  # Restart all containers
make clean    # Remove Docker resources + srcs/.env + secrets/*.txt
make fclean   # Full clean including data directories
make re       # Full rebuild (fclean + all)
make logs     # View and follow logs
make ps       # List running containers
make status   # Detailed status information
make help     # Show help message
```

### Build Process

**1. Directory Setup:**
```bash
make setup
```
Creates:
- `/home/inicoara/data/mariadb`
- `/home/inicoara/data/wordpress`

**2. Config Placeholders and Validation:**
```bash
make secrets
make check_config
```
`make check_config` fails if any required file is empty or if one of these variables is missing/empty in `srcs/.env`:
- `MARIA_DATABASE`
- `MYSQL_USER`
- `MYSQL_HOST`
- `WP_URL`
- `WP_TITLE`
- `WP_ADMIN`
- `WP_ADMIN_EMAIL`
- `WP_USER`
- `WP_USER_EMAIL`

**3. Image Building:**
```bash
make build
```
Builds three Docker images:
- `srcs-mariadb` - Based on Alpine 3.22
- `srcs-nginx` - Based on Alpine 3.22
- `srcs-wordpress` - Based on Alpine 3.22

**4. Container Launch:**
```bash
make up
```
Starts containers in this order:
1. MariaDB (with healthcheck)
2. WordPress (waits for MariaDB healthy)
3. NGINX (waits for WordPress)

### Docker Compose Configuration

**File:** `srcs/docker-compose.yml`

```yaml
services:
  mariadb:
    build: ./requirements/mariadb
    restart: always
    env_file: .env
    secrets: [db_psd, db_user_psd]
    networks: [custom]
    volumes: [db_data:/var/lib/mysql]
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "--skip-ssl"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 30s

  wordpress:
    build: ./requirements/wordpress
    restart: always
    env_file: .env
    secrets: [db_user_psd, wp_admin_psd, wp_user_psd]
    networks: [custom]
    volumes: [wp_data:/var/www/html]
    depends_on:
      mariadb:
        condition: service_healthy

  nginx:
    build: ./requirements/nginx
    restart: always
    networks: [custom]
    ports: ["443:443"]
    volumes: [wp_data:/var/www/html:ro]
    depends_on: [wordpress]

networks:
  custom:
    driver: bridge

volumes:
  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/inicoara/data/mariadb
  wp_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/inicoara/data/wordpress

secrets:
  db_psd:
    file: ../secrets/db_password.txt
  db_user_psd:
    file: ../secrets/db_user_password.txt
  wp_admin_psd:
    file: ../secrets/wp_admin_password.txt
  wp_user_psd:
    file: ../secrets/wp_user_password.txt
```

---

## Container Management

### Inspecting Containers

```bash
# List all containers
docker ps -a

# Inspect a specific container
docker inspect mariadb

# View container logs
docker logs mariadb
docker logs -f wordpress  # Follow logs
docker logs --tail 50 nginx  # Last 50 lines

# Execute commands in a running container
docker exec -it mariadb /bin/sh
docker exec -it wordpress wp --info --allow-root

# View container stats
docker stats

# Check container health
docker inspect --format='{{.State.Health.Status}}' mariadb
```

### Container Lifecycle

```bash
# Start a stopped container
docker start mariadb

# Stop a running container
docker stop wordpress

# Restart a container
docker restart nginx

# Remove a container
docker rm -f mariadb

# View container processes
docker top wordpress
```

---

## Volume Management

### Understanding Volumes

The project uses **named volumes** with local driver binding to host directories:

- **db_data** → `/home/inicoara/data/mariadb` → Container: `/var/lib/mysql`
- **wp_data** → `/home/inicoara/data/wordpress` → Container: `/var/www/html`

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect a volume
docker volume inspect srcs_db_data

# Check volume contents (from host)
sudo ls -la /home/inicoara/data/mariadb
sudo ls -la /home/inicoara/data/wordpress

# Check volume contents (from container)
docker exec mariadb ls -la /var/lib/mysql
docker exec wordpress ls -la /var/www/html

# Remove all volumes (WARNING: data loss!)
make clean
```

### Data Persistence

**Where data is stored:**

```
/home/inicoara/data/
├── mariadb/                    # MariaDB data
│   ├── mysql/                  # System database
│   ├── word_press/             # WordPress database
│   ├── ibdata1                 # InnoDB data
│   ├── ib_logfile*             # InnoDB logs
│   └── ...
└── wordpress/                  # WordPress files
    ├── wp-admin/               # Admin interface
    ├── wp-content/             # Themes, plugins, uploads
    │   ├── themes/
    │   ├── plugins/
    │   └── uploads/
    ├── wp-includes/            # Core files
    ├── wp-config.php           # Configuration
    └── ...
```

**Backup procedures:**

```bash
# Backup volumes
sudo tar -czf backup_mariadb_$(date +%Y%m%d).tar.gz -C /home/inicoara/data mariadb
sudo tar -czf backup_wordpress_$(date +%Y%m%d).tar.gz -C /home/inicoara/data wordpress

# Restore volumes
make down
sudo rm -rf /home/inicoara/data/mariadb
sudo tar -xzf backup_mariadb_20260305.tar.gz -C /home/inicoara/data
sudo rm -rf /home/inicoara/data/wordpress
sudo tar -xzf backup_wordpress_20260305.tar.gz -C /home/inicoara/data
make up
```

---

## Network Configuration

### Docker Network

**Network Name:** `custom`  
**Driver:** `bridge`  
**Subnet:** Automatically assigned by Docker (typically `172.x.0.0/16`)

### DNS Resolution

Docker provides automatic DNS resolution between containers:

- `nginx` can reach `wordpress` by name
- `wordpress` can reach `mariadb` by name
- Internal DNS server: `127.0.0.11`

### Network Commands

```bash
# List networks
docker network ls

# Inspect network
docker network inspect srcs_custom

# Get container IPs
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mariadb
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' wordpress
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx

# Test connectivity between containers
docker exec nginx ping -c 3 wordpress
docker exec wordpress ping -c 3 mariadb

# Test DNS resolution
docker exec nginx nslookup wordpress
docker exec wordpress nslookup mariadb
```

### Port Mapping

Only NGINX exposes a port to the host:

```
Host:443 → nginx:443
```

Internal ports (not exposed):
- `wordpress:9000` (PHP-FPM)
- `mariadb:3306` (MySQL)

---

## Configuration Files

### Environment Variables (.env)

**File:** `srcs/.env`

```bash
# Database
MARIA_DATABASE=word_press
MYSQL_USER=ionut
MYSQL_HOST=mariadb

# WordPress
WP_URL=https://inicoara.42.fr
WP_TITLE=My WordPress
WP_ADMIN=wpboss
WP_ADMIN_EMAIL=wpboss@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com
```

### MariaDB Configuration

**Dockerfile:** `srcs/requirements/mariadb/Dockerfile`
- Base: Alpine 3.22
- Package: `mariadb mariadb-client`
- Entrypoint: `config.sh`

**Script:** `srcs/requirements/mariadb/config.sh`
- Initializes database if not exists
- Creates users with secrets
- Grants permissions
- Starts MariaDB in foreground

**Config:** `srcs/requirements/mariadb/zz-network.cnf`
```ini
[mysqld]
bind-address=0.0.0.0
port=3306
```

### NGINX Configuration

**Dockerfile:** `srcs/requirements/nginx/Dockerfile`
- Base: Alpine 3.22
- Package: `nginx openssl`
- Copies: `nginx.conf`, SSL certificates

**Config:** `srcs/requirements/nginx/nginx.conf`
```nginx
server {
    listen 443 ssl;
    server_name inicoara.42.fr;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate /etc/nginx/inicoara.42.fr.pem;
    ssl_certificate_key /etc/nginx/inicoara.42.fr-key.pem;
    
    root /var/www/html;
    index index.php;
    
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### WordPress Configuration

**Dockerfile:** `srcs/requirements/wordpress/Dockerfile`
- Base: Alpine 3.22
- Packages: `php php-fpm php-mysqli wordpress curl`
- Installs: WP-CLI
- Entrypoint: `script.sh`

**Script:** `srcs/requirements/wordpress/script.sh`
- Downloads WordPress if needed
- Creates `wp-config.php`
- Installs WordPress with WP-CLI
- Creates users
- Starts PHP-FPM in foreground

---

## Development Workflow

### Making Changes

1. **Edit configuration:**
   ```bash
   vim srcs/requirements/nginx/nginx.conf
   ```

2. **Rebuild affected service:**
   ```bash
   docker compose -f srcs/docker-compose.yml build nginx
   ```

3. **Restart service:**
   ```bash
   docker compose -f srcs/docker-compose.yml up -d nginx
   ```

4. **Test changes:**
   ```bash
   curl -k https://inicoara.42.fr
   docker logs nginx
   ```

### Adding a New Service

1. **Create service directory:**
   ```bash
   mkdir -p srcs/requirements/myservice
   ```

2. **Create Dockerfile:**
   ```bash
   vim srcs/requirements/myservice/Dockerfile
   ```

3. **Add to docker-compose.yml:**
   ```yaml
   services:
     myservice:
       build: ./requirements/myservice
       restart: always
       networks:
         - custom
   ```

4. **Build and test:**
   ```bash
   make build
   make up
   ```

---

## Testing

### Manual Tests

```bash
# 1. Build and start
make

# 2. Validate config explicitly (optional if using make/up/build)
make check_config

# 3. Check all containers are running
make ps

# 4. Test HTTPS access
curl -k https://inicoara.42.fr

# 5. Test WordPress login
curl -k -c cookies.txt -d "log=wpboss&pwd=$(cat secrets/wp_admin_password.txt)" https://inicoara.42.fr/wp-login.php

# 6. Test database connection
docker exec wordpress mariadb -h mariadb -u ionut -p$(cat secrets/db_user_password.txt) word_press -e "SHOW TABLES;"

# 7. Check data persistence
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml up -d
curl -k https://inicoara.42.fr  # Should still work
```

---

## Debugging

### Common Issues

**Container won't start:**
```bash
docker logs <container>
docker inspect <container>
```

**Network issues:**
```bash
docker network inspect srcs_custom
docker exec nginx ping wordpress
```

**Volume permission issues:**
```bash
sudo ls -la /home/inicoara/data/
sudo chown -R $(whoami):$(whoami) /home/inicoara/data/
```

**Secret not found:**
```bash
make secrets
ls -la secrets/
cat secrets/db_password.txt
```

---

**Last Updated:** March 2026  
**Project:** Inception - 42 Curriculum  
**Maintainer:** inicoara
