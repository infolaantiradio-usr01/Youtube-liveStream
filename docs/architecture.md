# Arquitectura del sistema

Este proyecto convierte un stream de audio (AzuraCast) en una emisión de vídeo 24/7 en YouTube.

## Flujo general
1. Audio entra desde AzuraCast (Icecast/Liquidsoap)
2. Now Playing se consulta cada 15s vía API REST de AzuraCast
3. FFmpeg mezcla audio + logo + carátula + texto y emite a YouTube
4. systemd mantiene todo vivo

## Componentes
- FFmpeg
- systemd
- Bash scripts
- AzuraCast API
- YouTube RTMP
