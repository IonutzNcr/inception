# Concepts Clés et Outils - Réseau et Docker

## 📚 Concepts Réseau Fondamentaux

### Modèles de Réseau
- **Modèle OSI** (7 couches)
- **Modèle TCP/IP** (4 couches)

### Adressage
- **IPv4** - Adresse IP version 4 (32 bits)
- **IPv6** - Adresse IP version 6 (128 bits)
- **Masque de sous-réseau** (Subnet Mask)
- **CIDR** - Classless Inter-Domain Routing (notation /24, /16, etc.)
- **Adresses privées** (10.x.x.x, 172.16.x.x, 192.168.x.x)
- **Adresses publiques**
- **Localhost / Loopback** (127.0.0.1)
- **Broadcast**

### Protocoles de Transport
- **TCP** - Transmission Control Protocol (orienté connexion, fiable)
- **UDP** - User Datagram Protocol (sans connexion, rapide)
- **Handshake TCP** (SYN, SYN-ACK, ACK)
- **Ports** (0-65535)
  - Ports bien connus (0-1023)
  - Ports enregistrés (1024-49151)
  - Ports dynamiques (49152-65535)

### Services et Protocoles Applicatifs
- **HTTP** - Port 80 (web non chiffré)
- **HTTPS** - Port 443 (web chiffré)
- **SSH** - Port 22 (connexion sécurisée)
- **FTP** - Ports 20/21 (transfert de fichiers)
- **DNS** - Port 53 (résolution de noms)
- **SMTP** - Port 25 (envoi email)
- **MySQL/MariaDB** - Port 3306
- **PostgreSQL** - Port 5432
- **FastCGI** - Port 9000 (PHP-FPM)

### DNS (Domain Name System)
- **Enregistrement A** (IPv4)
- **Enregistrement AAAA** (IPv6)
- **Enregistrement CNAME** (alias)
- **Enregistrement MX** (mail)
- **Enregistrement TXT**
- **Enregistrement NS** (name server)
- **TLD** - Top Level Domain (.fr, .com)
- **Subdomain**
- **/etc/hosts** - Résolution locale

### Routage et Translation
- **Routage** - Acheminement des paquets
- **Table de routage**
- **Gateway / Passerelle**
- **Route par défaut** (0.0.0.0/0)
- **NAT** - Network Address Translation
- **IP publique** vs **IP privée**

### Sécurité
- **Firewall** - Pare-feu
- **iptables** - Firewall Linux
- **nftables** - Nouvelle génération de firewall Linux
- **SSL/TLS** - Chiffrement des communications
- **Certificat SSL**
- **Autorité de Certification (CA)**
- **Certificat auto-signé**
- **CN** - Common Name
- **SAN** - Subject Alternative Name
- **Let's Encrypt** - CA gratuite

### Concepts de Filtrage
- **INPUT** - Paquets entrants
- **OUTPUT** - Paquets sortants
- **FORWARD** - Paquets transférés

---

## 🐳 Concepts Docker Networking

### Types de Réseaux
- **Bridge network** - Réseau par défaut isolé
- **Host network** - Utilise le réseau de l'hôte
- **None** - Pas de réseau
- **Custom network** - Réseau personnalisé
- **Overlay network** - Pour Docker Swarm

### Fonctionnalités
- **Port mapping** (publication de ports)
- **Docker DNS** - Résolution automatique des noms de services
- **Isolation réseau** - Séparation entre projets
- **Communication inter-containers**
- **Network driver** - Bridge, host, overlay

### Configuration
- **networks** (dans docker-compose.yml)
- **ports** (binding hôte:container)
- **expose** (ports internes uniquement)
- **links** (legacy, éviter)

---

## 🛠️ Outils de Diagnostic Réseau

### Interfaces et Adresses
```bash
ip addr                    # Voir les interfaces et IPs
ip a                       # Version courte
ifconfig                   # Alternative (legacy)
```

### Routage
```bash
ip route                   # Table de routage
ip r                       # Version courte
route -n                   # Alternative (legacy)
```

### Connectivité
```bash
ping <host>                # Tester la connectivité ICMP
ping -c 4 google.com       # 4 paquets seulement
traceroute <host>          # Tracer le chemin réseau
tracepath <host>           # Alternative sans root
```

### DNS
```bash
nslookup <domain>          # Résolution DNS simple
dig <domain>               # Résolution DNS détaillée
dig +short <domain>        # Résultat court
host <domain>              # Alternative simple
```

### Ports et Connexions
```bash
ss -tuln                   # Tous les ports en écoute (TCP/UDP)
ss -tunap                  # Avec les processus
netstat -tuln              # Alternative (legacy)
netstat -tunap             # Avec les processus
lsof -i :443               # Qui écoute sur le port 443
lsof -i TCP:80             # Connexions TCP sur port 80
```

