#!/usr/bin/env bash
set -euo pipefail

# Genera clips de 5 min (300s) a 1280x720 30fps desde imágenes/vídeos.
# - Incremental (solo convierte lo nuevo o modificado)
# - Vídeos SIN audio
# - Fade in/out suave para transiciones menos bruscas
#
# Entradas:  /opt/antiradio/backgrounds/*
# Salidas:   /opt/antiradio/bg_clips/*.mp4
# Lista:     /opt/antiradio/bg_concat.txt

SRC="/opt/antiradio/backgrounds"
OUT="/opt/antiradio/bg_clips"
LIST="/opt/antiradio/bg_concat.txt"

DUR=300
W=1280
H=720
FPS=30

FADE=1  # segundos de fade in/out

log(){ echo "[make_backgrounds] $*"; }

mkdir -p "$OUT"
: > "$LIST"

log "SRC=$SRC"
log "OUT=$OUT"
log "LIST=$LIST"
log "DUR=${DUR}s ${W}x${H} ${FPS}fps"

# Helper: compara timestamps (si out es más nuevo que src, se considera OK)
is_up_to_date() {
  local src="$1" out="$2"
  [[ -f "$out" ]] && [[ "$out" -nt "$src" ]]
}

make_from_image() {
  local src="$1" base="$2" out="$OUT/$base.mp4"
  if is_up_to_date "$src" "$out"; then
    log "OK (ya existe y está actualizado): $(basename "$out")"
  else
    log "-> imagen: $(basename "$src") => $(basename "$out")"
    ffmpeg -hide_banner -loglevel error -y \
      -loop 1 -t "$DUR" -i "$src" \
      -vf "scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=black,format=yuv420p,fade=t=in:st=0:d=${FADE},fade=t=out:st=$(($DUR-$FADE)):d=${FADE}" \
      -r "$FPS" -c:v libx264 -preset veryfast -crf 20 \
      -an \
      "$out"
  fi
  printf "file '%s'\n" "$out" >> "$LIST"
}

make_from_video() {
  local src="$1" base="$2" out="$OUT/$base.mp4"
  if is_up_to_date "$src" "$out"; then
    log "OK (ya existe y está actualizado): $(basename "$out")"
  else
    log "-> video: $(basename "$src") => $(basename "$out") (sin audio)"
    ffmpeg -hide_banner -loglevel error -y \
      -stream_loop -1 -i "$src" -t "$DUR" \
      -vf "scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=black,format=yuv420p,fade=t=in:st=0:d=${FADE},fade=t=out:st=$(($DUR-$FADE)):d=${FADE}" \
      -r "$FPS" -c:v libx264 -preset veryfast -crf 20 \
      -an \
      "$out"
  fi
  printf "file '%s'\n" "$out" >> "$LIST"
}

shopt -s nullglob
inputs=("$SRC"/*)
if [[ ${#inputs[@]} -eq 0 ]]; then
  log "No hay archivos en $SRC"
  exit 1
fi

log "Procesando imágenes..."
for f in "$SRC"/*.{png,jpg,jpeg,webp}; do
  [[ -f "$f" ]] || continue
  base="$(basename "${f%.*}")"
  make_from_image "$f" "$base"
done

log "Procesando vídeos..."
for f in "$SRC"/*.{mp4,mov,mkv,webm,avi}; do
  [[ -f "$f" ]] || continue
  base="$(basename "${f%.*}")"
  make_from_video "$f" "$base"
done

log "Listo. Clips en $OUT y lista en $LIST"
