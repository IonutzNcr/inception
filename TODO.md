# 📋 TODO - Projet Inception

## ❌ OBLIGATOIRE - À Faire

### 1. **Makefile** ⚠️ CRITIQUE
**Statut:** Fichier vide  
**Action requise:**
```makefile
# Règles obligatoires à implémenter:
- all      : Construire et lancer tous les conteneurs
- build    : Construire les images Docker
- up       : Démarrer les conteneurs (avec -d)
- down     : Arrêter les conteneurs
- stop     : Arrêter sans supprimer
- start    : Redémarrer les conteneurs arrêtés
- clean    : Supprimer conteneurs, volumes, images
- fclean   : clean + suppression des données dans /home/$(USER)/data
- re       : fclean + all
- logs     : Afficher les logs
- ps       : Voir les conteneurs en cours
```

**Localisation:** `/home/ionut/work/inception2/Makefile`

---

### 2. **Restart Policy** ⚠️ CRITIQUE
**Statut:** Manquant dans docker-compose.yml  
**Exigence:** Les conteneurs doivent redémarrer automatiquement en cas de crash

**Action requise:** Ajouter à chaque service dans `docker-compose.yml`:
```yaml
services:
  mariadb:
    restart: always    # ← Ajouter cette ligne
    ...
  nginx:
    restart: always    # ← Ajouter cette ligne
    ...
  wordpress:
    restart: always    # ← Ajouter cette ligne
    ...
```

**Localisation:** `srcs/docker-compose.yml`

---

### 3. **TLS Protocol** ⚠️ CRITIQUE
**Statut:** Protocoles SSL/TLS non spécifiés  
**Exigence:** Nginx doit utiliser uniquement TLSv1.2 ou TLSv1.3

**Action requise:** Ajouter dans `nginx.conf`:
```nginx
server {
    listen 443 ssl;
    server_name inicoara.42.fr;
    
    # Ajouter ces lignes:
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    
    ssl_certificate    /etc/nginx/inicoara.42.fr.pem;
    ssl_certificate_key /etc/nginx/inicoara.42.fr-key.pem;
    ...
}
```

**Localisation:** `srcs/requirements/nginx/nginx.conf` (ligne 16-18)

---



### 5. **Port 443 UNIQUEMENT** ⚠️⚠️ CRITIQUE
**Statut:** Nginx écoute sur port 80 - INTERDIT par le sujet  
**Citation du sujet:** *"Your NGINX container must be the only entrypoint into your infrastructure via the port 443 only"*

**Action OBLIGATOIRE:** SUPPRIMER le bloc `listen 80` dans nginx.conf

**❌ BLOC À SUPPRIMER:**
```nginx
server {
    listen 80;
    server_name inicoara.42.fr;
    return 301 https://$host$request_uri;
}
```

**✅ Garder UNIQUEMENT:**
```nginx
server {
    listen 443 ssl;
    server_name inicoara.42.fr;
    
    ssl_pSecret db_root_password manquant** ⚠️ IMPORTANT
**Statut:** Le sujet montre 3 fichiers secrets dont `db_root_password.txt`  
**Actuel:** Vous avez db_password.txt et db_user_password.txt

**Action requise:** Créer le fichier manquant et l'utiliser
```bash
# Créer le fichier
echo "VotreMotDePasseRoot" > secrets/db_root_password.txt
```

**Ajouter dans docker-compose.yml:**
```yaml
secrets:
  db_root_psd:
    file: ../secrets/db_root_password.txt
```

**Localisation:** `secrets/db_root_password.txt` (à créer)

---

### 7. **rotocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ...
}
```

**Localisation:** `srcs/requirements/nginx/nginx.conf` (lignes 10-14 à supprimer)

---

### 6. **.gitignore** 📝 RECOMMANDÉ
**Statut:** Absent  
**Action requise:** Créer un `.gitignore` à la racine:

