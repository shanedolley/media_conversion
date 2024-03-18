#!/bin/bash

json_body() {
    
        df -Ph | grep plexmedia | \
        jq -R -s '
            [
            split("\n") |
            .[] |
            if test("^/") then
                gsub(" +"; " ") | split(" ") | {filesystem: .[0], space_total: .[1], space_used: .[2], space_available: .[3], used_pc: .[4], mount: .[5]}
            else
                empty
            end
            ]'
}
    curl -s -H "Content-Type:application/json" -H "$webhook_auth" -X POST --data "$(json_body)" "https://api.dolley.cloud/webhook-test/media_space"