#!/bin/bash
foldername="/mnt/plexmedia/Movies/The Deer Hunter (1978) {tmdb-11778}"
filename=The Deer Hunter (1978) [Remux-1080p] {tmdb-11778}.mp4
convFileName="$foldername/$filename"

ffmpeg -i "$convFileName" -c:v hevc_nvenc -c:a copy -stats -loglevel quiet -strict -2 -y "/conversions/$filename"
