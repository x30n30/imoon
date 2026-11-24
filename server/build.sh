#!/bin/bash
# iMoon — build Flutter web and deploy to /var/www/imoon/
set -e

cd /opt/imoon

echo "[1/4] flutter pub get"
flutter pub get

echo "[2/4] build_runner (generates database.g.dart)"
dart run build_runner build --delete-conflicting-outputs

echo "[3/4] flutter build web"
flutter build web --release --base-href /app/

echo "[4/4] deploy web build"
rm -rf /var/www/imoon/app/*
cp -r build/web/* /var/www/imoon/app/

# Landing page
cp server/landing/index.html /var/www/imoon/index.html

# Android APK (only if SDK present)
if command -v sdkmanager &>/dev/null; then
  echo "[+] Building Android APK..."
  flutter build apk --release
  cp build/app/outputs/flutter-apk/app-release.apk /var/www/imoon/download/imoon.apk
  echo "APK deployed."
else
  echo "[skip] Android SDK not found — APK build skipped."
fi

echo "=== Build complete ==="
