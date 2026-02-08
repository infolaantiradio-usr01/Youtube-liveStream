# 🎸 La Antiradio – YouTube Live Stream (v1.1)

Sistema de emisión **24/7** para **La Antiradio**, basado en **FFmpeg + systemd**, que convierte un stream de audio en una emisión de YouTube con fondos dinámicos y Now Playing en tiempo real.

---

## 🚀 Qué hace este sistema

- 📡 Toma audio en directo desde Zeno.fm  
- 🎥 Genera vídeos de fondo dinámicos (imágenes y vídeos)
- ⏱️ Convierte todo a clips de **5 minutos**
- 🔀 Concatena los fondos automáticamente
- 🎵 Muestra **NOW PLAYING** en tiempo real
- 🔁 Funciona 24/7 con auto-restart (systemd)

---

## 📂 Estructura en el VPS

```text
/opt/antiradio/
├── backgrounds/
├── bg_clips/
├── covers/
├── bg_concat.txt
├── cover.jpg
├── nowplaying.txt
├── logo.png
├── ffmpeg.sh
├── nowplaying.sh
└── make_backgrounds.sh
```

---

## 🎥 Fondos dinámicos (clips de 5 minutos)

### Añadir nuevos fondos

1. Copia imágenes o vídeos a:
```bash
/opt/antiradio/backgrounds/
```

2. Ejecuta:
```bash
sudo /opt/antiradio/make_backgrounds.sh
```

✔ Script incremental  
✔ Sin audio en los fondos  
✔ No borra clips existentes  

---

## 🎵 Now Playing

- Actualiza metadatos en caliente
- Texto animado tipo directo
- Sin cortes de emisión

Archivo:
```bash
/opt/antiradio/nowplaying.txt
```

---

## 🔧 Servicios systemd

```bash
sudo systemctl start antiradio-ffmpeg
sudo systemctl stop antiradio-ffmpeg
sudo systemctl restart antiradio-ffmpeg
journalctl -u antiradio-ffmpeg -f
```

---

## 🏷️ Versiones

- v1.0 – Base funcional  
- v1.1 – Fondos dinámicos + Now Playing mejorado  

---

## 🎸 La Antiradio

Radio viva.  
Rock, ruido y verdad.
