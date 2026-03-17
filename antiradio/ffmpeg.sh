#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
AZURACAST_URL="https://radio.laantiradio.com/listen/la_antiradio_youtube/radio.mp3"
BG_LIST="/opt/antiradio/bg_concat.txt"
NOW_FILE="/opt/antiradio/nowplaying.txt"
COVER_FILE="/opt/antiradio/cover.jpg"

# IMPORTANTE: tu clave actual
STREAM_KEY="TU_STREAM_KEY"
RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# Calidad
VBITRATE="1800k"
ABITRATE="160k"

exec ffmpeg -hide_banner -loglevel info \
  -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10 \
  -i "${AZURACAST_URL}" \
  -stream_loop -1 -safe 0 -f concat -i "${BG_LIST}" \
  -f image2 -loop 1 -i "${COVER_FILE}" \
  -filter_complex "\
    [1:v]scale=1280:720,format=yuv420p[vid_bg]; \
    [2:v]scale=230:230:force_original_aspect_ratio=decrease,pad=230:230:(ow-iw)/2:(oh-ih)/2:color=black@0[cover]; \
    [vid_bg][cover]overlay=40:H-h-40:eof_action=pass[bg_out]; \
    [bg_out]drawtext=fontfile=${FONT}:textfile=${NOW_FILE}:reload=1: \
      fontcolor=white:fontsize=32: \
      shadowcolor=black@0.9:shadowx=2:shadowy=2: \
      x=40+230+25:y=h-th-95: \
      box=1:boxcolor=0x1a1a1a@0.85:boxborderw=18[out_v] \
  " \
  -map "[out_v]" -map 0:a \
  -c:v libx264 -preset veryfast -profile:v high -level 4.1 \
  -r 30 -g 60 -keyint_min 60 -sc_threshold 0 \
  -b:v "${VBITRATE}" -maxrate "${VBITRATE}" -bufsize 3600k \
  -c:a aac -b:a "${ABITRATE}" -ar 44100 -ac 2 \
  -f flv "${RTMP_URL}"
