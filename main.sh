#!/bin/bash

# fetching HTML structure of URL, and using regular expressions to target the information I want
# doing the process step-by-step by saving the outputs in seperate .txt files within "tmp" folder to troubleshoot easier

source "${UTIL_DIR}/html.sh"
source "${UTIL_DIR}/conversion.sh"

# single quotes around the URL as variable expansion is not needed
WIKI_URL='https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway'

# if condition that file 'places.txt' doesn't exist is true, it will execute the extracting of coordinates
# not re-running if file exist, because that means you already have coordinates and loading that data again is both slow and necessary
if [[ ! -f  "${DATA_DIR}/places.txt" ]]; then

    # using '/start/,/end/' (syntax) with 'sed' to target the table that contains the list of municipalities
    # appending '</td>' on every line that starts with '<th>' due to the HTML structure being formatted in such a way that '</td>' was on a newline, and 'grep' to match and print all table data
    # 'awk' to print every second, fourth, fifth and eight line within a 11-line span (table has eleven table cells for each place)

    curl -s "$WIKI_URL" |  sed -n '\|<table class="sortable wikitable">|,\|</table>|p' > "${TMP_DIR}/main.wiki.table.txt"
    sed -i -E '/<td>/s/.*/&<\/td>/' "${TMP_DIR}/main.wiki.table.txt" > "${TMP_DIR}/table.all.rows.txt" && grep -E -o '<td>.*<\/td>' "${TMP_DIR}/main.wiki.table.txt" > "${TMP_DIR}/table.all.rows.txt"
    awk 'NR % 11 == 2 || NR % 11 == 4 || NR % 11 == 5' "${TMP_DIR}/table.all.rows.txt" > "${TMP_DIR}/table.main.rows.txt"
    awk 'NR % 11 == 2 || NR % 11 == 5 || NR % 11 == 6 || NR % 11 == 10 || NR % 11 == 0' "${TMP_DIR}/table.all.rows.txt" > "${TMP_DIR}/table.description.rows.txt"
    
    get_inner_html < "${TMP_DIR}/table.main.rows.txt" > "${TMP_DIR}/places.as.a.txt"
    get_inner_html < "${TMP_DIR}/table.description.rows.txt" > "${TMP_DIR}/ugh.txt"

    # 'match' function to find the first occurence of "href=..." for each line and 'title' attribute, and extract the content within the double quotes by using built-in tools in AWK like like 'substr()' and 'RSTART/RLENGTH'
    # 'printf' to combine the base Wikipedia URL with the string found in the first match to create an absolute URL for each municipality/Arms image, and insert a tab between that string and the second one;
    # which stores the content within the 'title' attribute (here: name of the municipality)
    # used 'else if' statement for every second, ('county'), third ('population') and fourth ('arms') line to be processed differently within the AWK script 

    awk '
        {
            if (NR % 3 == 1) {
                if (match($0, /href="[^"]*"/)) {
                    url = substr($0, RSTART+6, RLENGTH-7)
                }
                if (match($0, />[^<]*<\/a>/)) {
                    title = substr($0, RSTART+1, RLENGTH-5)
                    printf("%s%s\t%s\t", "https://en.wikipedia.org", url, title)
                }
            } else if (NR % 3 == 2) {
                if (match($0, />[^<]*<\/a>/)) {
                    printf("%s\t", substr($0, RSTART+1, RLENGTH-5))
                }
            } else if (NR % 3 == 0) {
                printf("%s\n", $0)
            }
        }
    ' "${TMP_DIR}/places.as.a.txt" > "${TMP_DIR}/places.as.data.txt"
    echo "Extracted table cells"

    # wops I like didn't realize I had to make a description for each place as well before now, following the same process as the earlier AWK script by extracting specifics of each column and combining them together in a tab-seperated document
    # extracting the 'Mayor' column felt difficult as they were either within <a> or <span> tags; exists better ways to extract the content between <span> tags, but it will suffice for now

    awk '
    {
        if (NR % 5 == 1) {
            if (match($0, />[^<]*<\/a>/)) {
                printf("%s\t", substr($0, RSTART+1, RLENGTH-5))
            }
        } else if (NR % 5 == 2 || NR % 5 == 3) {
            printf("%s\t", $0)
        } else if (NR % 5 == 4) {
            if (match($0, />[^<]*<\/a>/)) {
                printf("%s\t", substr($0, RSTART+1, RLENGTH-5))
            } else if (match($0, />([^<]+)<\/span>/)) {
                printf("%s\t", substr($0, RSTART+1, RLENGTH-8))
            }
        } else if (NR % 5 == 0) {
            if (match($0, />[^<]*<\/a>/)) {
                printf("%s\n", substr($0, RSTART+1, RLENGTH-5))
            }
        }
    }' "${TMP_DIR}/ugh.txt" > "${TMP_DIR}/super.ugh.txt"
    echo "existing"

# using '_' so my 'while' statement doesn't include field 2, 3 and 4 in my 'tmp/places.with.coords.txt', as those fields will be relevant in the HTML of my main page
# finds the first instance of "<span class="latitude/longitude>" ('head -n 1'), extract the degrees and convert them to decimals
while read -r url place _ _; do
        page=$(get_page "$url")
        lat=$(extract_elements 'span' 'class="latitude"' <<< "$page" |\
            head -n 1 |\
            get_inner_html |\
            degrees_converter)
        lon=$(extract_elements 'span' 'class="longitude"' <<< "$page" |\
            head -n 1 |\
            get_inner_html |\
            degrees_converter)
        printf "%s\t%s\t%s\t%s\n" "$url" "$place" "$lat" "$lon" >> "${TMP_DIR}/places.with.coords.txt"
    done < "${TMP_DIR}/places.as.data.txt"

# prepering fields of data (dates, weather data) that's going to be inserted into the updated 'places.txt' during 'weather.sh' by inserting '\t' '  
    awk -F '\t' '
        {
           printf("%s\t\t\t\t\t\t\t\n", $0)
        }
    ' "${TMP_DIR}/places.with.coords.txt" > "${DATA_DIR}/places.txt"
fi