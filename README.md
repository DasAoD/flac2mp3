# flac2mp3-watcher

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
| `ROOT` | `/media` | Directory to watch (must be mounted) |
| `UMASK_VAL` | `002` | File creation umask |
| `LOGFILE` | `/config/flac2mp3-watcher.log` | Log file path |
| `LOG_MAX_MB` | `10` | Max log size in MB before rotation |
| `LOG_BACKUPS` | `3` | Number of rotated log files to keep |

---

## Volumes

| Container path | Purpose |
|----------------|---------|
| `/media` | Music directory to watch (mount your FLAC folder here) |
| `/config` | Log file storage |

---

## Unraid Template

```
Repository:   dasaod/flac2mp3:latest
Network:      Bridge

Volumes:
  /path/to/music        → /media   (RW)
  /mnt/user/appdata/flac2mp3 → /config  (RW)

Environment:
  ROOT        = /media
  UMASK_VAL   = 002
  LOGFILE     = /config/flac2mp3-watcher.log
  LOG_MAX_MB  = 10
  LOG_BACKUPS = 3
```

---

## Build

```bash
# Build locally
docker build -t dasaod/flac2mp3:1.2 -t dasaod/flac2mp3:latest .

# Push to Docker Hub
docker push dasaod/flac2mp3:1.2
docker push dasaod/flac2mp3:latest
```

---

## How It Works

1. On startup, an initial scan converts all existing `.flac` files under `ROOT`
2. `inotifywait` then watches for new or updated files (`CLOSE_WRITE`, `CREATE`, `MOVED_TO`)
3. When a `.flac` file is detected, `ffmpeg` converts it to `.mp3` (320k CBR) in the same directory
4. On success, the original `.flac` is deleted
5. Log rotation runs automatically when the log exceeds `LOG_MAX_MB`

---

## Changelog

### 1.2
- Fix: log rotation now called on every log entry
- Fix: relative paths from inotify always resolved to absolute
- Improved: case-insensitive FLAC extension matching via `nocasematch`

### 1.1
- Added log rotation (`LOG_MAX_MB`, `LOG_BACKUPS`)
- Added Dockerfile with embedded `watcher.sh` (no install on start)
- Added Healthcheck
- Improved path handling

### 1.0
- Initial release

---

## License

MIT
