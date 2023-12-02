#!/bin/bash

# usi
# 'classic' endpoint is to retrive the weather data formatted in XML, easier to parse using regex tools than JSON I assume
API_BASE_URL='https://api.met.no/weatherapi/locationforecast/2.0/classic?'

# loading utilities
source "utilities/api.sh"
source "utilities/html.sh"

# using the municiplalities' coordinates (latitude and longitude) to extract and record forecasted temperature, precipitation and humidity for the next day (at midday)
# for each record (aka, place), request/save the weather - expiresAt field doesn't exist or larger than time now

data_file="data/places.txt"
tmp_out_file="tmp/ewbash.txt"

while IFS=$'\t' read -r url place lat lon temp rain humidity date_for date_updated date_expires; do

    # if date_expires is empty, add
    if [[ -z "$date_expires" ]]; then
        date_expires=$(date +'%s')
    fi

    # if 'date_now' is equal or greater than 'date_expires', request fresh data
    date_now=$(date +'%s')

    if (( date_now >= date_expires )); then

        # if date_updated isn't empty, use it; else use date_now
        if [[ -z "$date_updated" ]]; then
            date_updated=$(TZ=GMT date)
        fi

        # creating a valid URL by inserting the coordinates to 'lat' and 'lon' parameters, using the URL to query the fetch data for each municipality;
        # and last updated date to send 'If-Modified-Since' headers everytime you'll query the API
        # this creates a loop that when fetching new data for each place, the client will send respective request headers

        valid_url="${API_BASE_URL}&lat=${lat}&lon=${lon}"
        http_response=$(query_api "$valid_url" "$date_updated")
        head=$(sed '/^[[:space:]]*$/q' <<< "$http_response") # headers are presented before the response body, 'sed' extracts only the headers by stopping at the first empty line
        # deletes the first instance of the first empty or whitespace-only line and the content above it (aka headers), here isolating and prepping the response body for processing to find relevant data within the XML format
        body=$(sed '1,/^[[:space:]]*$/d' <<< "$http_response" | tr -d '\n\t') 

        # update if the HTTP status code is between 200–299 (successful request) 
        status=$(head -n 1 <<< "$head" | cut -d' ' -f2)
        if ((status >= 200 && status < 300)); then
            # use "tomorrow" to obtain the predicted weather data for the next day (the string being formatted the same way as the date in the XML document)
            # by using 'head -n 1' you make sure to extract only the first instance of "<time datatype="forecast" from="%Y-%m-%dT12:00:00Z" to="%Y-%m-%dT12:00:00Z"></time>"
            date_for=$(date -d "tomorrow" +"%Y-%m-%dT12:00:00Z")
            time_elements=$(extract_elements "time" "datatype=\"forecast\" from=\"${date_for}\"[^>]*" <<< "$body")
            temp=$(\
                echo "$time_elements" |\
                    extract_weather_data "temperature" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )
            rain=$(\
                echo "$time_elements" |\
                    extract_weather_data "precipitation" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )
            humidity=$(\
                echo "$time_elements" |\
                    extract_weather_data "humidity" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*value="([^"]*)".*|\1|' )

            # adding 'date_to' variable to obtain the forecasted weather symbol code the timespan 12:00:00 to 13:00:00 each day
            date_to=$(date -d "tomorrow" +"%Y-%m-%dT13:00:00Z")
            weather_icon=$(extract_elements "time" "datatype=\"forecast\" from=\"${date_for}\" to=\"${date_to}\"[^>]*" <<< "$body")
               symbol=$(\
                echo "$weather_icon" |\
                    extract_weather_data "symbol" '[^>\/]*' |\
                    head -n 1 |\
                    sed -E 's|.*code="([^"]*)".*|\1|' )

            # update 'date_updated' variable by taking the newly updated date via 'query_api' function, and update 'If-Modified-Since' header
            # will "date_expires"
            date_updated=$(grep -i "^date:" <<< "$head" | cut -d' ' -f2-)
            date_expires=$(grep -i "^expires:" <<< "$head"| cut -d' ' -f2-)

            # 'logs.txt' reads each line when you attempt to fetch data for a place, and store info corresponding to the action of its status code 
            echo "[LOG] $date_now 200 received fresh data for $place, humidity: $humidity, rain: $rain, temp: $temp" >> "logs/logs.txt"
        
        # status code 304: "Not Modified" - use the cached version of the resource instead of unnecessarily loading both the server and network if the data hasn't been updated
        elif ((status == 304)); then
            echo "[LOG] $date_now 304 no fresh data for $place" >> "logs/logs.txt" 

        else
            # record error status codes
            echo "[ERROR] $date_now $(head -n 1 <<< "$head")" >> "logs/logs.txt"
        fi
    fi 
  
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$url" "$place" "$lat" "$lon" "$temp" "$rain" "$humidity" "$symbol" "$date_for" "$date_to" "$date_updated" "$date_expires" >> "$tmp_out_file"
done < "$data_file"

mv "tmp/ewbash.txt" "data/places.txt"

# if [[ -f "data/slay.txt" ]]; then
    # check_data_midday=$(awk -F'\t' -v current_date="$(date +'%Y-%m-%dT%H:%M:%SZ')" '$9 < current_date { print $5 }' "data/slay.txt")
    # if [[ -n "$check_data_midday" ]]; then
       # echo "[ERROR] $date_now Existing data is up-to-date."
    # fi
# fi

# TODO: throttle requests?