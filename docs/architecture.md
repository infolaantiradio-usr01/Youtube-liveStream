# Arquitectura del sistema

Este proyecto convierte un stream de audio (Zeno.fm) en una emisión de vídeo 24/7 en YouTube.

## Flujo general
1. Audio entra desde Zeno
2. Fondos de vídeo se generan y concatenan
3. Now Playing se actualiza en tiempo real
4. FFmpeg mezcla todo y emite a YouTube
5. systemd mantiene todo vivo

## Componentes
- FFmpeg
- systemd
- Bash scripts
- YouTube RTMP
