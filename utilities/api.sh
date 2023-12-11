#!/bin/bash

# send headers when fetching from an API, even if it is not required it is good manners to tell that you're utilizing their API e.g. when you clog their traffic and they need to get in contact;
# "Any requests with a profibited or missing User-Agent will receive a 403 Forbidden error"
function query_api(){
    local url date_updated
    url=$1
    date_updated=${2:-$(TZ=GMT date)}
    
    curl -s -i \
        -H "Accept: application/xml" \
        -H "If-Modified-Since: ${date_updated}" \
        -H "User-Agent: ntnu.no whoami@ntnu.no main_assignment_IDG1100" \
        "${url}"
}
