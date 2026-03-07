# Fondamentaux des Réseaux

## 1. Modèle OSI et TCP/IP

### Modèle OSI (7 couches)
```
7. Application  → HTTP, FTP, DNS, SSH
6. Présentation → Chiffrement, compression
5. Session      → Gestion des connexions
4. Transport    → TCP, UDP (ports)
3. Réseau       → IP, routage
2. Liaison      → Ethernet, MAC
1. Physique     → Câbles, signaux
```

### Modèle TCP/IP (4 couches - utilisé en pratique)
```
4. Application  → HTTP, DNS, SSH (couches 5-7 OSI)
3. Transport    → TCP, UDP
2. Internet     → IP, ICMP
1. Accès réseau → Ethernet, WiFi (couches 1-2 OSI)
```

---

## 2. Adressage IP

### IPv4
- Format : `192.168.1.1`
- 4 octets (32 bits)
- Plage : 0.0.0.0 à 255.255.255.255

### Classes d'adresses (historique)
```
Classe A : 0.0.0.0   - 127.255.255.255  (1er octet)
Classe B : 128.0.0.0 - 191.255.255.255  (2 premiers octets)
Classe C : 192.0.0.0 - 223.255.255.255  (3 premiers octets)
```

### Adresses privées (non routables sur Internet)
```
10.0.0.0        - 10.255.255.255   (1 réseau Classe A)
172.16.0.0      - 172.31.255.255   (16 réseaux Classe B)
192.168.0.0     - 192.168.255.255  (256 réseaux Classe C)
127.0.0.0       - 127.255.255.255  (localhost/loopback)
```

### Masque de sous-réseau (Subnet Mask)

Le masque définit quelle partie de l'IP est le **réseau** et quelle partie est l'**hôte**.

**Notation CIDR** : `/24` = 255.255.255.0

```
/8  = 255.0.0.0       → 16 777 216 hôtes (Classe A)
/16 = 255.255.0.0     → 65 536 hôtes (Classe B)
/24 = 255.255.255.0   → 256 hôtes (Classe C)
/32 = 255.255.255.255 → 1 seul hôte (adresse spécifique)
```

**Exemple** : `192.168.1.50/24`
```
IP      : 192.168.1.50
Masque  : 255.255.255.0
Réseau  : 192.168.1.0
Broadcast: 192.168.1.255
Hôtes   : 192.168.1.1 à 192.168.1.254 (254 adresses utilisables)
```

**Calcul** :
- IP ET Masque = Adresse réseau
- `192.168.1.50` ET `255.255.255.0` = `192.168.1.0`

---

## 3. Ports et Services

### Concept des Ports
- Numéro de 0 à 65535
- Permet d'identifier l'application sur une machine
- Format : `IP:Port` → `192.168.1.1:80`

### Ports bien connus (0-1023)
```
20/21  : FTP (File Transfer Protocol)
22     : SSH (Secure Shell)
23     : Telnet (non sécurisé)
25     : SMTP (envoi email)
53     : DNS (résolution de noms)
80     : HTTP (web non chiffré)
110    : POP3 (réception email)
143    : IMAP (réception email)
443    : HTTPS (web chiffré/SSL)
3306   : MySQL/MariaDB
5432   : PostgreSQL
6379   : Redis
```

### Types de ports
- **0-1023** : Ports système (root requis)
- **1024-49151** : Ports enregistrés (applications)
- **49152-65535** : Ports dynamiques/privés (éphémères)

---

## 4. Protocoles de Transport

### TCP (Transmission Control Protocol)
**Caractéristiques** :
- ✅ Orienté connexion (handshake en 3 étapes)
- ✅ Fiable (garantit la livraison)
- ✅ Ordre préservé
- ✅ Contrôle de flux
- ❌ Plus lent que UDP

**Handshake TCP (3-way)** :
```
Client → Server : SYN
Server → Client : SYN-ACK
Client → Server : ACK
→ Connexion établie
```

**Utilisé par** : HTTP, HTTPS, SSH, FTP, SMTP

### UDP (User Datagram Protocol)
**Caractéristiques** :
- ✅ Sans connexion
- ✅ Rapide
- ✅ Faible latence
- ❌ Pas de garantie de livraison
- ❌ Pas d'ordre garanti

**Utilisé par** : DNS, DHCP, streaming vidéo, VoIP, jeux en ligne

---

## 5. DNS (Domain Name System)

### Rôle
Convertir les noms de domaine en adresses IP.

**Exemple** :
```
google.com → 142.250.185.46
```

### Hiérarchie DNS
```
.                        (root)
  └── .fr                (TLD - Top Level Domain)
       └── google.fr     (Second Level Domain)
            └── www.google.fr (Subdomain)
```

