#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
AZURACAST_URL="https://radio.laantiradio.com/listen/la_antiradio_youtube/radio.mp3"
BG_LIST="/opt/antiradio/bg_concat.txt"
ARTIST_FILE="/opt/antiradio/artist.txt"
TITLE_FILE="/opt/antiradio/title.txt"
COVER_FILE="/opt/antiradio/cover.jpg"

# IMPORTANTE: tu clave actual
STREAM_KEY="TU_STREAM_KEY"
RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD_FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

VBITRATE="1800k"
ABITRATE="160k"

# Creamos temporalmente estos archivos para que FFmpeg no crashee en el arranque
echo "La Antiradio" > "${ARTIST_FILE}"
echo "Iniciando..." > "${TITLE_FILE}"

# Intentamos usar la BOLD, pero si el sistema no la tiene FFmpeg usa la normal sin fallar
if [ ! -f "$BOLD_FONT" ]; then BOLD_FONT="$FONT"; fi

exec ffmpeg -hide_banner -loglevel warning \
  -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10 \
  -i "${AZURACAST_URL}" \
  -stream_loop -1 -safe 0 -f concat -i "${BG_LIST}" \
  -f image2 -loop 1 -i "${COVER_FILE}" \
  -filter_complex "\
    [1:v]scale=1280:720,format=yuv420p[vid_bg]; \
    [2:v]scale=230:230:force_original_aspect_ratio=decrease,pad=230:230:(ow-iw)/2:(oh-ih)/2:color=black@0[cover]; \
    [cover]pad=iw+10:ih+10:5:5:color=gray@0.8[cover_border]; \
    [vid_bg][cover_border]overlay=50:H-h-50:eof_action=pass[bg_out]; \
    [bg_out]drawtext=fontfile=${BOLD_FONT}:textfile=${ARTIST_FILE}:reload=1: \
      fontcolor=white:fontsize=46: \
      shadowcolor=black@0.9:shadowx=3:shadowy=3: \
      x=50+240+20:y=H-th-135[txt_artist]; \
    [txt_artist]drawtext=fontfile=${FONT}:textfile=${TITLE_FILE}:reload=1: \
      fontcolor=0xcccccc:fontsize=32: \
      bordercolor=black:borderw=1: \
      shadowcolor=black@0.9:shadowx=2:shadowy=2: \
      x=50+240+22:y=H-th-95[out_v] \
  " \
  -map "[out_v]" -map 0:a \
  -c:v libx264 -preset veryfast -profile:v high -level 4.1 \
  -r 30 -g 60 -keyint_min 60 -sc_threshold 0 \
  -b:v "${VBITRATE}" -maxrate "${VBITRATE}" -bufsize 3600k \
  -c:a aac -b:a "${ABITRATE}" -ar 44100 -ac 2 \
  -f flv "${RTMP_URL}"
