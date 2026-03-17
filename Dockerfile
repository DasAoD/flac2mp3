# dasaod/flac2mp3:1.2
FROM alpine:3.20

ENV ROOT=/media \
    UMASK_VAL=002 \
    LOGFILE=/config/flac2mp3-watcher.log \
    LOG_MAX_MB=10 \
    LOG_BACKUPS=3

RUN apk add --no-cache bash coreutils ffmpeg inotify-tools su-exec

WORKDIR /app
COPY watcher.sh /app/watcher.sh
RUN chmod +x /app/watcher.sh

USER 99:100

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD pgrep inotifywait >/dev/null || exit 1

ENTRYPOINT ["/bin/bash","/app/watcher.sh"]

# --- Metadata Labels (OCI) ---
LABEL org.opencontainers.image.title="flac2mp3-watcher"
LABEL org.opencontainers.image.description="Überwacht einen Ordner (inotify) und konvertiert FLAC zu MP3 (320k) in-place. Löscht Quell-Datei nach Erfolg. Unraid-friendly (UID 99/GID 100), Logrotation."
LABEL org.opencontainers.image.version="1.2"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/dasaod/flac2mp3"
LABEL org.opencontainers.image.documentation="https://hub.docker.com/r/dasaod/flac2mp3"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="DasAoD <das.aod@gmail.com>"

# Optional: Icon (später ersetzen)
LABEL org.opencontainers.image.vendor="dasaod"
LABEL org.opencontainers.image.ref.name="dasaod/flac2mp3"
LABEL org.opencontainers.image.base.name="alpine:3.20"
LABEL org.opencontainers.image.revision="1.2.0"
LABEL org.opencontainers.image.created="2025-11-06T23:03:00Z"
