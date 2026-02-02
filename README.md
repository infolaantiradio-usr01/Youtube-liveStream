# La Antiradio – VPS Ubuntu + YouTube 24/7

Este paquete contiene los scripts y servicios `systemd` para emitir una radio 24/7 desde Zeno.fm a YouTube Live, con overlay de Now Playing y carátula.

## Estructura
- `nowplaying.sh` → escucha metadatos (SSE) de Zeno, actualiza `nowplaying.txt` y `cover.jpg`
- `ffmpeg.sh` → genera vídeo 720p con overlay y lo envía por RTMP a YouTube
- `antiradio-nowplaying.service` → servicio systemd para nowplaying
- `antiradio-ffmpeg.service` → servicio systemd para ffmpeg

## Instalación rápida
1. Copia la carpeta `antiradio` a `/opt/antiradio` en tu VPS.
2. Copia `antiradio-nowplaying.service` a `/etc/systemd/system/antiradio-nowplaying.service`
3. Copia `antiradio-ffmpeg.service` a `/etc/systemd/system/antiradio-ffmpeg.service`
4. Edita `/opt/antiradio/ffmpeg.sh` y sustituye `TU_STREAM_KEY` por tu clave del evento de YouTube.
5. Permisos:
   - `chmod +x /opt/antiradio/nowplaying.sh /opt/antiradio/ffmpeg.sh`
6. Activar servicios:
   - `systemctl daemon-reload`
   - `systemctl enable --now antiradio-nowplaying.service`
   - `systemctl enable --now antiradio-ffmpeg.service`

## Logs
- `journalctl -u antiradio-nowplaying -f`
- `journalctl -u antiradio-ffmpeg -f`

## Notas sobre carátulas
Si Zeno no entrega URL de carátula, puedes usar carátulas locales:
- Guarda JPGs en `/opt/antiradio/covers/`
- Nombre del archivo = el texto de `nowplaying.txt` + `.jpg`
  Ejemplo: `NEBOXPOP - CICATRICES EN REVERSA.jpg`

Generado: 2026-02-01

