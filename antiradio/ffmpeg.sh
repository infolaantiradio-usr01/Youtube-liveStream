#!/usr/bin/env bash
set -euo pipefail

# IMPORTANTE:
# - No guardes tu clave real en un lugar público.
# - Sustituye TU_STREAM_KEY por la clave del evento de YouTube Live.
STREAM_KEY="TU_STREAM_KEY"
RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"

# Audio desde Zeno
ZENO_URL="https://stream.zeno.fm/jkjslxjr7sntv"

# Archivos generados por nowplaying.sh
LOGO="/opt/antiradio/logo.png"
COVER="/opt/antiradio/cover.jpg"
NOW="/opt/antiradio/nowplaying.txt"

exec ffmpeg \
-hide_banner -loglevel info \
-reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10 \
-i "${ZENO_URL}" \
-loop 1 -i "${LOGO}" \
-loop 1 -i "${COVER}" \
-filter_complex "\
[1:v]scale=1280:720,format=yuv420p[bg];\
[2:v]scale=220:220:force_original_aspect_ratio=decrease,\
pad=220:220:(ow-iw)/2:(oh-ih)/2:color=black@0[cover];\
[bg][cover]overlay=40:H-h-40[vid];\
[vid]drawtext=textfile=${NOW}:reload=1:fontcolor=white:fontsize=34:x=40+220+18:y=h-th-40:box=1:boxcolor=black@0.6:boxborderw=18[v]" \
-map "[v]" -map 0:a \
-c:v libx264 -preset veryfast -tune stillimage \
-profile:v high -level 4.1 -r 30 -g 60 -keyint_min 60 \
-b:v 1800k -maxrate 1800k -bufsize 3600k \
-c:a aac -b:a 160k -ar 44100 -ac 2 \
-f flv "${RTMP_URL}"

