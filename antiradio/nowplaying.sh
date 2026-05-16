#!/usr/bin/env bash
set -euo pipefail

API_URL="https://radio.laantiradio.com/api/nowplaying/la_antiradio_youtube"
POLL_INTERVAL=5
DIR="/opt/antiradio"
ARTIST_FILE="${DIR}/artist.txt"
TITLE_FILE="${DIR}/title.txt"
GENRE_FILE="${DIR}/genre.txt"
COVER_FILE="${DIR}/cover.jpg"
LOGO_FILE="${DIR}/logo_fallback.jpg"
TMP_DIR="/tmp"
LAST_SONG_ID=""

mkdir -p "${DIR}"

write_atomic() {
  local value="$1" file="$2" tmp
  tmp="$(mktemp "${TMP_DIR}/antiradio.XXXXXX")"
  printf '%s' "$value" > "$tmp"
  mv -f "$tmp" "$file"
}

is_jpeg() {
  local f="$1"
  python3 - "$f" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
try:
    data = p.read_bytes()
except Exception:
    sys.exit(1)
if len(data) < 4:
    sys.exit(1)
if data[:2] != b'\xff\xd8' or data[-2:] != b'\xff\xd9':
    sys.exit(1)
sys.exit(0)
PY
}

use_logo() {
  cp -f "$LOGO_FILE" "$COVER_FILE" 2>/dev/null || true
}

fetch_cover() {
  local url="$1" tmp
  tmp="$(mktemp "${TMP_DIR}/antiradio-cover.XXXXXX.jpg")"
  if curl -fsSL --max-time 10 -o "$tmp" "$url"; then
    if is_jpeg "$tmp"; then
      mv -f "$tmp" "$COVER_FILE"
      return 0
    fi
  fi
  rm -f "$tmp"
  return 1
}

restart_ffmpeg() {
  echo "[nowplaying] Reiniciando FFmpeg para actualizar carátula..."
  systemctl restart antiradio-ffmpeg.service
}

echo "[nowplaying] consultando AzuraCast cada ${POLL_INTERVAL}s: ${API_URL}"

while true; do
  RESPONSE="$(curl -fsSL --max-time 10 "$API_URL" 2>/dev/null || true)"

  if [[ -n "${RESPONSE}" ]] && echo "${RESPONSE}" | jq -e '.now_playing.song' >/dev/null 2>&1; then
    SONG_ID="$(echo "${RESPONSE}" | jq -r '.now_playing.song.id // empty')"
    SONG_ARTIST="$(echo "${RESPONSE}" | jq -r '.now_playing.song.artist // "La Antiradio"' | tr -d '\r')"
    SONG_TITLE="$(echo "${RESPONSE}" | jq -r '.now_playing.song.title // "Live 24/7"' | tr -d '\r')"
    SONG_GENRE="$(echo "${RESPONSE}" | jq -r '.now_playing.song.genre // "ALTERNATIVE"' | tr -d '\r' | tr '[:lower:]' '[:upper:]')"
    SONG_ART="$(echo "${RESPONSE}" | jq -r '.now_playing.song.art // empty')"

    write_atomic "$SONG_ARTIST" "$ARTIST_FILE"
    write_atomic "$SONG_TITLE"  "$TITLE_FILE"
    write_atomic "$SONG_GENRE"  "$GENRE_FILE"

    # ── Actualizar carátula y reiniciar FFmpeg si cambió la canción ──
    if [[ -n "${SONG_ID}" && "${SONG_ID}" != "${LAST_SONG_ID}" ]]; then
      echo "[nowplaying] Nueva canción: ${SONG_ARTIST} — ${SONG_TITLE} (id=${SONG_ID})"

      if [[ -n "${SONG_ART}" ]]; then
        if fetch_cover "$SONG_ART"; then
          echo "[nowplaying] Carátula actualizada OK"
        else
          use_logo
          echo "[nowplaying] WARNING: cover fallido, usando logo"
        fi
      else
        use_logo
      fi

      restart_ffmpeg
      LAST_SONG_ID="${SONG_ID}"
    fi

  else
    write_atomic "La Antiradio"  "$ARTIST_FILE"
    write_atomic "Stream Offline" "$TITLE_FILE"
    write_atomic "LIVE"           "$GENRE_FILE"
    use_logo
  fi

  sleep "$POLL_INTERVAL"
done
