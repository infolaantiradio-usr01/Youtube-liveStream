#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
AZURACAST_URL="https://radio.laantiradio.com/listen/la_antiradio_youtube/radio.mp3"
BG_LIST="/opt/antiradio/bg_concat.txt"
ARTIST_FILE="/opt/antiradio/artist.txt"
TITLE_FILE="/opt/antiradio/title.txt"
COVER_FILE="/opt/antiradio/cover.jpg"
GENRE_FILE="/opt/antiradio/genre.txt"
LIVE_FILE="/opt/antiradio/live_label.txt"
URL_FILE="/opt/antiradio/url_label.txt"

# IMPORTANTE: tu clave actual
STREAM_KEY="TU_STREAM_KEY"
RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD_FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

VBITRATE="1800k"
ABITRATE="160k"

# ── Archivos de arranque (evitan crash si nowplaying no ha arrancado aún) ──
echo -n "La Antiradio" > "${ARTIST_FILE}"
echo -n "Iniciando..."  > "${TITLE_FILE}"
echo -n "LIVE"          > "${GENRE_FILE}"
echo -n "EN DIRECTO"    > "${LIVE_FILE}"
echo -n "laantiradio.com" > "${URL_FILE}"

if [ ! -f "$BOLD_FONT" ]; then BOLD_FONT="$FONT"; fi

# ── Posiciones clave (frame 1280x720) ──
# Cover: 246×246px (240 + 6px borde rojo). Posición: x=50, y=H-h-95
# Área de texto: x=316 (50+246+20), ocupando hasta aprox. x=970
# Panel oscuro: y=H-250 a y=H-60 (cubre texto + deja hueco al waveform)
# Waveform: y=H-50 a y=H (franja de 50px en el fondo)

exec ffmpeg -hide_banner -loglevel warning \
  -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10 \
  -i "${AZURACAST_URL}" \
  -stream_loop -1 -safe 0 -f concat -i "${BG_LIST}" \
  -f image2 -loop 1 -i "${COVER_FILE}" \
  -filter_complex "\
    [1:v]scale=1280:720,format=yuv420p[vid_bg]; \
    [2:v]scale=240:240:force_original_aspect_ratio=decrease,pad=240:240:(ow-iw)/2:(oh-ih)/2:color=black@0[cover_sc]; \
    [cover_sc]pad=iw+6:ih+6:3:3:color=0xe01a2b[cover_bd]; \
    [vid_bg][cover_bd]overlay=50:H-h-95:eof_action=pass[bg_cov]; \
    [bg_cov]drawbox=x=316:y=H-250:w=660:h=195:color=black@0.55:t=fill[bg_pan]; \
    [bg_pan]drawtext=fontfile=${BOLD_FONT}:textfile=${ARTIST_FILE}:reload=1:\
fontcolor=white:fontsize=52:\
shadowcolor=black@0.9:shadowx=3:shadowy=3:\
x=326:y=H-th-195[txt_ar]; \
    [txt_ar]drawbox=x=326:y=H-138:w=550:h=2:color=0xe01a2b:t=fill[sep]; \
    [sep]drawtext=fontfile=${FONT}:textfile=${TITLE_FILE}:reload=1:\
fontcolor=0xdddddd:fontsize=30:\
shadowcolor=black@0.9:shadowx=2:shadowy=2:\
x=326:y=H-th-125[txt_ti]; \
    [txt_ti]drawtext=fontfile=${BOLD_FONT}:textfile=${GENRE_FILE}:reload=1:\
fontcolor=white:fontsize=16:\
box=1:boxcolor=0xe01a2b@0.30:boxborderw=6:\
x=326:y=H-88[txt_ge]; \
    [txt_ge]drawtext=fontfile=${BOLD_FONT}:textfile=${LIVE_FILE}:reload=0:\
fontcolor=white:fontsize=17:\
box=1:boxcolor=black@0.75:boxborderw=9:\
x=W-tw-25:y=18[txt_lv]; \
    [txt_lv]drawtext=fontfile=${FONT}:textfile=${URL_FILE}:reload=0:\
fontcolor=white@0.30:fontsize=14:\
x=15:y=15[txt_wm]; \
    [0:a]showwaves=s=1280x50:mode=cline:rate=30:colors=0xe01a2b[waves]; \
    [txt_wm][waves]overlay=x=0:y=H-h[out_v] \
  " \
  -map "[out_v]" -map 0:a \
  -c:v libx264 -preset veryfast -profile:v high -level 4.1 \
  -r 30 -g 60 -keyint_min 60 -sc_threshold 0 \
  -b:v "${VBITRATE}" -maxrate "${VBITRATE}" -bufsize 3600k \
  -c:a aac -b:a "${ABITRATE}" -ar 44100 -ac 2 \
  -f flv "${RTMP_URL}"
