# Troubleshooting - Inception Docker Stack

## Problèmes Rencontrés et Solutions

### 1. **Erreur MariaDB: Can't connect to server on 'mariadb' (115)**

**Problème:**
```
ERROR 2002 (HY000): Can't connect to server on 'mariadb' (115)
mariadb-1 exited with code 1
```

**Cause:**
Le script MariaDB utilisait la commande `mariadb` sans spécifier explicitement la connexion socket locale. Le client essayait de résoudre le hostname 'mariadb' au lieu d'utiliser le socket Unix local.

**Solution:**
Ajout du flag `-h localhost` pour forcer la connexion via le socket Unix local:
```bash
mariadb -h localhost --socket="$SOCK" --skip-ssl -e "CREATE DATABASE..."
```

**Fichier modifié:** `srcs/requirements/mariadb/config.sh`

---

### 2. **Erreur WordPress: PHP memory exhausted**

**Problème:**
```
PHP Fatal error: Allowed memory size of 134217728 bytes exhausted
wordpress-1 exited with code 255
```

**Cause:**
La limite de mémoire PHP par défaut (128MB) était insuffisante pour WP-CLI lors du téléchargement et de l'installation de WordPress.

**Solution:**
Augmentation de la limite mémoire PHP de 128M à 256M dans le Dockerfile:
```dockerfile
RUN PHP_INI="$(ls -1 /etc/php*/php.ini 2>/dev/null | head -n 1)" \
 && [ -n "$PHP_INI" ] \
 && sed -i 's|^memory_limit.*|memory_limit = 256M|' "$PHP_INI"
```

**Fichier modifié:** `srcs/requirements/wordpress/Dockerfile`

---

### 3. **Erreur MariaDB: TLS/SSL error during initialization**

**Problème:**
```
ERROR 2026 (HY000): TLS/SSL error: SSL is required, but the server does not support it
```

**Cause:**
Le serveur MariaDB démarrait avec `--skip-networking` (sans SSL) mais le client mariadb essayait de se connecter avec SSL par défaut.

**Solution:**
Ajout du flag `--skip-ssl` pour toutes les connexions client pendant l'initialisation:
```bash
mariadb -h localhost --socket="$SOCK" --skip-ssl -e "..."
```

**Fichier modifié:** `srcs/requirements/mariadb/config.sh`

---

### 4. **Erreur MariaDB: Access denied for user**

**Problème:**
```
[Warning] Access denied for user 'ionut'@'srcs-wordpress-1.srcs_custom' (using password: YES)
Error: Database connection error (1045)
```

**Cause:**
Les volumes Docker persistaient avec d'anciennes données d'utilisateurs créés avec des mots de passe différents. Le script ne recréait pas les utilisateurs si la base existait déjà.

**Solution:**
Modification du script pour toujours DROP et recréer les utilisateurs avec les bons credentials:
```bash
mariadb -h localhost --socket="$SOCK" --skip-ssl -e "DROP USER IF EXISTS '$MYSQL_USER'@'%';"
mariadb -h localhost --socket="$SOCK" --skip-ssl -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$USER_PASSWORD';"
```

**Fichier modifié:** `srcs/requirements/mariadb/config.sh`

---

### 5. **Erreur WordPress: php-fpm81: not found**

**Problème:**
```
/script.sh: exec: line 71: php-fpm81: not found
wordpress-1 exited with code 127
```

**Cause:**
Le script appelait `php-fpm81` en dur, mais le nom du binaire PHP-FPM varie selon la version installée (php-fpm83 dans Alpine 3.22).

**Solution:**
Détection dynamique du binaire PHP-FPM:
```bash
PHP_FPM=$(which php-fpm* 2>/dev/null | head -n 1)
if [ -z "$PHP_FPM" ]; then
  PHP_FPM=$(ls /usr/sbin/php-fpm* 2>/dev/null | head -n 1)
fi
exec "$PHP_FPM" -F
```

**Fichier modifié:** `srcs/requirements/wordpress/script.sh`

---

### 6. **Nginx: 403 Forbidden**

