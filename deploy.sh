#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 🎸 La Antiradio – Script de despliegue automático
# Uso: curl el raw de GitHub y ejecutar, o copiar al VPS y:
#   chmod +x deploy.sh && sudo ./deploy.sh
# ============================================================

REPO_URL="https://github.com/infolaantiradio-usr01/Youtube-liveStream.git"
BRANCH="feature/azuracast-migration"
INSTALL_DIR="/opt/antiradio"
TEMP_DIR="/tmp/antiradio-deploy"
SYSTEMD_DIR="/etc/systemd/system"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✔]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✘]${NC} $1"; exit 1; }

# --- Comprobar root ---
if [[ $EUID -ne 0 ]]; then
  error "Este script debe ejecutarse como root (sudo ./deploy.sh)"
fi

echo ""
echo "🎸 La Antiradio – Despliegue AzuraCast v2.0"
echo "============================================="
echo ""

# --- 1. Instalar dependencias si faltan ---
for cmd in git jq curl ffmpeg; do
  if ! command -v "$cmd" &>/dev/null; then
    warn "$cmd no encontrado. Instalando..."
    apt-get update -qq && apt-get install -y -qq "$cmd"
    log "$cmd instalado"
  else
    log "$cmd ya disponible"
  fi
done

# --- 2. Clonar rama desde GitHub ---
rm -rf "$TEMP_DIR"
log "Clonando rama '$BRANCH' desde GitHub..."
git clone -b "$BRANCH" --depth 1 "$REPO_URL" "$TEMP_DIR"
log "Repositorio clonado en $TEMP_DIR"

# --- 3. Crear directorio de instalación si no existe ---
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/covers"

# --- 4. Comprobar que existen los archivos esenciales ---
if [[ ! -f "$INSTALL_DIR/logo.png" ]]; then
  warn "No se encontró logo.png en $INSTALL_DIR"
  warn "Asegúrate de copiar tu logo.png a $INSTALL_DIR antes de iniciar el stream"
fi

# --- 5. Parar servicios existentes (si están corriendo) ---
if systemctl is-active --quiet antiradio-ffmpeg 2>/dev/null; then
  log "Parando antiradio-ffmpeg..."
  systemctl stop antiradio-ffmpeg
fi
if systemctl is-active --quiet antiradio-nowplaying 2>/dev/null; then
  log "Parando antiradio-nowplaying..."
  systemctl stop antiradio-nowplaying
fi

# --- 6. Copiar scripts ---
log "Instalando scripts en $INSTALL_DIR..."
cp -f "$TEMP_DIR/antiradio/ffmpeg.sh"     "$INSTALL_DIR/ffmpeg.sh"
cp -f "$TEMP_DIR/antiradio/nowplaying.sh"  "$INSTALL_DIR/nowplaying.sh"
chmod +x "$INSTALL_DIR/ffmpeg.sh" "$INSTALL_DIR/nowplaying.sh"
log "Scripts instalados y con permisos de ejecución"

# --- 7. Copiar servicios systemd ---
log "Instalando servicios systemd..."
cp -f "$TEMP_DIR/systemd/antiradio-ffmpeg.service"      "$SYSTEMD_DIR/"
cp -f "$TEMP_DIR/systemd/antiradio-nowplaying.service"   "$SYSTEMD_DIR/"
systemctl daemon-reload
log "Servicios systemd actualizados"

# --- 8. Verificar conexión con AzuraCast ---
echo ""
log "Verificando conexión con AzuraCast..."
API_RESPONSE="$(curl -fsSL --max-time 10 'https://radio.laantiradio.com/api/nowplaying/la_antiradio_youtube' 2>/dev/null || true)"

if [[ -n "$API_RESPONSE" ]]; then
  ARTIST="$(echo "$API_RESPONSE" | jq -r '.now_playing.song.artist // "?"')"
  TITLE="$(echo "$API_RESPONSE"  | jq -r '.now_playing.song.title // "?"')"
  log "API OK → Sonando ahora: $ARTIST - $TITLE"
else
  warn "No se pudo conectar con la API de AzuraCast. Comprueba la URL."
fi

AUDIO_STATUS="$(curl -sI --max-time 10 'https://radio.laantiradio.com/listen/la_antiradio_youtube/radio.mp3' 2>/dev/null | head -1 || true)"
if [[ "$AUDIO_STATUS" == *"200"* ]]; then
  log "Stream de audio OK (HTTP 200)"
else
  warn "El stream de audio no responde 200. Respuesta: $AUDIO_STATUS"
fi

# --- 9. Comprobar STREAM_KEY ---
CURRENT_KEY="$(grep -oP 'STREAM_KEY="\K[^"]+' "$INSTALL_DIR/ffmpeg.sh" || true)"
if [[ "$CURRENT_KEY" == "TU_STREAM_KEY" || -z "$CURRENT_KEY" ]]; then
  echo ""
  warn "⚠️  STREAM_KEY no configurada en ffmpeg.sh"
  warn "Edita $INSTALL_DIR/ffmpeg.sh y pon tu clave de YouTube Live:"
  warn "  nano $INSTALL_DIR/ffmpeg.sh"
  echo ""
fi

# --- 10. Limpiar ---
rm -rf "$TEMP_DIR"
log "Archivos temporales eliminados"

# --- Resumen ---
echo ""
echo "============================================="
echo "🎸 Despliegue completado"
echo "============================================="
echo ""
echo "Para iniciar los servicios:"
echo "  sudo systemctl start antiradio-nowplaying"
echo "  sudo systemctl start antiradio-ffmpeg"
echo ""
echo "Para ver los logs en directo:"
echo "  journalctl -u antiradio-nowplaying -f"
echo "  journalctl -u antiradio-ffmpeg -f"
echo ""
echo "Para activar inicio automático al arrancar:"
echo "  sudo systemctl enable antiradio-nowplaying antiradio-ffmpeg"
echo ""
if [[ "$CURRENT_KEY" == "TU_STREAM_KEY" || -z "$CURRENT_KEY" ]]; then
  echo -e "${YELLOW}⚠️  RECUERDA: configura tu STREAM_KEY en $INSTALL_DIR/ffmpeg.sh${NC}"
  echo ""
fi
