#!/usr/bin/env bash
# Enciende el backend (Next.js) si no está corriendo ya en el puerto 3000.
# VS Code lo ejecuta automáticamente antes de abrir la app (ver .vscode/launch.json).
set -euo pipefail

cd "$(dirname "$0")/../backend"

if curl -s -m 3 -o /dev/null http://localhost:3000/api/config; then
  echo "Backend ya está encendido en http://localhost:3000"
  echo "Ready"
  exit 0
fi

if [[ ! -d node_modules ]]; then
  echo "Instalando dependencias del backend..."
  npm install
fi

echo "Encendiendo backend en http://localhost:3000 ..."
exec npm run dev
