# flac2mp3 (flac2mp3-watcher) – Projektkontext für Claude Code

Leichtgewichtiger Docker-Container, der ein Verzeichnis rekursiv auf FLAC-Dateien überwacht und diese automatisch in-place zu MP3 (320k CBR) konvertiert. Die Quell-FLAC-Datei wird nach erfolgreicher Konvertierung gelöscht.

## Tech-Stack
- Alpine Linux, `ffmpeg`, `inotify-tools`
- Unraid-freundlich: läuft als UID 99 / GID 100 (`nobody:users`)
- Docker Hub: `dasaod/flac2mp3`

## Funktionsweise
- Überwacht rekursiv via `inotify` – reagiert sofort, kein Polling
- Konvertiert FLAC → MP3 bei 320k CBR, erhält Metadata-Tags
- Löscht das Original-FLAC nach erfolgreicher Konvertierung
- Initialer Scan beim Start (konvertiert bestehende FLAC-Dateien)
- Überspringt Dateien, wenn bereits eine aktuelle MP3 existiert
- Log-Rotation (konfigurierbare Größe/Anzahl Backups)
- Healthcheck prüft, ob `inotifywait` läuft

## Environment-Variablen
| Variable | Default | Beschreibung |
|---|---|---|
| `ROOT` | `/media` | Zu überwachendes Verzeichnis |
| `UMASK_VAL` | `002` | Umask für neue Dateien |
| `LOGFILE` | `/config/flac2mp3-watcher.log` | Log-Pfad |
| `LOG_MAX_MB` | `10` | Max. Log-Größe in MB |
| `LOG_BACKUPS` | `3` | Anzahl rotierter Log-Dateien |

## Quick Start
```bash
docker run -d \
  --name flac2mp3-watcher \
  -e ROOT=/media \
  -v /path/to/your/music:/media \
  -v /path/to/appdata/flac2mp3:/config \
  dasaod/flac2mp3:latest
```

## Wichtige Konventionen
- CI (Forgejo Actions) baut nur bei Änderungen an `Dockerfile` und `watcher.sh` – bei Änderungen an diesen Dateien Versionsnummer im Changelog konsequent hochzählen (aktuell v0.1.6)
- Case-insensitive FLAC-Extension-Matching beibehalten
- Relative Pfade aus inotify-Events müssen immer zu absoluten Pfaden aufgelöst werden (war ein früherer Bugfix, Regression vermeiden)
- Log-Rotation muss bei jedem Log-Eintrag geprüft werden, nicht nur periodisch
