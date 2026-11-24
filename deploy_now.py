"""
iMoon deploy script.

Usage:
  python deploy_now.py          -- deploy pre-built web app + landing page
  python deploy_now.py --apk    -- also upload build/app/outputs/flutter-apk/app-release.apk

Before running, build locally:
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  flutter build web --release --base-href /app/
  flutter build apk --release  (optional, for Android)
"""

import paramiko, os, sys

HOST   = '80.208.230.36'
USER   = 'root'
PW     = 'pOfPF543Qq2o'
LOCAL  = r'E:\#CODE_RED\imoon'

DEPLOY_APK = '--apk' in sys.argv

# Build happens in E:\imoon (no # in path — Dart URI requirement)
BUILD_DIR  = r'E:\imoon'
WEB_LOCAL  = os.path.join(BUILD_DIR, 'build', 'web')
WEB_REMOTE = '/var/www/imoon/app'
LANDING    = os.path.join(LOCAL, 'server', 'landing', 'index.html')

def ensure_remote_dir(sftp, path):
    parts = path.strip('/').split('/')
    p = ''
    for part in parts:
        p += '/' + part
        try:
            sftp.stat(p)
        except FileNotFoundError:
            sftp.mkdir(p)

def upload_dir(sftp, local_dir, remote_dir):
    ensure_remote_dir(sftp, remote_dir)
    count = 0
    for root, dirs, files in os.walk(local_dir):
        rel_root = os.path.relpath(root, local_dir).replace('\\', '/')
        rdir = remote_dir if rel_root == '.' else remote_dir + '/' + rel_root
        ensure_remote_dir(sftp, rdir)
        for fname in files:
            lpath = os.path.join(root, fname)
            rpath = rdir + '/' + fname
            sftp.put(lpath, rpath)
            count += 1
    return count

if not os.path.isdir(WEB_LOCAL):
    print('ERROR: build/web/ not found.')
    print('Run: flutter build web --release --base-href /app/')
    sys.exit(1)

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print(f'Connecting to {HOST}...')
ssh.connect(HOST, username=USER, password=PW, timeout=15)
sftp = ssh.open_sftp()

# Clear old web build
ssh.exec_command(f'rm -rf {WEB_REMOTE}/* 2>/dev/null; mkdir -p {WEB_REMOTE}')

print('Uploading Flutter web build...')
n = upload_dir(sftp, WEB_LOCAL, WEB_REMOTE)
print(f'  {n} files uploaded to {WEB_REMOTE}')

print('Uploading landing page...')
sftp.put(LANDING, '/var/www/imoon/index.html')
print('  landing page updated')

if DEPLOY_APK:
    apk_local  = os.path.join(LOCAL, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
    apk_remote = '/var/www/imoon/download/imoon.apk'
    if os.path.exists(apk_local):
        ensure_remote_dir(sftp, '/var/www/imoon/download')
        sftp.put(apk_local, apk_remote)
        print('  APK uploaded')
    else:
        print('  APK not found (run: flutter build apk --release)')

sftp.close()
ssh.close()
print('\nDone — https://imoon.plexus.lv')
