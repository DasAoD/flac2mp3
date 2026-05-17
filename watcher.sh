#!/bin/bash
# flac2mp3-watcher v1.3 – Unraid-friendly: FLAC -> MP3 (320k), delete source, logrotate
# Fixes v1.3: ffmpeg stdin isolation (< /dev/null), inotifywait via process substitution
set -euo pipefail

VERSION="1.3"

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

mp3_of(){ local f="$1"; echo "${f%.flac}.mp3"; }

mkdir -p "$(dirname "$LOGFILE")"; chmod 775 "$(dirname "$LOGFILE")" || true
mkdir -p "$ROOT"; chmod 2775 "$ROOT" || true

log "flac2mp3-watcher startet – Version $VERSION"
log "ROOT=$ROOT  UMASK=$UMASK_VAL  LOGFILE=$LOGFILE  MAX_MB=$LOG_MAX_MB  BACKUPS=$LOG_BACKUPS"

nice="nice -n 5"; ionice="ionice -c2 -n4"

convert_one(){
  local src="$1"
  [[ "$src" = /* ]] || src="$ROOT/${src#./}"

  local dst tmp
  dst="$(mp3_of "$src")"
  tmp="${dst}.tmp.mp3"

  install -d -m 2775 -o 99 -g 100 "$(dirname "$dst")"

  if [[ -f "$dst" && "$dst" -nt "$src" ]]; then
    log "Skip (aktuell): $dst"
    return 0
  fi

  log "Konvertiere: $src -> $dst"
  # < /dev/null: ffmpeg darf nie von stdin lesen (würde inotify-Events konsumieren)
  if ${ionice} ${nice} ffmpeg -hide_banner -loglevel error -y \
       -i "$src" -map_metadata 0 -c:a libmp3lame -b:a 320k -vn "$tmp" < /dev/null; then
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
  # Process substitution statt Pipe: while-Schleife hat eigenen stdin,
  # kein Durchreichen von inotify-Events an ffmpeg möglich
  while IFS= read -r path; do
    fn="${path##*/}"
    shopt -s nocasematch
    [[ "$fn" =~ \.flac$ ]] || { shopt -u nocasematch; continue; }
    [[ "$fn" =~ \.(part|tmp|temp)$ ]] && { shopt -u nocasematch; continue; }
    shopt -u nocasematch

    [[ "$path" = /* ]] || path="$ROOT/${path#./}"

    sleep 1
    convert_one "$path" || true
  done < <(inotifywait -m -r -e CLOSE_WRITE,MOVED_TO --format '%w%f' "$ROOT")
}

initial_scan
watch_loop
