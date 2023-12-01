#!/bin/bash

# 'classic' is the weather data formatted in XML
API_BASE_URL="https://api.met.no/weatherapi/nowcast/2.0/classic?"

# loading utilities
source "utilities/api.sh"
source "utilities/html.sh"

# for each record (aka, place), request/save the weather - expiresAt field doesn't exist or larger than time now
data_file="data/places.txt"
valid_url="${API_BASE_URL}lat=${lat}&lon=${lon}"

while IFS=$'\t' read -r url place lat lon temp rain humidity date_for date_updated date_expires; do
    # if date_expires is empty, add
    if [[ -z "$date_expires" ]]; then
        date_expires=$(date +'%s')
    fi
    # if date_expires is >= than time now, request fresh data
    date_now=$(date +'%s')
    buffer=60 # 1 minute buffer to provide a small window of time to handle the expiration event
    if ((date_now >= date_expires + buffer)); then

        # if date_updated isn't empty, use it; else use date_now
        if [[ -z "$date_updated" ]]; then
            date_updated=$(TZ=GMT date)
        fi

        http_response=$(query_api "$valid_url" "$date_updated")
        head=$(sed '/^[[:space:]]*$/q' <<< "$http_response")
        body=$(sed '1,/^[[:space:]]*$/d' <<< "$http_response" | tr -d '\n\t')
        # check if 200
        status=$(head -n 1 <<< "$head" | cut -d' ' -f2)
        if ((status >= 200 && status < 300)); then
            # save new data
            date_for=$(date -d "tomorrow" +"%Y-%m-%d")'T12:00:00Z'
            time_elements=$(extract_elements "time" "datatype=\"forecast\" from=\"${date_for}\"[^>]*" <<< "$body")
            temp=$(\
                echo "$time_elements" |\
                    eextract_self.closing_elements "temperature" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )
            rain=$(\
                echo "$time_elements" |\
                    extract_self.closing_elements "precipitation" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )
            humidity=$(\
                echo "$time_elements" |\
                    extract_self.closing_elements "humidity" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )
            # update 'date_updated' and "date_expires"
            date_updated=$(grep -i "^date:" <<< "$head" | cut -d' ' -f2-)
            date_expires=$(grep -i "^expires:" <<< "$head"| cut -d' ' -f2-)
            echo "[LOG] $date_now 200 received fresh data for $place, humidity: $humidity, temp: $temp" >> "${LOGS_DIR}/logs.txt"
        elif ((status == 304)); then
            echo "[LOG] $date_now 304 no fresh data for $place" >> "${LOGS_DIR}/logs.txt"
        else
            # record errors
            echo "[ERROR] $date_now $(head -n 1 <<< "$head")" >> "${LOGS_DIR}/logs.txt"
        fi
    fi 
  
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$url" "$place" "$lat" "$lon" "$temp" "$rain" "$humidity" "$date_for" "$date_updated" "$date_expires"
done < "$data_file" > "data/slay_test.txt"

# TODO: throttle requests?