```gitignore
# Secrets et mots de passe
secrets/
*.txt
.env

# Certificats SSL
*.pem
*.key
*.crt
*.csr
8. **Domain Name** ✅ VÉRIFIÉ
**Statut:** OK - `inicoara.42.fr` utilisé partout  
**Citation du sujet:** *"This domain name must be login.42.fr"*
data/

# Docker
.docker/

# OS
.DS_9. **Script PHP-FPM** 📝 AMÉLIORATION
**Statut:** Script WordPress incomplet  
**Citation du sujet:** *"Read about PID 1 and the best practices for writing Dockerfiles"*

**Action requise:** Ajouter cette ligne à la fin de `script.sh`:

```bash
# À ajouter à la fin du script (avant la ligne finale)
chown -R www-data:www-data /var/www/html

# Lancer PHP-FPM en foreground (PID 1)
**Localisation:** `/home/ionut/work/inception2/.gitignore` (à créer)

---

### 7. **Domain Name** ✅ VÉRIFIÉ
**Statut:** OK - `inicoara.42.fr` utilisé partout  
**Action:** Vérifier que `/etc/hosts` contient:
```
127.0.0.1  inicoara.42.fr
```

---

### 8. **Script PHP-FPM** 📝 AMÉLIORATION
**Statut:** Script WordPress incomplet  
**Action requise:** Ajouter cette ligne à la fin de `script.sh`:

```bash
# À ajouter à la fin du script (avant la ligne finale)
chown -R www-data:www-data /var/www/html

# Lancer PHP-FPM en foreground
exec php-fpm83 -F    # ← Ajouter cette ligne
```

**Localisation:** `srcs/requirements/wordpress/script.sh` (ligne 95)
10. **Container Names** 📝 RECOMMANDÉ
**Statut:** Noms de conteneurs non spécifiés  
**Citation du sujet:** *"Each Docker image must have the same name as its corresponding service"*


### 9. **Container Names** 📝 RECOMMANDÉ
**Statut:** Noms de conteneurs non spécifiés  
**Action recommandée:** Ajouter `container_name` dans docker-compose.yml:

```yaml
services:
  mariadb:
    container_name: mariadb    # ← Ajouter
    ...
  nginx:
    container_name: nginx      # ← Ajouter
    ...
  wordpress:
    container_name: wordpress  # ← Ajouter
    ...
```

**Localisation:** `srcs/docker-compose.yml`
**Citation du sujet:** Le sujet mentionne un dossier `bonus/` pour services additionnels

### 11
---

## 🎁 BONUS - Services Additionnels (Optionnel)

### 10. **Redis Cache** (Bonus)
**Statut:** Non implémenté  
**Action:** Créer service Redis pour cache WordPress:
- Dossier: `srcs/requirements/bonus/redis/`
- Dockerfile avec Alpine + redis
- Configuration Redis
- Intégration avec WordPress (plugin Redis Object Cache)

---

### 11. **FTP Server** (Bonus)
**Statut:** Non implémenté  
**Action:** Créer service FTP (vsftpd) pour gérer les fichiers WordPress:
- Dossier: `srcs/requirements/bonus/ftp/`
- Dockerfile avec Alpine + vsftpd
- Volume partagé avec WordPress
- Port 21 exposé

---

### 12. **Adminer** (Bonus)
**Statut:** Non implémenté  
**Action:** Créer service Adminer pour gérer MariaDB via interface web:
- Dossier: `srcs/requirements/bonus/adminer/`
- Dockerfile avec Alpine + PHP + Adminer
- Port 8080 exposé
- Accès à MariaDB

---

### 13. **Service Personnel** (Bonus)
**Statut:** Non implémenté  
**Exemples possibles:**
- Site statique (nginx simple)
- Portainer (gestion Docker)
- Monitoring (Grafana/Prometheus)
- Wiki (WikiJS)