### Types d'enregistrements DNS
```
A      : Nom → IPv4        (example.com → 192.168.1.1)
AAAA   : Nom → IPv6        (example.com → 2001:db8::1)
CNAME  : Alias             (www → example.com)
MX     : Serveur mail      (mail.example.com)
TXT    : Texte arbitraire  (vérifications SPF, DKIM)
NS     : Serveur DNS       (autoritaire pour le domaine)
```

### Fichier /etc/hosts
Résolution locale avant DNS :
```
127.0.0.1       localhost
192.168.1.10    mon-serveur.local
```

---

## 6. NAT (Network Address Translation)

### Principe
Permet à plusieurs machines avec des **IP privées** de partager une **IP publique** pour accéder à Internet.

**Exemple** :
```
Réseau local (privé)        Routeur/NAT           Internet (public)
192.168.1.10:5000  →  →  →  203.0.113.5:12345  →  →  →  Server:80
192.168.1.20:6000  →  →  →  203.0.113.5:12346  →  →  →  Server:80
```

Le routeur garde une **table de traduction** pour savoir où renvoyer les réponses.

---

## 7. Routage

### Table de routage
Détermine où envoyer les paquets.

**Commande** : `ip route` ou `route -n`

**Exemple** :
```
Destination     Gateway         Interface
0.0.0.0         192.168.1.1     eth0         (route par défaut)
192.168.1.0/24  0.0.0.0         eth0         (réseau local)
172.17.0.0/16   0.0.0.0         docker0      (réseau Docker)
```

### Route par défaut (Default Gateway)
- `0.0.0.0/0` = toutes les destinations
- Utilisée quand aucune route spécifique ne correspond
- Généralement la box/routeur Internet

---

## 8. Pare-feu (Firewall)

### iptables / nftables (Linux)
Filtre les paquets entrants/sortants selon des règles.

**Concepts** :
- **INPUT** : paquets entrants vers la machine
- **OUTPUT** : paquets sortants depuis la machine
- **FORWARD** : paquets traversant la machine (routeur)

**Exemples iptables** :
```bash
# Autoriser le port 443 (HTTPS)
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Bloquer une IP
iptables -A INPUT -s 192.168.1.50 -j DROP

# Autoriser localhost
iptables -A INPUT -i lo -j ACCEPT
```

---

## 9. Docker Networking

### Types de réseaux Docker
```
bridge  : Réseau par défaut isolé (containers sur même hôte)
host    : Utilise le réseau de l'hôte directement
none    : Pas de réseau
custom  : Réseaux personnalisés (meilleure isolation)
```

### Bridge Network (par défaut)
- Réseau virtuel privé : `172.17.0.0/16`
- Chaque container a une IP dans ce réseau
- Les containers peuvent communiquer entre eux par IP
- **Port mapping** : `-p 8080:80` (hôte:container)

### Custom Network (docker-compose)
**Avantages** :
- ✅ Résolution DNS automatique (nom du service)
- ✅ Isolation entre projets
- ✅ Communication inter-containers sécurisée

**Exemple** :
```yaml
services:
  nginx:
    networks:
      - custom
  wordpress:
    networks:
      - custom

networks:
  custom:
    driver: bridge
```

**Communication** :
- nginx peut contacter wordpress via `http://wordpress:9000`
- Docker résout `wordpress` → IP du container

---

## 10. SSL/TLS et Certificats

### Principe
Chiffrer les communications entre client et serveur (HTTPS).

### Certificat SSL
- Contient la **clé publique**
- Signé par une **Autorité de Certification (CA)**
- Prouve l'identité du serveur

### Certificat Auto-Signé
- Créé par vous-même (pas de CA)
- Gratuit mais **non reconnu** par les navigateurs
- ⚠️ Message "Your connection is not private"

**Création** :
```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout server-key.pem \
  -out server.pem \
  -subj "/CN=example.com" \
  -addext "subjectAltName=DNS:example.com"
```

### Extensions importantes
- **CN (Common Name)** : Nom de domaine principal
- **SAN (Subject Alternative Name)** : **OBLIGATOIRE** pour Chrome
  - Exemple : `DNS:example.com,DNS:www.example.com`

---

## 11. Concepts Réseau dans votre Projet Inception

### Architecture
```
Client (navigateur)
    ↓ HTTPS:443
Nginx (reverse proxy)
    ↓ FastCGI:9000
WordPress (PHP-FPM)
    ↓ MySQL:3306
MariaDB
```

### Réseau Docker Custom
```yaml
networks:
  custom:
    driver: bridge
```

**Ce qui se passe** :
1. Tous les containers sont sur le réseau `custom`
2. Docker crée un bridge virtuel (ex: `172.18.0.0/16`)
3. Chaque container a une IP : `172.18.0.2`, `172.18.0.3`, etc.
4. Docker DNS résout les noms : `mariadb` → `172.18.0.2`

### Pourquoi nginx peut contacter wordpress ?
```nginx
fastcgi_pass wordpress:9000;
```

