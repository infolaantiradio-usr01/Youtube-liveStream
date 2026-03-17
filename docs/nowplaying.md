# Now Playing

El script nowplaying.sh:
- Consulta la API REST de AzuraCast cada 15 segundos
- Extrae artista, título y URL de carátula del JSON
- Escribe el tema actual en nowplaying.txt
- Descarga la carátula automáticamente en cover.jpg

FFmpeg lo lee en caliente y lo muestra en pantalla.
