[![Docker Hub](https://img.shields.io/docker/v/dasaod/flac2mp3?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/dasaod/flac2mp3)
# flac2mp3-watcher

> **📌 Mirror-Hinweis:** Dieses Repository ist ein automatischer Spiegel.
> Die primäre Entwicklung findet auf **[git.uliana.de/DasAoD/flac2mp3](https://git.uliana.de/DasAoD/flac2mp3)** statt.
> Issues und Pull Requests bitte dort öffnen.


A lightweight Docker container that watches a directory tree for FLAC files and automatically converts them to MP3 (320k CBR) in-place. The source FLAC file is deleted after a successful conversion.

Built on Alpine Linux with `ffmpeg` and `inotify-tools`. Unraid-friendly (runs as UID 99 / GID 100).

Docker Hub: [dasaod/flac2mp3](https://hub.docker.com/r/dasaod/flac2mp3)

---

## Features

- Watches recursively via `inotify` — reacts immediately, no polling
- Converts FLAC → MP3 at 320k CBR, preserving metadata tags
- Deletes the original FLAC after a successful conversion
- Initial scan on startup (converts any existing FLAC files)
- Skips files where an up-to-date MP3 already exists
- Log rotation (configurable size and number of backups)
- Healthcheck: verifies `inotifywait` is running
- Unraid-friendly: runs as `nobody:users` (99:100), respects umask

---

## Quick Start

```bash
docker run -d \
  --name flac2mp3-watcher \
  -e ROOT=/media \
  -v /path/to/your/music:/media \
  -v /path/to/appdata/flac2mp3:/config \
  dasaod/flac2mp3:latest
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ROOT` | `/media` | Directory to watch |
| `UMASK_VAL` | `002` | File creation umask |
| `LOGFILE` | `/config/flac2mp3-watcher.log` | Log file path |
| `LOG_MAX_MB` | `10` | Max log size in MB |
| `LOG_BACKUPS` | `3` | Number of rotated log files to keep |

---

## Changelog

### 1.2
- Fix: log rotation now called on every log entry
- Fix: relative paths from inotify always resolved to absolute
- Improved: case-insensitive FLAC extension matching

### 1.1
- Added log rotation
- Added Healthcheck

### 1.0
- Initial release

---

## Mitwirkende

Dieses Projekt wurde in Zusammenarbeit mit [Claude](https://claude.ai) (Sonnet 4.6) von [Anthropic](https://anthropic.com) entwickelt und iterativ ausgebaut.  
Der überwiegende Teil des Codes, der Architektur und der Dokumentation wurde durch KI generiert und gemeinsam verfeinert.

| Rolle | Person / Tool |
|---|---|
| Projektidee, Anforderungen & Tests | [DasAoD](https://git.uliana.de/DasAoD) |
| Code, Architektur, Dokumentation | [Claude](https://git.uliana.de/Claude) (Anthropic) |

## License

[MIT](LICENSE)
