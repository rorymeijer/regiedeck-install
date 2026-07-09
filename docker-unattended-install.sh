#!/usr/bin/env bash
set -euo pipefail

APP_NAME="regiedeck"
APP_DIR="/srv/docker/regiedeck"
REPO="rorymeijer/Regiedeck"
BRANCH="main"
PORT="8181"

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

apt update
apt install -y git curl ca-certificates

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi

mkdir -p "$APP_DIR"
cd "$APP_DIR"

rm -rf app

git clone -b "$BRANCH" "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${REPO}.git" app

cat > Dockerfile <<'EOF'
FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    git \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

COPY app/ /var/www/html/

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/config \
    && chmod -R 775 /var/www/html/storage /var/www/html/config

RUN sed -i 's#/var/www/html#/var/www/html/public#g' /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html
EOF

cat > compose.yml <<EOF
services:
  regiedeck:
    build: .
    container_name: regiedeck
    restart: unless-stopped
    ports:
      - "${PORT}:80"
    environment:
      MYSQL_HOST: "${MYSQL_HOST}"
      MYSQL_DATABASE: "${MYSQL_DATABASE}"
      MYSQL_USER: "${MYSQL_USER}"
      MYSQL_PASSWORD: "${MYSQL_PASSWORD}"
    volumes:
      - ./storage:/var/www/html/storage
      - ./config:/var/www/html/config
EOF

mkdir -p storage config

cp -a app/config/* config/

chown -R 33:33 storage config
chmod -R 775 storage config

docker compose up -d --build

unset GITHUB_TOKEN

echo
echo "Regiedeck Docker container draait."
echo "Open:"
echo "http://<server-ip>:${PORT}/install/"
echo
echo "Na installatie verwijderen:"
echo "docker exec regiedeck rm -rf /var/www/html/public/install"
