#!/bin/bash

# Fonction pour générer un mot de passe aléatoire
generate_password() {
    echo $(date +%s | sha256sum | base64 | head -c 16)
}

# Demande le nom de domaine
read -p "Entrez le nom de domaine (exemple: net.fr): " DOMAIN

# Chemins des dossiers
DOC_ROOT="/var/www/$DOMAIN/web"
LOG_DIR="/var/www/$DOMAIN/log"

# Crée les dossiers nécessaires
mkdir -p $DOC_ROOT
mkdir -p $LOG_DIR

# Attribue les permissions à www-data
chown -R www-data:www-data /var/www/$DOMAIN

# Vérifie si l'utilisateur souhaite un wildcard
read -p "Souhaitez-vous activer le wildcard dans le même dossier pour ce domaine? [y/n]: " WILDCARD
if [ "$WILDCARD" == "y" ]; then
    WILDCARD_ALIAS="ServerAlias *.${DOMAIN}"
else
    WILDCARD_ALIAS=""
fi

# Crée le fichier VirtualHost
VH_CONF="/etc/apache2/sites-available/$DOMAIN.conf"
cat <<EOF > $VH_CONF
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        # BEGIN Config
        # VirtualHost Domain : $DOMAIN
        ServerAdmin webmaster@$DOMAIN
        ServerName $DOMAIN
        $WILDCARD_ALIAS
        DocumentRoot $DOC_ROOT
        <Directory $DOC_ROOT>
            # Suite identique pour tous les Sites
            Options Indexes FollowSymLinks MultiViews
            AllowOverride All
            Order allow,deny
            allow from all
        </Directory>

        # Logs 
        ErrorLog $LOG_DIR/error.log
        CustomLog $LOG_DIR/access.log combined

        # SSL : Idem pour tous les sites SSL géré par CloudFlare
        SSLEngine on
        SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
        SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

        # Fichiers
        <FilesMatch "\.(cgi|shtml|phtml|php)$">
            SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>
        <FilesMatch \.php$>
            SetHandler "proxy:unix:/var/run/php/php7.4-fpm.sock|fcgi://localhost/"
        </FilesMatch>
        # END Config
    </VirtualHost>
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF

echo "Fichier VirtualHost pour $DOMAIN créé avec succès !"

# Gestion de wildcard
if [ "$WILDCARD" == "y" ]; then
    echo "Wilcard *.$DOMAIN associé au domaine principal"
fi

# Gestion de la base de données MySQL
read -p "Souhaitez-vous créer une base de données MySQL et un utilisateur dédié pour ce domaine? [y/n]: " MYSQL_DB
if [ "$MYSQL_DB" == "y" ]; then
    DB_NAME="bd_${DOMAIN//./_}" # Remplace les '.' par '_'
    DB_USER="${DOMAIN//./_}_user"
    DB_PASS=$(generate_password)

    # Crée la base de données et l'utilisateur
    mysql -u root -p -e "CREATE DATABASE ${DB_NAME};"
    mysql -u root -p -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -u root -p -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    mysql -u root -p -e "FLUSH PRIVILEGES;"

    echo "Base de données MySQL créée avec succès : ${DB_NAME} - Utilisateur : ${DB_USER} - Mot de Passe : ${DB_PASS}"
fi
