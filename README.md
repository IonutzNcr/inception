*This project has been created as part of the 42 curriculum by inicoara*

# Inception

## Description

**Inception** is a system administration project that focuses on containerization using Docker. The goal is to set up a small infrastructure composed of different services (NGINX, WordPress, MariaDB) running in separate Docker containers, following best practices for security, isolation, and configuration management.

This project demonstrates:
- Docker containerization and orchestration
- Multi-service architecture with Docker Compose
- Network configuration and service isolation
- Volume management and data persistence
- SSL/TLS certificate configuration
- Secret management and environment variables

The entire infrastructure runs on Alpine Linux containers, connected through a custom Docker network, with persistent data storage on the host machine.

## Instructions

### Prerequisites
- A Linux system (physical machine or virtual machine)
- Docker and Docker Compose installed
- Make utility
- Sudo privileges for directory creation

### Installation and Execution

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Configure your domain:**
   Add the following line to `/etc/hosts`:
   ```
   127.0.0.1  inicoara.42.fr
   ```

3. **Build and launch the project:**
   ```bash
   make
   ```
   This will:
   - Create necessary data directories (`/home/inicoara/data/mariadb` and `/home/inicoara/data/wordpress`)
   - Build all Docker images
   - Start all containers in detached mode

4. **Access the services:**
   - WordPress site: `https://inicoara.42.fr`
   - WordPress admin panel: `https://inicoara.42.fr/wp-admin`

### Available Commands

```bash
make          # Build and start all containers
make build    # Build Docker images
make up       # Start containers
make down     # Stop and remove containers
make stop     # Stop containers (keep them)
make start    # Start stopped containers
make restart  # Restart all containers
make clean    # Remove containers, volumes, and images
make fclean   # Full clean including data directories
make re       # Full rebuild (fclean + all)
make logs     # Show and follow container logs
make ps       # List running containers
make status   # Show detailed status
make help     # Show help message
```

### Stopping the Project

```bash
make down     # Stop and remove containers (data persists)
make fclean   # Complete cleanup including data
```

## Project Structure

```
.
├── Makefile                  # Build and management commands
├── secrets/                  # Sensitive credentials (gitignored)
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_user_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── docker-compose.yml    # Service orchestration
    ├── .env                  # Environment variables
    └── requirements/
        ├── mariadb/          # MariaDB container configuration
        │   ├── Dockerfile
        │   ├── config.sh
        │   └── zz-network.cnf
        ├── nginx/            # NGINX container configuration
        │   ├── Dockerfile
        │   ├── nginx.conf
        │   ├── inicoara.42.fr.pem
        │   └── inicoara.42.fr-key.pem
        └── wordpress/        # WordPress container configuration
            ├── Dockerfile
            └── script.sh
```

## Architecture and Design Choices

### Docker in This Project

This project uses Docker to create an isolated, reproducible infrastructure with the following services:

1. **NGINX** - Web server and reverse proxy
   - Entry point to the infrastructure (port 443 only)
   - Handles TLS/SSL termination
   - Forwards PHP requests to WordPress container via FastCGI

2. **WordPress + PHP-FPM** - Content management system
   - Runs PHP-FPM on port 9000
   - Serves WordPress application
   - Connects to MariaDB for data storage

3. **MariaDB** - Database server
   - Stores WordPress data
   - Isolated from direct external access
   - Persistent data storage via Docker volumes

### Technical Comparisons

#### Virtual Machines vs Docker

| Virtual Machines | Docker |
|-----------------|--------|
| Full OS virtualization | OS-level virtualization |
| Higher resource overhead | Lightweight (shared kernel) |
| Slower startup (minutes) | Fast startup (seconds) |
| Stronger isolation | Process-level isolation |
| Multiple kernels | Single kernel, multiple containers |

**Choice for this project:** Docker provides faster deployment, easier management, and sufficient isolation for this use case while being more resource-efficient.

#### Secrets vs Environment Variables

| Secrets | Environment Variables |
|---------|----------------------|
| Encrypted at rest | Stored in plain text |
| Mounted as files in `/run/secrets/` | Available as env vars |
| Not visible in `docker inspect` | Visible in `docker inspect` |
| Better security for credentials | Good for non-sensitive config |

**Choice for this project:** Docker secrets are used for all passwords and credentials, while `.env` files store non-sensitive configuration like database names and URLs.

#### Docker Network vs Host Network

| Docker Network (bridge) | Host Network |
|------------------------|--------------|
| Container isolation | Shares host network stack |
| Custom DNS resolution | Direct host access |
| Network namespace per container | No network isolation |
| Port mapping required | Direct port binding |

**Choice for this project:** Custom Docker bridge network (`custom`) for service isolation and automatic DNS resolution between containers (e.g., `wordpress` resolves to the WordPress container IP).

#### Docker Volumes vs Bind Mounts

| Docker Volumes | Bind Mounts |
|---------------|-------------|
| Managed by Docker | Direct host path mapping |
| Named and portable | Absolute paths |
| Better performance on some systems | Direct file access |
| Can use volume drivers | Limited to local filesystem |

**Choice for this project:** Named volumes with local driver binding to `/home/inicoara/data/` to comply with project requirements while maintaining Docker volume management benefits.

## Resources

### Classic References

**Docker Documentation:**
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Networking](https://docs.docker.com/network/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)

**NGINX:**
- [NGINX Official Documentation](https://nginx.org/en/docs/)
- [NGINX SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [NGINX FastCGI Module](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)

**WordPress:**
- [WordPress Documentation](https://wordpress.org/documentation/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [WordPress with Docker](https://developer.wordpress.org/advanced-administration/before-install/howto-install/#docker)

**MariaDB:**
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [MariaDB on Docker](https://hub.docker.com/_/mariadb)

**SSL/TLS:**
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [TLS Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)

### AI Usage

AI tools were used in this project for the following tasks:

1. **Code Review and Best Practices:**
   - Validating Dockerfile syntax and optimization
   - Reviewing shell scripts for security issues
   - Checking NGINX configuration for performance and security

2. **Documentation:**
   - Generating initial templates for technical documentation
   - Reviewing markdown structure and clarity
   - Ensuring completeness of installation instructions

3. **Debugging:**
   - Analyzing Docker Compose networking issues
   - Troubleshooting volume permission problems
   - Understanding healthcheck failures

4. **Research:**
   - Comparing TLS versions and cipher suites
   - Understanding PID 1 and signal handling in containers
   - Learning about Docker secrets implementation

**Note:** All AI-generated content was thoroughly reviewed, tested, and adapted to ensure correctness and understanding. Peer reviews were conducted to validate implementation choices.

## Credentials

Default credentials are stored in the `secrets/` directory (not committed to Git). For initial setup, create the following files:

- `secrets/db_password.txt` - MariaDB root password
- `secrets/db_user_password.txt` - WordPress database user password
- `secrets/wp_admin_password.txt` - WordPress admin password
- `secrets/wp_user_password.txt` - WordPress regular user password

See `USER_DOC.md` for detailed credential management instructions.

## Additional Documentation

- **[USER_DOC.md](USER_DOC.md)** - User and administrator guide
- **[DEV_DOC.md](DEV_DOC.md)** - Developer documentation
- **[TODO.md](TODO.md)** - Project checklist and requirements tracking

## License

This project is part of the 42 school curriculum and is intended for educational purposes.
