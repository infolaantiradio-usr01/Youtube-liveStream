#!/usr/bin/env bash
set -euo pipefail

# AzuraCast API – Now Playing
API_URL="https://radio.laantiradio.com/api/nowplaying/la_antiradio_youtube"
POLL_INTERVAL=15   # segundos entre consultas

# Rutas del proyecto
DIR="/opt/antiradio"
ARTIST_FILE="${DIR}/artist.txt"
TITLE_FILE="${DIR}/title.txt"
COVER_FILE="${DIR}/cover.jpg"
LOGO_FILE="${DIR}/logo.png"

mkdir -p "${DIR}"

echo "[nowplaying] consultando AzuraCast cada ${POLL_INTERVAL}s: $API_URL"

while true; do
  # Obtener JSON de la API de AzuraCast
  RESPONSE="$(curl -sL --max-time 10 "$API_URL" || true)"

  if [[ -n "${RESPONSE}" ]] && echo "${RESPONSE}" | jq -e '.now_playing.song' >/dev/null 2>&1; then
    SONG_ARTIST=$(echo "${RESPONSE}" | jq -r '.now_playing.song.artist // "La Antiradio"')
    SONG_TITLE=$(echo "${RESPONSE}" | jq -r '.now_playing.song.title // "Live 24/7"')
    SONG_ART=$(echo "${RESPONSE}" | jq -r '.now_playing.song.art // empty')

    # Limpiar y separar
    SONG_ARTIST="$(echo "$SONG_ARTIST" | tr -d '\r')"
    SONG_TITLE="$(echo "$SONG_TITLE" | tr -d '\r')"

    # Guardamos en archivos separados para que FFmpeg les dé formatos distintos
    echo -n "${SONG_ARTIST}" > "${ARTIST_FILE}"
    echo -n "${SONG_TITLE}" > "${TITLE_FILE}"

    if [[ -n "${SONG_ART}" ]]; then
      TMP_COVER="/tmp/antiradio_cover_$$.jpg"
      curl -sL --max-time 10 -o "${TMP_COVER}" "${SONG_ART}" || rm -f "${TMP_COVER}"
      if [[ -s "${TMP_COVER}" ]]; then
        mv -f "${TMP_COVER}" "${COVER_FILE}"
      fi
    else
      cp "${LOGO_FILE}" "${COVER_FILE}" || true
    fi
  else
    echo -n "La Antiradio" > "${ARTIST_FILE}"
    echo -n "Stream Offline" > "${TITLE_FILE}"
    cp "${LOGO_FILE}" "${COVER_FILE}" || true
  fi

  sleep "$POLL_INTERVAL"
done
