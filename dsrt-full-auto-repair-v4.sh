#!/bin/bash
echo "=============================================="
echo "🤖 DSRT FULL AUTO-REPAIR v4 + BACKUP & RESTORE"
echo "=============================================="

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/repair-log.txt"
BACKUP_DIR="backup/$(date '+%Y-%m-%d_%H-%M')"
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

log() {
  echo "$1"
  echo "$1" >> "$LOG_FILE"
}

log "🕒 Repair started: $(date)"

# ====== MODE RESTORE (opsional) ======
if [[ "$1" == "restore" ]]; then
  echo "♻️  RESTORE MODE"
  echo "Available backups:"
  ls -d backup/* | nl
  echo
  read -p "Enter backup folder number to restore: " choice
  TARGET=$(ls -d backup/* | sed -n "${choice}p")
  if [ -d "$TARGET" ]; then
    cp -r "$TARGET"/* ./
    log "♻️  Restored backup from $TARGET"
    echo "✅ Restored successfully!"
  else
    echo "⚠️ Invalid choice"
  fi
  exit 0
fi

# ====== GIT SETUP ======
if [ ! -d .git ]; then
  log "🧩 Initializing new Git repo..."
  git init
  git branch -M main
fi

REPO_URL=$(git config --get remote.origin.url)
if [ -z "$REPO_URL" ]; then
  if [[ "$CODESPACE_NAME" != "" ]]; then
    USERNAME=$(echo "$CODESPACE_NAME" | cut -d'-' -f1)
    REPO_NAME=$(basename "$(pwd)")
    REPO_URL="https://github.com/$USERNAME/$REPO_NAME.git"
    git remote add origin "$REPO_URL"
    log "🌐 Auto-detected remote: $REPO_URL"
  else
    read -p "Enter GitHub repo URL: " REPO_URL
    git remote add origin "$REPO_URL"
  fi
else
  log "✅ Remote found: $REPO_URL"
fi

# ====== BASE PROJECT CONFIG ======
[ -f package.json ] || npm init -y
npm pkg set name="dsrt-engine"
npm pkg set type="module"
npm pkg set scripts.build="vite build"
npm pkg set scripts.dev="vite"

# ====== INSTALL DEV DEPENDENCIES ======
log "📦 Installing dependencies..."
npm install vite eslint prettier --save-dev --legacy-peer-deps

# ====== FOLDER STRUCTURE ======
for dir in src assets dist public; do
  [ -d "$dir" ] || { mkdir -p "$dir"; log "�� Created folder: $dir"; }
done

# ====== FILE CREATION FUNCTION ======
create_file_if_missing() {
  FILE="$1"
  CONTENT="$2"
  if [ ! -f "$FILE" ]; then
    echo "$CONTENT" > "$FILE"
    log "🧩 Created missing file: $FILE"
  fi
}

# ====== ESSENTIAL FILES ======
create_file_if_missing vite.config.js "// DSRT Engine Vite Config
import { defineConfig } from 'vite';
export default defineConfig({
  root: '.',
  publicDir: 'public',
  build: { outDir: 'dist', sourcemap: true, minify: 'esbuild' },
  server: { port: 5173, open: true }
});
"

create_file_if_missing .eslintrc.json '{
  "env": { "browser": true, "es2021": true },
  "extends": ["eslint:recommended"],
  "parserOptions": { "ecmaVersion": "latest", "sourceType": "module" },
  "rules": { "no-unused-vars": "warn", "no-console": "off" }
}'

create_file_if_missing .prettierrc '{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}'

create_file_if_missing .gitignore "node_modules\ndist\n.env\n*.log\nbackup"

create_file_if_missing index.html '<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>DSRT Engine</title>
  <link rel="stylesheet" href="./assets/style.css" />
</head>
<body>
  <canvas id=\"app\"></canvas>
  <script type=\"module\" src=\"./src/main.js\"></script>
</body>
</html>'

create_file_if_missing src/main.js "// DSRT Engine Entry
import { initEngine } from './engine.js';
window.addEventListener('DOMContentLoaded', () => {
  console.log('🚀 DSRT Engine booting...');
  initEngine();
});
"

create_file_if_missing src/engine.js "// DSRT Basic Engine Example
export function initEngine() {
  const canvas = document.getElementById('app');
  const ctx = canvas.getContext('2d');
  resizeCanvas(canvas);
  ctx.fillStyle = '#0ff';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#000';
  ctx.font = '20px Arial';
  ctx.fillText('DSRT Engine Active', 20, 40);
}
function resizeCanvas(canvas) {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  });
}
"

create_file_if_missing assets/style.css "body {margin: 0;overflow: hidden;background: #0d0d0d;color: #fff;font-family: Arial, sans-serif;}
canvas {display: block;}"

# ====== BACKUP SYSTEM ======
log "🗄️  Backing up current files to $BACKUP_DIR ..."
find src assets . -type f \( -name "*.js" -o -name "*.html" -o -name "*.css" \) -not -path "./$BACKUP_DIR/*" -not -path "./node_modules/*" | while read f; do
  mkdir -p "$BACKUP_DIR/$(dirname "$f")"
  cp "$f" "$BACKUP_DIR/$f"
done
log "✅ Backup completed."

# ====== REPAIR & FORMAT ======
log "🧠 Scanning and repairing source files..."
find src assets . -type f \( -name "*.js" -o -name "*.html" -o -name "*.css" \) | while read f; do
  if [ ! -s "$f" ]; then
    echo "// Auto-fixed empty file" > "$f"
    log "⚙️ Fixed empty file: $f"
  fi
  npx prettier --write "$f" >/dev/null 2>&1
done

# ====== LINT + BUILD ======
log "🔍 Running ESLint..."
npx eslint src --fix || true

log "🏗️ Building project..."
npx vite build || true

# ====== COMMIT + PUSH ======
git add .
git commit -m "🧠 Auto Repair + Backup Sync $(date '+%Y-%m-%d %H:%M:%S')" || log "⚠️ Nothing to commit"
git push -u origin main || log "⚠️ Push failed (check token/remote)"

log "✅ Process completed!"
echo "=============================================="
echo "✅ DSRT AUTO-REPAIR + BACKUP finished!"
echo "📜 Log: $LOG_FILE"
echo "🗄️  Backup folder: $BACKUP_DIR"
echo "=============================================="
