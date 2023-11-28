#!/bin/bash
# this is a function I made for a script that's supposed to fetch data from an weather API from Lab 10, will fix it to make it relevant for this current project later

# ToS (https://api.met.no/doc/TermsOfService): 5. When using requests with latitude/longitude, truncate all coordinates to max 4 decimals for traffic reasons

latitude="$1"
longitude="$2"

# use '.' to seperate fields within a variable, and truncate if the second fields is greater than 4
function truncate_decimals() {
    decimals=$(awk -F'.' '{print length($2)}' <<< "$1")

    if [[ $decimals -gt 4 ]]; then
        printf "%.4f" "$1"
    else
        printf "%s" "$1"
    fi
}

# update $latitude and $longitude; original value will be truncated if more than 4 decimals
latitude=$(truncate_decimals "$1")
longitude=$(truncate_decimals "$2")