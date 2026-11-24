#!/bin/bash
# iMoon — one-time VPS setup
# Run once via SSH: bash /opt/imoon/server/setup.sh
set -e

echo "=== iMoon VPS Setup ==="

# 1. Flutter SDK
if ! command -v flutter &>/dev/null; then
  echo "Installing Flutter..."
  snap install flutter --classic
fi
flutter --version

# 2. Web directory structure
mkdir -p /opt/imoon
mkdir -p /var/www/imoon/app
mkdir -p /var/www/imoon/download

# 3. Nginx site
cp /opt/imoon/server/nginx.conf /etc/nginx/sites-available/imoon
ln -sf /etc/nginx/sites-available/imoon /etc/nginx/sites-enabled/imoon
nginx -t && systemctl reload nginx
echo "Nginx configured."

# 4. Add Flutter web platform to project (safe to run once)
cd /opt/imoon
flutter create --platforms web . || true
flutter pub get
dart run build_runner build --delete-conflicting-outputs
echo "Flutter web platform ready."

# 5. Initial build
bash /opt/imoon/server/build.sh

# 6. SSL
if ! command -v certbot &>/dev/null; then
  snap install certbot --classic
fi
certbot --nginx -d imoon.plexus.lv --non-interactive --agree-tos \
  -m girts.rutkovskis@appxite.com
echo "SSL certificate installed."

echo "=== Setup complete: https://imoon.plexus.lv ==="