- `wordpress` = nom du service dans docker-compose
- Docker résout `wordpress` → IP du container WordPress
- Port `9000` = PHP-FPM écoute sur ce port

### Pourquoi WordPress peut contacter MariaDB ?
```php
DB_HOST=mariadb
```

- `mariadb` = nom du service
- Docker résout `mariadb` → IP du container MariaDB
- Port `3306` par défaut pour MySQL/MariaDB

### Binding des ports
```yaml
nginx:
  ports:
    - "443:443"  # hôte:container
```

- Port **443 de l'hôte** → Port **443 du container nginx**
- `0.0.0.0:443` = écoute sur toutes les interfaces
- Accessible depuis l'extérieur

---

## 12. Débogage Réseau

### Commandes essentielles

```bash
# Voir les interfaces réseau
ip addr
ifconfig

# Voir les routes
ip route
route -n

# Tester la connectivité
ping google.com
ping 8.8.8.8

# Résolution DNS
nslookup google.com
dig google.com

# Ports ouverts
ss -tuln          # tous les ports en écoute
netstat -tuln     # alternative
lsof -i :443      # qui écoute sur le port 443

# Tracer le chemin réseau
traceroute google.com

# Tester un port TCP
telnet google.com 80
nc -zv google.com 80

# Voir les connexions actives
ss -tunap
netstat -tunap

# Firewall
iptables -L -n -v

# Docker
docker network ls
docker network inspect bridge
```

### Déboguer Docker Networking

```bash
# Voir les réseaux Docker
docker network ls

# Inspecter un réseau
docker network inspect srcs_custom

# Voir l'IP d'un container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name

# Tester depuis un container
docker exec -it nginx ping wordpress
docker exec -it nginx telnet mariadb 3306
docker exec -it nginx nslookup mariadb

# Logs réseau
docker logs nginx
docker logs wordpress
```

---

## 13. Troubleshooting Courants

### "Connection refused"
- ✅ Le serveur n'écoute pas sur ce port
- → Vérifier : `ss -tuln | grep :443`

### "No route to host"
- ✅ Problème de routage ou firewall
- → Vérifier : `ip route`, `iptables -L`

### "Network unreachable"
- ✅ Pas de route vers le réseau
- → Vérifier : gateway configurée ?

### "Name or service not known"
- ✅ Problème DNS
- → Vérifier : `/etc/hosts`, `/etc/resolv.conf`

### "Connection timeout"
- ✅ Firewall bloque ou serveur ne répond pas
- → Tester avec `telnet` ou `nc`

### Docker : "Cannot connect to service"
- ✅ Services pas sur le même réseau Docker
- ✅ Service pas démarré (depends_on)
- → Vérifier : `docker network inspect`

---

## 14. Bonnes Pratiques

### Sécurité
- ✅ N'exposer que les ports nécessaires
- ✅ Utiliser HTTPS (pas HTTP)
- ✅ Firewall pour bloquer l'accès non autorisé
- ✅ Certificats valides (Let's Encrypt)
- ✅ Mettre à jour régulièrement

### Docker
- ✅ Utiliser des réseaux custom (pas bridge par défaut)
- ✅ Ne pas utiliser `network_mode: host` (sauf cas particulier)
- ✅ Nommer les containers explicitement
- ✅ Utiliser `depends_on` avec `condition: service_healthy`

### Debugging
- ✅ Vérifier couche par couche (bottom-up)
- ✅ Tester la connectivité IP d'abord (ping)
- ✅ Puis DNS (nslookup)
- ✅ Puis port (telnet/nc)
- ✅ Lire les logs !

---

## Résumé Visuel : Flux d'une Requête HTTPS

```
1. Client tape : https://inicoara.42.fr
   
2. DNS : inicoara.42.fr → 127.0.0.1 (via /etc/hosts)

3. TCP Handshake (SYN, SYN-ACK, ACK) → Port 443

4. TLS Handshake : négociation du chiffrement, échange des certificats

5. Requête HTTP chiffrée :
   GET / HTTP/1.1
   Host: inicoara.42.fr

6. Docker : hôte:443 → nginx:443 (port mapping)

7. Nginx traite la requête :
   - Vérifie le server_name
   - Passe à PHP-FPM : fastcgi_pass wordpress:9000

8. Docker DNS : wordpress → IP du container WordPress

9. WordPress (PHP) traite la requête :
   - Se connecte à MariaDB via mysql://mariadb:3306
   - Docker DNS : mariadb → IP du container MariaDB

10. MariaDB exécute les requêtes SQL, renvoie les données

11. WordPress génère le HTML

12. Nginx renvoie la réponse chiffrée au client

13. Navigateur déchiffre et affiche la page
```

---

**Note** : Ces fondamentaux sont essentiels pour comprendre Docker, les microservices, et le déploiement d'applications web modernes !
