#!/usr/bin/env bash
set -euo pipefail

# AzuraCast API – Now Playing
API_URL="https://radio.laantiradio.com/api/nowplaying/la_antiradio"
POLL_INTERVAL=15   # segundos entre consultas

# Rutas del proyecto
DIR="/opt/antiradio"
NOW_FILE="${DIR}/nowplaying.txt"
COVER_FILE="${DIR}/cover.jpg"
LOGO_FILE="${DIR}/logo.png"
LOCAL_COVERS_DIR="${DIR}/covers"

mkdir -p "$LOCAL_COVERS_DIR"

sanitize() {
  # Limpia caracteres raros para nombres de archivo y texto
  echo "$1" | tr -d '\r' | sed 's/[\\/:*?"<>|]/_/g; s/  */ /g; s/^ *//; s/ *$//'
}

set_default_cover() {
  cp -f "$LOGO_FILE" "$COVER_FILE"
}

download_cover() {
  local url="$1"
  local tmp="${COVER_FILE}.tmp"
  if curl -fsSL --max-time 15 "$url" -o "$tmp"; then
    mv -f "$tmp" "$COVER_FILE"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

last_key=""

echo "[nowplaying] consultando AzuraCast cada ${POLL_INTERVAL}s: $API_URL"

while true; do
  # Obtener JSON de la API de AzuraCast
  json="$(curl -fsSL --max-time 10 "$API_URL" 2>/dev/null || true)"

  if [[ -z "$json" ]]; then
    echo "[nowplaying] sin respuesta de la API, reintentando..."
    sleep "$POLL_INTERVAL"
    continue
  fi

  # Extraer artista y título
  artist="$(echo "$json" | jq -r '.now_playing.song.artist // empty' 2>/dev/null || true)"
  title="$(echo "$json"  | jq -r '.now_playing.song.title // empty'  2>/dev/null || true)"

  # Limpiar
  artist="$(echo "$artist" | tr -d '\r')"
  title="$(echo "$title" | tr -d '\r')"

  # Componer texto para pantalla
  if [[ -n "$artist" && -n "$title" ]]; then
    display="$(sanitize "$artist - $title")"
  elif [[ -n "$title" ]]; then
    display="$(sanitize "$title")"
  elif [[ -n "$artist" ]]; then
    display="$(sanitize "$artist")"
  else
    display="La Antiradio · En directo"
  fi

  # Escribir nowplaying
  echo "$display" > "$NOW_FILE"

  # Solo actualizar carátula si cambió el tema
  key="$(echo "$display" | tr '[:upper:]' '[:lower:]')"
  if [[ "$key" != "$last_key" ]]; then
    got_cover=0

    # 1) Carátula desde AzuraCast (siempre disponible)
    img_url="$(echo "$json" | jq -r '.now_playing.song.art // empty' 2>/dev/null || true)"
    if [[ -n "$img_url" ]]; then
      if download_cover "$img_url"; then
        got_cover=1
      fi
    fi

    # 2) Carátula local (opcional) basada en el display
    #    Guarda tus portadas aquí: /opt/antiradio/covers/<display>.jpg
    if [[ "$got_cover" -eq 0 ]]; then
      local_name="$(sanitize "$display").jpg"
      local_path="${LOCAL_COVERS_DIR}/${local_name}"
      if [[ -f "$local_path" ]]; then
        cp -f "$local_path" "$COVER_FILE"
        got_cover=1
      fi
    fi

    # 3) Fallback: logo
    if [[ "$got_cover" -eq 0 ]]; then
      set_default_cover
    fi

    last_key="$key"
    echo "[nowplaying] ♪ $display"
  fi

  sleep "$POLL_INTERVAL"
done