### Test de Ports
```bash
telnet <host> <port>       # Tester connexion TCP
nc -zv <host> <port>       # Netcat : test de port
nc -l 8080                 # Écouter sur port 8080
curl -I https://site.com   # Tester HTTP/HTTPS
wget --spider <url>        # Tester URL
```

### Firewall
```bash
iptables -L -n -v          # Lister les règles
iptables -S                # Afficher en format commande
iptables -A INPUT ...      # Ajouter une règle
iptables -D INPUT ...      # Supprimer une règle
iptables -F                # Flush (vider) les règles
```

### Analyse de Trafic
```bash
tcpdump -i eth0            # Capturer le trafic
tcpdump -i any port 443    # Capturer port 443 sur toutes les interfaces
wireshark                  # GUI pour analyse de trafic
```

---

## 🐋 Outils Docker Networking

### Gestion des Réseaux
```bash
docker network ls                         # Lister les réseaux
docker network create <name>              # Créer un réseau
docker network rm <name>                  # Supprimer un réseau
docker network inspect <name>             # Inspecter un réseau
docker network connect <net> <container>  # Connecter un container
docker network disconnect <net> <cont>    # Déconnecter un container
```

### Inspection des Containers
```bash
# Obtenir l'IP d'un container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container>

# Voir tous les détails réseau
docker inspect <container> | grep -A 20 NetworkSettings

# Voir les ports exposés
docker port <container>
```

### Tests Depuis un Container
```bash
# Ping depuis un container
docker exec -it <container> ping <target>

# Test DNS
docker exec -it <container> nslookup <domain>

# Test de port
docker exec -it <container> telnet <host> <port>
docker exec -it <container> nc -zv <host> <port>

# Curl depuis un container
docker exec -it <container> curl <url>
```

### Logs et Débogage
```bash
docker logs <container>                   # Voir les logs
docker logs -f <container>                # Suivre les logs en temps réel
docker logs --tail 100 <container>        # 100 dernières lignes
docker stats                              # Statistiques en temps réel
docker top <container>                    # Processus dans le container
```

---

## 🔧 Outils SSL/TLS

### Génération de Certificats
```bash
# Certificat auto-signé
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout server-key.pem \
  -out server.pem \
  -subj "/CN=example.com" \
  -addext "subjectAltName=DNS:example.com"

# Voir le contenu d'un certificat
openssl x509 -in server.pem -text -noout

# Vérifier une clé privée
openssl rsa -in server-key.pem -check

# Tester une connexion SSL
openssl s_client -connect example.com:443
```

---

## 📋 Commandes Rapides de Débogage

### Checklist Réseau de Base
```bash
# 1. Interfaces actives ?
ip addr

# 2. Gateway configurée ?
ip route | grep default

# 3. DNS fonctionne ?
nslookup google.com

# 4. Internet accessible ?
ping -c 4 8.8.8.8

# 5. Ports en écoute ?
ss -tuln | grep :443

# 6. Firewall bloque ?
iptables -L -n
```

### Checklist Docker
```bash
# 1. Containers en cours ?
docker ps

# 2. Réseaux créés ?
docker network ls

# 3. Container sur le bon réseau ?
docker inspect <container> | grep NetworkMode

# 4. IP du container ?
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container>

# 5. DNS Docker fonctionne ?
docker exec -it <container> nslookup <service_name>

# 6. Port accessible ?
docker exec -it <container> nc -zv <service> <port>

# 7. Logs d'erreur ?
docker logs <container>
```

---

## 🎯 Résumé par Cas d'Usage

### Tester la connectivité réseau
- `ping` - Test ICMP
- `traceroute` - Chemin réseau
- `telnet` / `nc` - Test TCP

### Déboguer DNS
- `nslookup` - Requête DNS simple
- `dig` - Requête DNS détaillée
- `/etc/hosts` - Résolution locale

### Voir les ports ouverts
- `ss -tuln` - Ports en écoute
- `lsof -i` - Ports par processus
- `netstat -tuln` - Alternative

### Déboguer Docker
- `docker network inspect` - Voir le réseau
- `docker exec ... ping` - Test connectivité
- `docker logs` - Voir les erreurs

### Sécuriser avec SSL
- `openssl req` - Générer certificat
- `openssl x509` - Lire certificat
- `openssl s_client` - Tester SSL

---

## 💡 Ressources Complémentaires

### Fichiers de Configuration Importants
- `/etc/hosts` - Résolution DNS locale
- `/etc/resolv.conf` - Serveurs DNS
- `/etc/sysctl.conf` - Configuration réseau kernel
- `/etc/nginx/nginx.conf` - Configuration Nginx
- `docker-compose.yml` - Configuration Docker Compose

### Variables d'Environnement Utiles
- `$HOSTNAME` - Nom de l'hôte
- `$PWD` - Répertoire courant

---

**Note** : Cette liste est un référentiel rapide pour le projet Inception et l'administration système réseau en général.
