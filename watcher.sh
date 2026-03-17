#!/bin/bash
# flac2mp3-watcher v1.2 – Unraid-friendly: FLAC -> MP3 (320k), delete source, logrotate
set -euo pipefail

VERSION="1.2"

ROOT="${ROOT:-/media}"
UMASK_VAL="${UMASK_VAL:-002}"
LOGFILE="${LOGFILE:-/config/flac2mp3-watcher.log}"
LOG_MAX_MB="${LOG_MAX_MB:-10}"
LOG_BACKUPS="${LOG_BACKUPS:-3}"

umask "$UMASK_VAL"

log(){
  rotate_logs
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOGFILE"
}

rotate_logs(){
  [[ -f "$LOGFILE" ]] || return 0
  local size_kb max_kb
  size_kb=$(du -k "$LOGFILE" | awk '{print $1}')
  max_kb=$(( LOG_MAX_MB * 1024 ))
  if (( size_kb > max_kb )); then
    for ((i=LOG_BACKUPS-1; i>=1; i--)); do
      [[ -f "${LOGFILE}.${i}" ]] && mv -f "${LOGFILE}.${i}" "${LOGFILE}.$((i+1))" || true
    done
    mv -f "$LOGFILE" "${LOGFILE}.1"
    : > "$LOGFILE"
  fi
}

#abspath(){ [[ "$1" = /* ]] && echo "$1" || echo "${ROOT%/}/$1"; }
mp3_of(){ local f="$1"; echo "${f%.flac}.mp3"; }

mkdir -p "$(dirname "$LOGFILE")"; chmod 775 "$(dirname "$LOGFILE")" || true
mkdir -p "$ROOT"; chmod 2775 "$ROOT" || true

log "flac2mp3-watcher startet – Version $VERSION"
log "ROOT=$ROOT  UMASK=$UMASK_VAL  LOGFILE=$LOGFILE  MAX_MB=$LOG_MAX_MB  BACKUPS=$LOG_BACKUPS"

nice="nice -n 5"; ionice="ionice -c2 -n4"

convert_one(){
  local src="$1"
  # Safety-Guard: immer absolut machen
  [[ "$src" = /* ]] || src="$ROOT/${src#./}"

  local dst tmp
  dst="$(mp3_of "$src")"
  tmp="${dst}.tmp.mp3"

  # Zielverzeichnis absichern (setgid für Gruppe users)
  install -d -m 2775 -o 99 -g 100 "$(dirname "$dst")"

  # Überspringen, wenn MP3 existiert und neuer ist
  if [[ -f "$dst" && "$dst" -nt "$src" ]]; then
    log "Skip (aktuell): $dst"
    return 0
  fi

  log "Konvertiere: $src -> $dst"
  if ${ionice} ${nice} ffmpeg -hide_banner -loglevel error -y \
       -i "$src" -map_metadata 0 -c:a libmp3lame -b:a 320k -vn "$tmp"; then
    touch -r "$src" "$tmp"
    chown 99:100 "$tmp"; chmod 664 "$tmp"
    mv -f "$tmp" "$dst"
    rm -f -- "$src"
    log "OK & gelöscht: $dst"
  else
    log "FEHLER: $src"
    rm -f -- "$tmp" 2>/dev/null || true
    return 1
  fi
}

initial_scan(){
  log "Initialer Scan unter $ROOT…"
  find "$ROOT" -type f -iname '*.flac' -print0 \
  | while IFS= read -r -d '' f; do convert_one "$f" || true; done
  log "Initialer Scan fertig."
}

watch_loop(){
  log "Watcher gestartet (inotify)…"
  inotifywait -m -r -e CLOSE_WRITE,MOVED_TO --format '%w%f' "$ROOT" |
  while IFS= read -r path; do
    fn="${path##*/}"
    shopt -s nocasematch
    [[ "$fn" =~ \.flac$ ]] || { shopt -u nocasematch; continue; }
    [[ "$fn" =~ \.(part|tmp|temp)$ ]] && { shopt -u nocasematch; continue; }
    shopt -u nocasematch

    # Pfad sicher absolut machen
    [[ "$path" = /* ]] || path="$ROOT/${path#./}"

    sleep 1
    convert_one "$path" || true
  done
}

initial_scan
watch_loop
