#!/bin/bash

# foldername="/mnt/plexmedia/Movies/The Deer Hunter (1978) {tmdb-11778}"
# filename=The Deer Hunter (1978) [Remux-1080p] {tmdb-11778}.mp4
# convFileName="$foldername/$filename"

# ffmpeg -i "$convFileName" -c:v hevc_nvenc -c:a copy -stats -loglevel quiet -strict -2 -y "/conversions/$filename"

webhook_auth="Authorization:76ba4bf5-f9d0-4639-a45d-31d6b3a1ffe8"

transcode_body() {
  cat <<EOF
    {"source": "sonarr","id": 31641,"filepath":"/plexmedia/tv/Constellation (2024) - {tvdb-418727}/Season 01/Constellation (2024) - S01E02 - Live And Let Die [WEBDL-2160p].mkv","comment": "Error","error": true}
EOF
}

curl -s -H "Content-Type:application/json" -H "$webhook_auth" -X POST --data "$(transcode_body)" "https://api.dolley.cloud/webhook/transcode_complete"
