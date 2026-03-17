#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
# Audio desde AzuraCast (Youtube Radio)
AZURACAST_URL="https://radio.laantiradio.com/listen/la_antiradio_youtube/radio.mp3"

BG_LIST="/opt/antiradio/bg_concat.txt"
NOW_FILE="/opt/antiradio/nowplaying.txt"
COVER_FILE="/opt/antiradio/cover.jpg"
LOGO_FILE="/opt/antiradio/logo.png"

# IMPORTANTE: pon aquí tu stream key
STREAM_KEY="TU_STREAM_KEY"
RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"

FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# Calidad
VBITRATE="1800k"
ABITRATE="160k"

# ====== FFmpeg ======
exec ffmpeg -hide_banner -loglevel info \
  -thread_queue_size 1024 \
  -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10 \
  -i "${AZURACAST_URL}" \
  -thread_queue_size 1024 \
  -stream_loop -1 -safe 0 -f concat -i "${BG_LIST}" \
  -stream_loop -1 -re -f image2 -framerate 1 -i "${COVER_FILE}" \
  -loop 1 -i "${LOGO_FILE}" \
  -filter_complex "\
    [1:v]scale=1280:720,format=yuv420p[bg]; \
    [2:v]scale=220:220:force_original_aspect_ratio=decrease,pad=220:220:(ow-iw)/2:(oh-ih)/2:color=black@0[cover]; \
    [3:v]scale=-1:-1[logo]; \
    [bg][logo]overlay=W-w-20:20[bg_logo]; \
    [bg_logo][cover]overlay=40:H-h-40[bg_vid]; \
    [bg_vid]drawtext=fontfile=${FONT}:textfile=${NOW_FILE}:reload=1: \
      fontcolor=white:fontsize=34: \
      x=40+220+18:y=h-th-40: \
      box=1:boxcolor=black@0.6:boxborderw=18[v] \
  " \
  -map "[v]" -map 0:a \
  -c:v libx264 -preset veryfast -profile:v high -level 4.1 \
  -r 30 -g 60 -keyint_min 60 -sc_threshold 0 \
  -b:v "${VBITRATE}" -minrate "${VBITRATE}" -maxrate "${VBITRATE}" -bufsize 3600k \
  -pix_fmt yuv420p \
  -c:a aac -b:a "${ABITRATE}" -ar 44100 -ac 2 \
  -flvflags no_duration_filesize \
  -f flv "${RTMP_URL}"