**Problème:**
```
403 Forbidden sur https://localhost:443
```

**Cause:**
La directive `root` dans nginx.conf pointait vers `/var/www/` au lieu de `/var/www/html` où WordPress est installé.

**Solution:**
Correction du chemin root:
```nginx
root /var/www/html;
```

**Fichier modifié:** `srcs/requirements/nginx/nginx.conf`

---

### 7. **Nginx: 502 Bad Gateway**

**Problème:**
```
502 Bad Gateway
[error] connect() failed (111: Connection refused) while connecting to upstream
```

**Cause:**
PHP-FPM écoutait uniquement sur `127.0.0.1:9000` (interface localhost) au lieu de `0.0.0.0:9000`. Nginx depuis un autre container ne pouvait pas s'y connecter.

**Solution:**
Modification de la configuration PHP-FPM pour écouter sur toutes les interfaces:
```dockerfile
RUN sed -i 's|^listen = .*|listen = 9000|' "$FPM_WWW_CONF"
```

Cela configure PHP-FPM pour écouter sur `0.0.0.0:9000` au lieu de `127.0.0.1:9000`.

**Fichier modifié:** `srcs/requirements/wordpress/Dockerfile`

---

## Améliorations Ajoutées

### Health Check MariaDB
Ajout d'un health check pour s'assurer que MariaDB est complètement opérationnel avant de démarrer WordPress:

```yaml
healthcheck:
  test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "--skip-ssl"]
  interval: 5s
  timeout: 3s
  retries: 10
  start_period: 30s
```

**Fichier modifié:** `srcs/docker-compose.yml`

### Dépendance Conditionnelle
WordPress attend maintenant que MariaDB soit "healthy" avant de démarrer:

```yaml
depends_on:
  mariadb:
    condition: service_healthy
```

**Fichier modifié:** `srcs/docker-compose.yml`

### Wait Loop pour WordPress
Ajout d'une boucle de vérification dans le script WordPress pour s'assurer que MariaDB accepte bien les connexions:

```bash
for i in $(seq 1 30); do
  if mariadb-admin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --skip-ssl --silent 2>/dev/null; then
    echo "MariaDB is ready!"
    break
  fi
  sleep 2
done
```

**Fichier modifié:** `srcs/requirements/wordpress/script.sh`

---

## Commandes Utiles

### Debugging
```bash
# Vérifier les logs
docker compose logs mariadb
docker compose logs wordpress
docker compose logs nginx

# Vérifier les connexions réseau
docker compose exec wordpress netstat -tlnp
docker compose exec mariadb netstat -tlnp

# Tester la connexion à MariaDB
docker compose exec wordpress mariadb-admin ping -h mariadb -u ionut -p

# Accéder à un container
docker compose exec wordpress sh
```

### Rebuild complet
```bash
# Avec suppression des volumes
cd srcs
docker compose down -v
rm -rf /home/inicoara/data/*
docker compose up --build

# Sans suppression des volumes
docker compose down
docker compose up --build
```

---

## Résumé des Fichiers Modifiés

1. **srcs/requirements/mariadb/config.sh**
   - Ajout de `-h localhost --skip-ssl` pour les connexions client
   - Implémentation du DROP/CREATE users pour garantir les bons passwords
   - Amélioration du wait loop pour la disponibilité du socket

2. **srcs/requirements/wordpress/Dockerfile**
   - Augmentation de `memory_limit` à 256M
   - Correction de la configuration PHP-FPM pour écouter sur `0.0.0.0:9000`

3. **srcs/requirements/wordpress/script.sh**
   - Ajout d'un wait loop avec timeout pour MariaDB
   - Détection dynamique du binaire PHP-FPM
   - Ajout du flag `--skip-ssl` pour mariadb-admin

4. **srcs/requirements/nginx/nginx.conf**
   - Correction du `root` vers `/var/www/html`
   - Ajout de `include /etc/nginx/mime.types`
   - Amélioration de la config FastCGI

5. **srcs/docker-compose.yml**
   - Ajout du health check pour MariaDB
   - Modification de `depends_on` avec condition `service_healthy`