---⚠️ VOLUMES: Supprimer bind mounts (interdit par le sujet!)
3. ⚠️ PORT 80: Supprimer le listen 80 (seulement 443 autorisé)
4. ✅ Restart policy dans docker-compose.yml
5. ✅ TLS protocols dans nginx.conf

6. ✅ Ajouter db_root_password.txt secret
7. ✅ Ajouter .gitignore
8. ✅ Restart policy dans docker-compose.yml
3. ✅ TLS protocols dans nginx.conf
4. ✅ Corriger chemins volumes (username)

### 🟡 IMPORTANT (Nécessaire mais non bloquant immédiat)
9. ✅ Container names explicites
10. ✅ Ajouter .gitignore
7. ✅ Compléter script.sh WordPress (exec php-fpm)

#1. Redis cache
12. FTP server
13. Adminer
14
### 🎁 BONUS (Points supplémentaires)
10. Redis cache
11. FTP server
12. Adminer
13. Service personnalisé au choix
 (SELON LE SUJET OFFICIEL)

1. **Makefile** - ✅ FAIT
2. **❌ CRITIQUE: Volumes** - Corriger les bind mounts interdits
3. **❌ CRITIQUE: Port 80** - Supprimer le listen 80 (seulement 443!)
4. **Restart policy** - Ajouter `restart: always` partout
5. **TLS protocols** - Ajouter `ssl_protocols TLSv1.2 TLSv1.3;`
6. **db_root_password** - Créer le secret manquant
7. **WordPress script** - Ajouter `exec php-fpm83 -F`
8. **Tests** - Lancer avec `make` et vérifier que tout fonctionne
9. **.gitignore** - Créer le fichier
10. **WordPress script** - Ajouter `exec php-fpm83 -F`
6. **Tests** - Lancer avec `make` et vérifier que tout fonctionne
7. **.gitignore** - Créer le fichier
8. **Bonus** (si temps) - Ajouter Redis, FTP, etc.
 (SELON SUJET OFFICIEL v5.2)

### Configuration
- [ ] Makefile avec toutes les règles à la racine
- [ ] `restart: always` sur tous les services (exigé par sujet)
- [ ] TLS 1.2/1.3 UNIQUEMENT spécifié dans nginx
- [ ] **PORT 443 UNIQUEMENT** (pas de port 80!)
- [ ] Named volumes (PAS de bind mounts!)
- [ ] Volumes stockés dans `/home/inicoara/data/` (votre login 42)
- [ ] Docker network configuré

### Conteneurs
- [ ] NGINX avec TLSv1.2/1.3 uniquement
- [ ] WordPress + php-fpm (sans nginx)
- [ ] MariaDB (sans nginx)
- [ ] Tous les Dockerfiles partent d'Alpine ou Debian (penultimate stable)
- [ ] Pas d'images "ready-made" (pas de wordpress:latest, etc.)
- [ ] Pas de `tail -f`, `sleep infinity`, `while true` interdits
- [ ] PID 1 correct (exec pour le processus principal)

### Sécurité
- [ ] Certificats SSL avec SAN correct
- [ ] Domain name: `inicoara.42.fr` (login.42.fr)
- [ ] Variables d'environnement dans .env
- [ ] Secrets dans fichiers séparés (secrets/)
- [ ] **Aucun mot de passe dans les Dockerfiles**
- [ ] 2 utilisateurs WordPress (admin ne contient pas admin/Admin/administrator)

### Tests
- [ ] WordPress accessible via HTTPS uniquement
- [ ] Volumes persistants fonctionnels
- [ ] Conteneurs redémarrent en cas de crash
- [ ] `make` construit et lance tout
- [ ] `make down` nettoie correctement
- [ ] `make fclean` supprime tout y compris data/

### Structure (selon sujet)
```
.
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
``` Debian
- [ ] Variables d'environnement dans .env
- [ ] Secrets dans fichiers séparés (secrets/)
- [ ] Documentation claire (README si demandé)

---

**Bon courage pour finaliser le projet ! 🚀**
