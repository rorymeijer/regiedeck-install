#!/usr/bin/env bash
set -euo pipefail

# === Regiedeck unattended deploy ===

HOSTNAME="regiedeck"
CPU="2"
RAM="2048"
DISK="20"
BRIDGE="vmbr0"
STORAGE="local-lvm"
TEMPLATE_STORAGE="local"

REPO="rorymeijer/Regiedeck"
BRANCH="main"
APP_DIR="/var/www/regiedeck"

echo "GitHub authenticatie voor private repo:"
read -r -p "GitHub username: " GITHUB_USER
read -r -s -p "GitHub token: " GITHUB_TOKEN
echo

read -r -p "Externe MySQL host [192.168.2.146]: " MYSQL_HOST
MYSQL_HOST="${MYSQL_HOST:-192.168.2.146}"

read -r -p "MySQL database [regiedeck]: " MYSQL_DATABASE
MYSQL_DATABASE="${MYSQL_DATABASE:-regiedeck}"

read -r -p "MySQL user [regiedeck]: " MYSQL_USER
MYSQL_USER="${MYSQL_USER:-regiedeck}"

read -r -s -p "MySQL password: " MYSQL_PASSWORD
echo

POST_INSTALL="/root/regiedeck-post-install.sh"

cat > "$POST_INSTALL" <<'POSTEOF'
#!/usr/bin/env bash
set -euo pipefail

apt update
apt install -y apache2 git unzip curl \
php php-cli php-mysql php-mbstring php-json php-curl php-xml libapache2-mod-php

a2enmod rewrite

rm -rf /var/www/regiedeck

git clone -b "__BRANCH__" "https://__GITHUB_USER__:__GITHUB_TOKEN__@github.com/__REPO__.git" /var/www/regiedeck

chown -R www-data:www-data /var/www/regiedeck/storage /var/www/regiedeck/config
chmod -R 775 /var/www/regiedeck/storage /var/www/regiedeck/config

cat > /etc/apache2/sites-available/regiedeck.conf <<'EOF'
<VirtualHost *:80>
    ServerName regiedeck.local
    DocumentRoot /var/www/regiedeck/public

    <Directory /var/www/regiedeck/public>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/regiedeck_error.log
    CustomLog ${APACHE_LOG_DIR}/regiedeck_access.log combined
</VirtualHost>
EOF

a2dissite 000-default.conf || true
a2ensite regiedeck.conf
systemctl reload apache2

cat > /root/regiedeck-db-info.txt <<EOF
MySQL host: __MYSQL_HOST__
Database: __MYSQL_DATABASE__
User: __MYSQL_USER__
Password: __MYSQL_PASSWORD__

Open:
http://<container-ip>/install/

Na installatie uitvoeren:
rm -rf /var/www/regiedeck/public/install
EOF

unset GITHUB_TOKEN
history -c || true
POSTEOF

sed -i \
  -e "s#__BRANCH__#${BRANCH}#g" \
  -e "s#__GITHUB_USER__#${GITHUB_USER}#g" \
  -e "s#__GITHUB_TOKEN__#${GITHUB_TOKEN}#g" \
  -e "s#__REPO__#${REPO}#g" \
  -e "s#__MYSQL_HOST__#${MYSQL_HOST}#g" \
  -e "s#__MYSQL_DATABASE__#${MYSQL_DATABASE}#g" \
  -e "s#__MYSQL_USER__#${MYSQL_USER}#g" \
  -e "s#__MYSQL_PASSWORD__#${MYSQL_PASSWORD}#g" \
  "$POST_INSTALL"

chmod +x "$POST_INSTALL"

var_unprivileged=1 \
var_cpu="$CPU" \
var_ram="$RAM" \
var_disk="$DISK" \
var_hostname="$HOSTNAME" \
var_os=debian \
var_version=12 \
var_brg="$BRIDGE" \
var_net=dhcp \
var_ipv6_method=none \
var_ssh=yes \
var_nesting=0 \
var_keyctl=1 \
var_tags=regiedeck,web,automated \
var_container_storage="$STORAGE" \
var_template_storage="$TEMPLATE_STORAGE" \
var_post_install="$POST_INSTALL" \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"

rm -f "$POST_INSTALL"

echo
echo "Regiedeck container is aangemaakt."
echo "Zoek het IP met:"
echo "pct list"
echo
echo "Open daarna:"
echo "http://<container-ip>/install/"
