#!/bin/bash

# extracting, splitting, forming HTML lines
# some errors within the "IDG1100" script when doing this on municipalities > leads to not full name not being shown up, empty lines, empty coordinates etc.

# use of 'local' to define local' variables, useful for encapsulate functionality within a specific function or script as it makes understanding the code easier to understand and mantain;
# by isolating the scope, you can prevent overwriting and reducing the namespace pollution of global variables, and also uninteded side effects (working with multiple URLs, lines etc.)

# more general way to search for content as it can apply to any website, while my first lines of code within 'main.sh' was very specific to the HTML structure of obtaining the data of the Wikipedia page
# fetch URLs, remove newlines and tabs to prep each municipality for processing so regex tools can process the entire page as a single string
function get_page(){
    local url place html one_line_html
    url=$1
    county=$2

    html="$(curl -s -L "$url")"

    one_line_html="$( echo "$html" | tr -d '\n\t' )" 

    if [ -z "$place" ]; then
        echo "$one_line_html"
    else
        printf "%s" "$one_line_html" > "$county"
    fi
    echo "We've received the page: ${url}"
}

# function to extract HTML elements where the structure is stored at one line, and then put it on a newline; requires both a opening and closing tag however (e.g. extracting "<img src=...>" won't work)
function extract_elements() {
    local html_single_line tag attributes
    tag="$1"
    attributes="$2"
    html_single_line=''

    # -n flag (--non-empty) within a conditional statement to test if something is not empty
    # if "$attributes" is not empty, put a space before the attribute and include it in the opening tag (e.g. in case the HTML element has a class, id etc.)

    if [[ -n "${attributes}" ]]; then
        attributes=' '"$attributes"
    fi

    # 'read' command by default reads line by line, stores ut to "$line" and concatenate it within "$html_single_line"
    while read -r line; do
        html_single_line+=$line
    done

    # regular expressions like 'awk', 'sed' and 'grep' work line-by-line, so sorting the elements line-by-line is necessary to avoid greedy matches
    # greedy matching: matches as much of the input string as possible while still allowing the overall pattern to match
    opening_tag="<${tag}${attributes}>"
    closing_tag="</${tag}>"

    echo "$html_single_line" |\
        sed -E "s|(${closing_tag})|\1\n|g" |\
        grep -o "${opening_tag}.*${closing_tag}"
}

function extract_weather_data() {
    local tag template html_single_line
    tag="$1"
    template="$2"

    while read -r line; do
        html_single_line+=$line
    done

    search_element="<${tag} ?${template} ?/?>"
    
    html_multi_line=$(
        echo "$html_single_line" |\
            sed -E "s|(>)|\1\n|g" |\
            sed -E 's|(<)|\n\1|g' )
    sed '/^$/d' <<< "$html_multi_line" |\
        grep -E -o "${search_element}"
}

# extract the content of each individually processed HTML element by splitting the starting and closing tag onto newlines, removes whitespace, then;
# continue processing the string passed as input to "$result" variable (by using '<<<') and removing the first and last line (here: tags) of each element
function get_inner_html () {
    while read -r element; do
        split_element=$(echo "$element" |\
            sed -E "s|(<\/[[:alpha:]]+>)|\n\1\n|g" |\
            sed -E "s|(<[[:alpha:]][^>]*>)|\n\1\n|g")

        result=$(sed '/^$/d' <<< "$split_element" |\
            sed '1d;$d' |\
            paste -s -d '')

        echo "$result"
    done
}
