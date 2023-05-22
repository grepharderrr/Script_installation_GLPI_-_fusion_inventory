#!/bin/bash

# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation des dépendances
sudo apt install -y apache2 mariadb-server php php-mysql php-curl php-json php-gd php-xml php-mbstring php-intl

# Configuration de la base de données MariaDB
sudo mysql_secure_installation

# Création de la base de données et de l'utilisateur pour GLPI
sudo mysql -u root -p -e "CREATE DATABASE glpidb;"
sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON glpidb.* TO 'glpiuser'@'localhost' IDENTIFIED BY 'mot_de_passe';"
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"

# Téléchargement de GLPI
wget https://github.com/glpi-project/glpi/releases/download/10.0.7/glpi-10.0.7.tgz

# Extraction de l'archive GLPI
sudo tar xzf glpi-10.0.7.tgz -C /var/www/html/

# Configuration des permissions
sudo chown -R www-data:www-data /var/www/html/glpi/
sudo chmod -R 755 /var/www/html/glpi/

# Configuration du VirtualHost Apache
sudo tee /etc/apache2/sites-available/glpi.conf > /dev/null <<EOF
<VirtualHost *:80>
  ServerName glpi.local
  DocumentRoot /var/www/html/glpi
  <Directory /var/www/html/glpi>
    Options FollowSymlinks
    AllowOverride All
    Require all granted
  </Directory>
  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Activer le VirtualHost
sudo a2ensite glpi.conf

# Activer les modules Apache nécessaires
sudo a2enmod rewrite
sudo systemctl restart apache2

# Installation du plugin FusionInventory
sudo apt install -y unzip
sudo git clone https://github.com/fusioninventory/fusioninventory-for-glpi.git /var/www/html/glpi/plugins/fusioninventory

# Configuration des permissions
sudo chown -R www-data:www-data /var/www/html/glpi/plugins/fusioninventory/

# Redémarrage d'Apache
sudo systemctl restart apache2

# Nettoyage des fichiers téléchargés
rm glpi-10.0.7.tgz

# Accès au répertoire du plugin FusionInventory
cd /var/www/html/glpi/plugins/fusioninventory/

# Installation des dépendances du plugin
sudo apt install -y composer
sudo composer install

# Activation du plugin dans GLPI
sudo php /var/www/html/glpi/bin/console glpi:plugin:install FusionInventory
sudo php /var/www/html/glpi/bin/console glpi:plugin:activate FusionInventory

# Redémarrage d'Apache
sudo systemctl restart apache2

echo "L'installation de GLPI avec le plugin FusionInventory est terminée."
echo "Accédez à votre GLPI en utilisant l'URL : http://votre_ip/glpi"
