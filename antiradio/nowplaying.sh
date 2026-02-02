#!/usr/bin/env bash
set -euo pipefail

# Zeno mount (según tu emisora)
MOUNT="jkjslxjr7sntv"
META_URL="https://api.zeno.fm/mounts/metadata/subscribe/${MOUNT}"

# Rutas del proyecto
DIR="/opt/antiradio"
NOW_FILE="${DIR}/nowplaying.txt"
COVER_FILE="${DIR}/cover.jpg"
LOGO_FILE="${DIR}/logo.png"
LOCAL_COVERS_DIR="${DIR}/covers"

mkdir -p "$LOCAL_COVERS_DIR"

sanitize() {
  # Limpia caracteres raros para nombres de archivo y texto
  echo "$1" | tr -d '\r' | sed 's/[\/:*?"<>|]/_/g; s/  */ /g; s/^ *//; s/ *$//'
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

extract_image_url() {
  # Intenta encontrar un campo de imagen en el JSON (Zeno no siempre lo envía)
  jq -r '
    .image? // .imageUrl? // .artwork? // .artworkUrl? // .cover? // .coverUrl? //
    .thumbnail? // .thumbnailUrl? // .albumArt? // .albumArtUrl? // empty
  ' 2>/dev/null || true
}

last_key=""

echo "[nowplaying] leyendo metadatos de: $META_URL"

# Con -N mantenemos streaming SSE sin buffer
curl -fsSL -N "$META_URL" | while IFS= read -r line; do
  # Solo procesar líneas que empiecen por "data:"
  [[ "$line" == data:* ]] || continue

  # Quitar "data:" y posibles espacios
  json="${line#data:}"
  json="${json# }"

  # Obtener streamTitle (Zeno en tu caso envía este campo)
  streamTitle="$(echo "$json" | jq -r '.streamTitle // empty' 2>/dev/null || true)"
  streamTitle="$(echo "$streamTitle" | tr -d '\r')"

  # Si viene con guiones bajos, los cambiamos por espacios
  streamTitle_pretty="$(echo "$streamTitle" | sed 's/_/ /g')"

  # Quita sufijos tipo " (master).wav" y extensiones .wav/.mp3/.flac
  streamTitle_pretty="$(echo "$streamTitle_pretty" | sed -E 's/\s*\(.*\)\.(wav|mp3|flac)$//I; s/\.(wav|mp3|flac)$//I')"

  if [[ -n "$streamTitle_pretty" ]]; then
    display="$(sanitize "$streamTitle_pretty")"
  else
    display="La Antiradio · En directo"
  fi

  # Escribir nowplaying
  echo "$display" > "$NOW_FILE"

  # Solo actualizar carátula si cambió el tema
  key="$(echo "$display" | tr '[:upper:]' '[:lower:]')"
  if [[ "$key" != "$last_key" ]]; then
    got_cover=0

    # 1) Si viniera URL de imagen en el JSON (normalmente no en tu caso, pero queda preparado)
    img_url="$(echo "$json" | extract_image_url)"
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
  fi
done

