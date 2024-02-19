#!/bin/bash
webhook_auth="Authorization:76ba4bf5-f9d0-4639-a45d-31d6b3a1ffe8"
filedeets_source="sonarr"
filedeets_id=123456789
dataMessage="This is a: comment"
curlCode="OK" 

transcode_body() 
{
  cat <<EOF
    {"source": "$filedeets_source","id": $filedeets_id,"comment": "$dataMessage"}
EOF
}

curl -s -H "$webhook_auth" -H "Content-Type: application/json" -X POST --data "$(transcode_body)" "https://api.dolley.cloud/webhook/transcode_complete"