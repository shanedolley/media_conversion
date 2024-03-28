#!/bin/bash

json_body() {
    
        df -P | grep plexmedia | \
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
    curl -s -H "Content-Type:application/json" -X POST --data "$(json_body)" "https://hookdeck.dolley.cloud/eluva9irjwevd0"