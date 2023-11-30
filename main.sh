#!/bin/bash

# fetching HTML structure of URL, and using regular expressions to target the information I want
# doing the process step-by-step by saving the outputs in seperate .txt files within "tmp" folder to troubleshoot easier

# temporary placement to test
function get_inner_html () {
    while read -r element; do
        split_element=$(echo "$element" | \
            sed -E "s|(<\/[[:alpha:]]+>)|\n\1\n|g" | \
            sed -E "s|(<[[:alpha:]][^>]*>)|\n\1\n|g")

        result=$(sed '/^$/d' <<< "$split_element" | \
            sed '1d;$d' | \
            paste -s -d '')
        echo "$result"
    done
}

# single quotes around the URL as variable expansion is not needed
WIKI_URL='https://en.wikipedia.org/wiki/List_of_municipalities_of_Norway'

# using '/start/,/end/' (syntax) with 'sed' to target the table that contains the list of municipalities
# appending '</td>' on every line that starts with '<th>' due to the HTML structure being formatted in such a way that '</td>' was on a newline, and 'grep' to match and print all table data
# 'awk' to print every second, fourth, fifth and eight line within a 11-line span (table has eleven table cells for each municipality)

curl -s "$WIKI_URL" |  sed -n '\|<table class="sortable wikitable">|,\|</table>|p' > "tmp/main.wiki.table.txt"
sed -i -E '/<td>/s/.*/&<\/td>/' "tmp/main.wiki.table.txt" > "tmp/table.all.rows.txt" && grep -E -o '<td>.*<\/td>' "tmp/main.wiki.table.txt" > "tmp/table.all.rows.txt"
awk 'NR % 11 == 2 || NR % 11 == 4 || NR % 11 == 5 || NR % 11 == 8' "tmp/table.all.rows.txt" > "tmp/table.main.rows.txt"

# if condition that file 'places.txt' doesn't exist is true, it will execute the extracting of coordinates by ...
# not re-running if file exist, because that means you already have coordinates and loading that data is slow 
if [[ ! -f  "data/places.txt" ]]; then
        get_inner_html < "tmp/table.main.rows.txt" > "tmp/places.as.a.txt"

    # 'match' function to find the first occurence of "href=..." for each line ands 'title' attribute, and extract the content within the double quotes by using built-in tools in AWK like like 'substr()' and 'RSTART/RLENGTH'
    # 'printf' to combine the base Wikipedia URL with the string found in the first match to create an absolute URL for each municipality/Arms image, and insert a tab between that string and the second one;
    # which stores the content within the 'title' attribute (here: name of the municipality)
    # used 'else if' statement for every second ('county') and third ('population') line to be processed differently within the AWK script 

    awk '
    {
        if (NR % 4 == 1 || NR % 4 == 4) {
            if (match($0, /href="[^"]*"/)) {
                url = substr($0, RSTART+6, RLENGTH-7)
            }
            if (match($0, />[^<]*<\/a>/)) {
                printf("%s%s\t%s", "https://en.wikipedia.org", url, substr($0, RSTART+1, RLENGTH-5))
            }
        } else if (NR % 4 == 2) {
            if (match($0, />[^<]*<\/a>/)) {
                printf("%s\t", substr($0, RSTART+1, RLENGTH-5))
            }
        } else if (NR % 4 == 3) {
            printf("%s\t", $0)
        }
    }
        ' "tmp/places.as.a.txt" > "tmp/places.as.data.txt"
    echo "cool echo message"

fi

# concatenate content of every four line together with relevant data for each muncipality
# awk '{ORS=(NR%4==0)?" ":"\n"}|' "tmp/lol.txt" | paste -s -d ''
