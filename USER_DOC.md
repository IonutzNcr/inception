# User Documentation - Inception

This guide explains how to use and manage the Inception infrastructure as an end user or system administrator.

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting and Stopping the Project](#starting-and-stopping-the-project)
3. [Accessing the Services](#accessing-the-services)
4. [Credential Management](#credential-management)
5. [Checking Service Health](#checking-service-health)
6. [Common Tasks](#common-tasks)
7. [Troubleshooting](#troubleshooting)

---

## Services Overview

The Inception infrastructure provides the following services:

### 1. **NGINX Web Server**
- **Purpose:** Web server and reverse proxy
- **Port:** 443 (HTTPS only)
- **Function:** 
  - Serves as the entry point for all web traffic
  - Handles SSL/TLS encryption
  - Routes requests to WordPress

### 2. **WordPress + PHP-FPM**
- **Purpose:** Content Management System (CMS)
- **Internal Port:** 9000 (not exposed externally)
- **Function:**
  - Powers the website
  - Provides admin interface for content management
  - Processes PHP code and serves web pages

### 3. **MariaDB Database**
- **Purpose:** MySQL-compatible database server
- **Internal Port:** 3306 (not exposed externally)
- **Function:**
  - Stores all WordPress data (posts, pages, users, settings)
  - Accessible only from the WordPress container

---

## Starting and Stopping the Project

### Prerequisites

Before starting, ensure:
- You have sudo privileges (for creating data directories)
- Docker and Docker Compose are installed
- Your system has at least 2GB of free RAM
- Domain name is configured in `/etc/hosts`:
  ```
  127.0.0.1  inicoara.42.fr
  ```

### Starting the Infrastructure

**First time setup:**
```bash
make
```
This command will:
1. Create data directories in `/home/inicoara/data/`
2. Build all Docker images (may take 5-10 minutes)
3. Start all containers
4. Initialize the WordPress installation

**Subsequent starts:**
```bash
make up
```
This starts the existing containers without rebuilding.

### Stopping the Infrastructure

**Stop containers (data persists):**
```bash
make down
```
This stops and removes containers but keeps all data intact.

**Pause containers (keep running):**
```bash
make stop
```
This pauses containers without removing them.

**Resume paused containers:**
```bash
make start
```

### Restarting Services

```bash
make restart
```
This performs a clean stop and start of all services.

### Checking Status

```bash
make ps          # List running containers
make status      # Detailed status information
make logs        # View real-time logs from all containers
```

---

## Accessing the Services

### WordPress Website

**URL:** `https://inicoara.42.fr`

**What you'll see:**
- Your WordPress home page
- All public blog posts and pages

**Browser Warning:**
When first accessing the site, your browser will show a security warning because the SSL certificate is self-signed. This is expected behavior for local development.

**To proceed (example for Firefox):**
1. Click "Advanced"
2. Click "Accept the Risk and Continue"

**To proceed (example for Chrome):**
1. Click "Advanced"
2. Click "Proceed to inicoara.42.fr (unsafe)"

### WordPress Admin Panel

**URL:** `https://inicoara.42.fr/wp-admin`

**Default Credentials:**

**Administrator Account:**
- Username: `wpboss` (configured in `.env`)
- Password: Content of `secrets/wp_admin_password.txt`

**Regular User Account:**
- Username: `editor` (configured in `.env`)
- Password: Content of `secrets/wp_user_password.txt`

**Admin Panel Features:**
- Create and edit posts/pages
- Manage themes and plugins
- Configure site settings
- Manage users
- View site statistics

---

## Credential Management

### Where Credentials Are Stored

All sensitive credentials are stored in the `secrets/` directory at the root of the project:

```
secrets/
├── credentials.txt           # General credentials file
├── db_password.txt           # MariaDB root password
├── db_user_password.txt      # WordPress database user password
├── wp_admin_password.txt     # WordPress admin password
└── wp_user_password.txt      # WordPress editor user password
```

**⚠️ IMPORTANT:** This directory is excluded from Git via `.gitignore` to prevent accidental credential exposure.

### Viewing Credentials

To view a specific credential:

```bash
# WordPress admin password
cat secrets/wp_admin_password.txt

# Database root password
cat secrets/db_password.txt

# WordPress editor password
cat secrets/wp_user_password.txt
```

### Changing Credentials

**⚠️ WARNING:** Changing passwords requires rebuilding the containers.

1. **Edit the credential file:**
   ```bash
   echo "new_secure_password" > secrets/wp_admin_password.txt
   ```

2. **Rebuild the infrastructure:**
   ```bash
   make fclean
   make
   ```

3. **For WordPress user passwords only** (without full rebuild):
   - Log in to WordPress admin panel
   - Go to Users → All Users
   - Click "Edit" on the user
   - Scroll to "Account Management" → "New Password"
   - Update the password file to match:
     ```bash
     echo "new_password" > secrets/wp_admin_password.txt
     ```

### Credential Security Best Practices

✅ **DO:**
- Use strong, unique passwords (minimum 12 characters)
- Store credentials securely (encrypted volume or password manager)
- Rotate credentials regularly (every 90 days recommended)
- Never commit secrets to version control

❌ **DON'T:**
- Share credentials via email or chat
- Reuse passwords across different services
- Write passwords in plain text outside the secrets directory
- Use default or weak passwords in production

---

## Checking Service Health

### Quick Health Check

```bash
make ps
```

**Expected output:**
```
NAME         STATUS         PORTS
mariadb      Up (healthy)   3306/tcp
wordpress    Up             9000/tcp
nginx        Up             0.0.0.0:443->443/tcp
```

All containers should show "Up" status.

### Detailed Container Status

```bash
make status
```

This shows:
- Container running status
- Data directory contents
- Docker images present

### Viewing Container Logs

**All containers:**
```bash
make logs
```

**Specific container:**
```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

**Follow logs in real-time:**
```bash
docker logs -f nginx
```

### Testing Website Connectivity

**From command line:**
```bash
curl -k https://inicoara.42.fr
```

**Expected:** HTML output from WordPress

### Checking Database Connectivity

**From within the WordPress container:**
```bash
docker exec -it wordpress mariadb-admin ping -h mariadb -u ionut -p$(cat secrets/db_user_password.txt)
```

**Expected:** `mysqld is alive`

### Verifying Data Persistence

**Check data directories:**
```bash
ls -lh /home/inicoara/data/mariadb/
ls -lh /home/inicoara/data/wordpress/
```

**MariaDB data directory should contain:**
- `mysql/` - System database
- `word_press/` - WordPress database
- `ib_*` files - InnoDB data files

**WordPress directory should contain:**
- `wp-admin/` - Admin interface
- `wp-content/` - Themes, plugins, uploads
- `wp-includes/` - Core WordPress files
- `wp-config.php` - WordPress configuration

---

## Common Tasks

### Creating a New WordPress Post

1. Go to `https://inicoara.42.fr/wp-admin`
2. Log in with admin credentials
3. Click "Posts" → "Add New"
4. Write your content
5. Click "Publish"

### Installing a WordPress Plugin

1. Log in to WordPress admin
2. Go to "Plugins" → "Add New"
3. Search for the plugin
4. Click "Install Now"
5. Click "Activate"

### Changing WordPress Theme

1. Log in to WordPress admin
2. Go to "Appearance" → "Themes"
3. Click "Add New"
4. Browse or search for a theme
5. Click "Install" then "Activate"

### Backing Up Data

**Manual backup:**
```bash
# Create backup directory
mkdir -p ~/inception_backup_$(date +%Y%m%d)

# Backup MariaDB data
sudo cp -r /home/inicoara/data/mariadb ~/inception_backup_$(date +%Y%m%d)/

# Backup WordPress data
sudo cp -r /home/inicoara/data/wordpress ~/inception_backup_$(date +%Y%m%d)/

# Backup secrets
cp -r secrets ~/inception_backup_$(date +%Y%m%d)/
```

**Restore from backup:**
```bash
make down
sudo rm -rf /home/inicoara/data/*
sudo cp -r ~/inception_backup_20260305/mariadb /home/inicoara/data/
sudo cp -r ~/inception_backup_20260305/wordpress /home/inicoara/data/
make up
```

### Viewing Resource Usage

```bash
docker stats
```

Shows real-time CPU, memory, and network usage for each container.

---

## Troubleshooting

### Website Not Accessible

**Problem:** Cannot access `https://inicoara.42.fr`

**Solutions:**

1. **Check if containers are running:**
   ```bash
   make ps
   ```
   All containers should show "Up" status.

2. **Check `/etc/hosts` configuration:**
   ```bash
   grep inicoara /etc/hosts
   ```
   Should show: `127.0.0.1  inicoara.42.fr`

3. **Check if port 443 is listening:**
   ```bash
   sudo ss -tuln | grep :443
   ```
   Should show LISTEN on port 443.

4. **Check nginx logs:**
   ```bash
   docker logs nginx
   ```

5. **Restart services:**
   ```bash
   make restart
   ```

### WordPress Database Connection Error

**Problem:** "Error establishing a database connection"

**Solutions:**

1. **Check if MariaDB is healthy:**
   ```bash
   docker ps | grep mariadb
   ```
   Should show "(healthy)" status.

2. **Check MariaDB logs:**
   ```bash
   docker logs mariadb
   ```

3. **Verify database credentials in `.env` file:**
   ```bash
   cat srcs/.env
   ```

4. **Test database connection:**
   ```bash
   docker exec -it wordpress mariadb -h mariadb -u ionut -p$(cat secrets/db_user_password.txt) word_press -e "SELECT 1;"
   ```

### Containers Keep Restarting

**Problem:** Containers restart in a loop

**Solutions:**

1. **Check logs for errors:**
   ```bash
   docker logs --tail 50 <container-name>
   ```

2. **Check data directory permissions:**
   ```bash
   ls -la /home/inicoara/data/
   ```

3. **Rebuild from scratch:**
   ```bash
   make fclean
   make
   ```

### SSL Certificate Errors

**Problem:** Browser shows "NET::ERR_CERT_AUTHORITY_INVALID"

**This is expected behavior** because the project uses self-signed certificates.

**Solution:** Accept the security exception in your browser (see "Accessing the Services" section).

### Out of Disk Space

**Problem:** "No space left on device"

**Solutions:**

1. **Check available space:**
   ```bash
   df -h
   ```

2. **Clean up Docker resources:**
   ```bash
   make clean
   docker system prune -a --volumes
   ```

3. **Check data directory size:**
   ```bash
   du -sh /home/inicoara/data/
   ```

### Performance Issues

**Problem:** Website is slow or unresponsive

**Solutions:**

1. **Check resource usage:**
   ```bash
   docker stats
   ```

2. **Check system resources:**
   ```bash
   free -h
   htop
   ```

3. **Restart containers:**
   ```bash
   make restart
   ```

4. **Check for errors in logs:**
   ```bash
   make logs
   ```

---

## Getting Help

For additional support:

1. **Check logs first:**
   ```bash
   make logs
   ```

2. **Review the developer documentation:**
   See [DEV_DOC.md](DEV_DOC.md) for technical details

3. **Check the troubleshooting file:**
   See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for known issues

4. **Contact the system administrator:**
   Provide logs and error messages

---

**Last Updated:** March 2026  
**Project:** Inception - 42 Curriculum  
**Maintainer:** inicoara
