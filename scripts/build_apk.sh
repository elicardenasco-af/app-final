#!/usr/bin/env bash
# Genera el instalador Android (APK) de Tienda App y lo publica en el backend
# para descargarlo desde el celular en http://IP_DEL_PC:3000
#
# Uso:
#   ./scripts/build_apk.sh                 # detecta la IP del PC en la red Wi-Fi
#   ./scripts/build_apk.sh 192.168.1.50    # usa una IP específica
set -euo pipefail

cd "$(dirname "$0")/.."

IP="${1:-}"
if [[ -z "$IP" ]]; then
  IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
fi
if [[ -z "$IP" ]]; then
  echo "No se pudo detectar la IP del PC. Pásala como argumento: ./scripts/build_apk.sh 192.168.1.50" >&2
  exit 1
fi

API_URL="http://$IP:3000/api"
echo "→ Compilando APK con API_URL=$API_URL"
flutter build apk --release --dart-define=API_URL="$API_URL"

mkdir -p backend/public/downloads
cp build/app/outputs/flutter-apk/app-release.apk backend/public/downloads/TiendaApp.apk
echo "$API_URL" > backend/public/downloads/api-url.txt

echo
echo "✓ APK listo: backend/public/downloads/TiendaApp.apk"
echo "  Con el backend encendido (cd backend && npm run dev), abre en el celular:"
echo "  http://$IP:3000  →  botón \"Descargar app\""
