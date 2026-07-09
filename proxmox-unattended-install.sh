#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="regiedeck"
CPU="2"
RAM="2048"
DISK="20"
BRIDGE="vmbr0"
STORAGE="local-lvm"
TEMPLATE_STORAGE="local"

REPO="rorymeijer/Regiedeck"
BRANCH="main"

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

POST_INSTALL_HOST="/root/regiedeck-post-install.sh"
POST_INSTALL_CT="/root/regiedeck-post-install.sh"

cat > "$POST_INSTALL_HOST" <<POSTEOF
#!/usr/bin/env bash
set -euo pipefail

rm -f /etc/apt/sources.list.d/pve-enterprise.sources
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/ceph.sources
rm -f /etc/apt/sources.list.d/ceph.list

apt update

apt install -y apache2 git unzip curl sudo \\
php php-cli php-mysql php-mbstring php-curl php-xml libapache2-mod-php

a2enmod rewrite

echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername

rm -rf /var/www/regiedeck

git clone -b "$BRANCH" "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$REPO.git" /var/www/regiedeck

mkdir -p /var/www/regiedeck/storage/logs /var/www/regiedeck/config

# Rechten voor installer, storage én in-app updater
chown -R www-data:www-data /var/www/regiedeck/storage /var/www/regiedeck/config /var/www/regiedeck/.git
chmod -R 775 /var/www/regiedeck/storage /var/www/regiedeck/config

# Git safe-directory voor root én www-data
git config --global --add safe.directory /var/www/regiedeck || true
sudo -u www-data git config --global --add safe.directory /var/www/regiedeck || true

cat > /etc/apache2/sites-available/regiedeck.conf <<'EOF'
<VirtualHost *:80>
    ServerName regiedeck.local
    DocumentRoot /var/www/regiedeck/public

    <Directory /var/www/regiedeck/public>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/regiedeck_error.log
    CustomLog \${APACHE_LOG_DIR}/regiedeck_access.log combined
</VirtualHost>
EOF

a2dissite 000-default.conf || true
a2ensite regiedeck.conf
systemctl enable apache2
systemctl restart apache2

cat > /usr/local/bin/update-regiedeck <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd /var/www/regiedeck

sudo -u www-data git fetch origin
sudo -u www-data git reset --hard origin/main

chown -R www-data:www-data /var/www/regiedeck/storage /var/www/regiedeck/config /var/www/regiedeck/.git
chmod -R 775 /var/www/regiedeck/storage /var/www/regiedeck/config
chown -R www-data:www-data /var/www/regiedeck

systemctl reload apache2

echo "Regiedeck is bijgewerkt."
EOF

chmod +x /usr/local/bin/update-regiedeck

cat > /root/regiedeck-db-info.txt <<EOF
MySQL host: $MYSQL_HOST
Database: $MYSQL_DATABASE
User: $MYSQL_USER
Password: $MYSQL_PASSWORD

Open:
http://<container-ip>/install/

Na installatie uitvoeren:
rm -rf /var/www/regiedeck/public/install

Handmatig updaten:
update-regiedeck
EOF

rm -f /root/regiedeck-post-install.sh
history -c || true
POSTEOF

chmod +x "$POST_INSTALL_HOST"

echo "Container aanmaken..."

BEFORE_IDS="$(pct list | awk 'NR>1 {print $1}')"

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
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"

AFTER_IDS="$(pct list | awk 'NR>1 {print $1}')"
CTID="$(comm -13 <(echo "$BEFORE_IDS" | sort) <(echo "$AFTER_IDS" | sort) | tail -n 1)"

if [[ -z "$CTID" ]]; then
  echo "Kon CTID niet automatisch bepalen."
  echo "Gebruik: pct list"
  exit 1
fi

echo "Nieuwe container gevonden: CTID $CTID"

echo "Post-install script naar container kopiëren..."
pct push "$CTID" "$POST_INSTALL_HOST" "$POST_INSTALL_CT" --perms 700

echo "Post-install uitvoeren in container..."
pct exec "$CTID" -- bash "$POST_INSTALL_CT"

rm -f "$POST_INSTALL_HOST"

echo
echo "Regiedeck is geïnstalleerd in container $CTID."
echo "IP-adres zoeken:"
echo "pct exec $CTID -- hostname -I"
echo
echo "Open daarna:"
echo "http://<container-ip>/install/"
echo
echo "Handmatig updaten:"
echo "pct exec $CTID -- update-regiedeck"
