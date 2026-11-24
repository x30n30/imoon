import paramiko, os, stat

HOST   = '80.208.230.36'
USER   = 'root'
PW     = 'pOfPF543Qq2o'
LOCAL  = r'E:\#CODE_RED\imoon'
REMOTE = '/opt/imoon'

SKIP_DIRS  = {'.dart_tool', '.idea', '.vscode', 'build', '.git',
              '__pycache__', 'android', 'ios', 'macos', 'windows', 'linux'}
SKIP_EXTS  = {'.g.dart', '.freezed.dart', '.iml'}
SKIP_FILES = {'.flutter-plugins', '.flutter-plugins-dependencies', '.packages',
              'pubspec.lock', 'deploy_now.py'}

def should_skip(rel_path):
    parts = rel_path.replace('\\', '/').split('/')
    if any(p in SKIP_DIRS for p in parts[:-1]):
        return True
    name = parts[-1]
    if name in SKIP_FILES:
        return True
    for ext in SKIP_EXTS:
        if name.endswith(ext):
            return True
    return False

def collect_files():
    files = []
    for root, dirs, fnames in os.walk(LOCAL):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in fnames:
            full = os.path.join(root, fname)
            rel  = os.path.relpath(full, LOCAL)
            if not should_skip(rel):
                files.append((full, rel.replace('\\', '/')))
    return files

def ensure_remote_dir(sftp, remote_path):
    parts = remote_path.strip('/').split('/')
    path  = ''
    for part in parts:
        path += '/' + part
        try:
            sftp.stat(path)
        except FileNotFoundError:
            sftp.mkdir(path)

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
print(f'Connecting to {HOST}...')
ssh.connect(HOST, username=USER, password=PW, timeout=15)
sftp = ssh.open_sftp()

files = collect_files()
print(f'Uploading {len(files)} files...')
for local_path, rel in files:
    remote_path = REMOTE + '/' + rel
    remote_dir  = remote_path.rsplit('/', 1)[0]
    ensure_remote_dir(sftp, remote_dir)
    sftp.put(local_path, remote_path)
    print(f'  {rel}')

sftp.close()

print('\nRunning build on VPS...')
_, out, err = ssh.exec_command(f'bash {REMOTE}/server/build.sh 2>&1')
for line in out:
    print(line, end='')

ssh.close()
print('\nDone — https://imoon.plexus.lv')
