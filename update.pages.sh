#!/bin/bash

# exec 2>save_me.txt
# set -x

index_data="${TMP_DIR}/places.as.data.txt"
data_file="${DATA_DIR}/places.txt"
desc_file="${TMP_DIR}/super.ugh.txt"

# function to create HTML for each place, inserting a '/place.sh?place=${place}' within the hyperlink as we're going to use the data ('data/places.txt') fetched from the external API for internal queries where weather data of each place is shown;
# using a server-side script ('place.sh') that has been set up through another function

function create_index_page() {

    html_index_template="${TEMPLATE_DIR}/template.index.html"
    index_page="${TMP_DIR}/index.txt"
    main_page="${TMP_DIR}/main.page.txt"
    if [[ -f "$index_data" ]]; then
        while IFS=$'\t' read -r _ place county population; do
                html_line="<p><a href='/place.sh?place=${place}'>${place}</a> ★ Population: ${population}</p>"
                modified_template=$(printf "%s\t%s\n" "$html_line" "$county" | sed "s/href=\'/href=\"/; s/\'>/\">/")
                echo "$modified_template"
        done < "$index_data" > "$index_page"

        else echo "File doesn't exist: $index_data"
        return 1  # exit the function with an error code
    fi

    cp "$html_index_template" "$main_page"

    # declare associative array "county_content", sorts and stores municipalities in their respective counties 
    declare -A county_content

    while IFS=$'\t' read -r line county; do
        if [[ -n "$county" ]]; then
            county_content["$county"]+="\t\t\t$line\n"
        fi
    done < "$index_page"

    for county in "${!county_content[@]}"; do
        sed -i "s|<!--$county-->|${county_content["$county"]}|g" "$main_page"  
    done < "$index_page"

    cat "$main_page"
}

function create_dynamic_page() {
    
    # 'sed' inserts the full path of "$data_file" into 'templates/info.page.sh.txt'
    # variable assignment to replace %page_template% with the contents of 'template.info.html' in "$page_template", replaces the %page_title% with "$title" within the page template;
    # store the processed contents in "$html" variable, replace %body% with "$body" where 'awk' has been used to structure the content of the weather data for each place
    file=$(sed -e "s|%data_file_path%|${data_file}|" -e "s|%desc_file_path%|${desc_file}|" "${TEMPLATE_DIR}/script.place.sh.txt")
    echo "${file//%page_template%/$(cat "${TEMPLATE_DIR}/template.info.html")}"
}

# using 'sudo' to make sure the file-writing operation are done with elevated permissions
# make sure the directory specified in "$DEST_DIR" (DocumentRoot), and all its subfolders and files (-rf) is emppty first, go through the process of making the directory and their parent directories if they don't already exist (--parents)
# copy main.css directory and the captured contents of the 'create_main_page' and 'create_dynamic_page' within 'index.html' and 'place.sh' into DocumentRoot, direct the output to '/dev/null' to suppress it from being shown in the terminal
sudo rm -rf "$DEST_DIR"
sudo mkdir -p "$DEST_DIR"
sudo cp "main.css" "$DEST_DIR/main.css"
sudo cp -r "assets" "$DEST_DIR/assets"
create_index_page | sudo tee "$DEST_DIR/index.html" > /dev/null
create_dynamic_page | sudo tee "$DEST_DIR/place.sh" > /dev/null

# change file ownership to 'www-data' to limit the permission of what the user can access 
sudo chown -R www-data:www-data "$DEST_DIR"

# make sure the 'place.sh' are executable by changing permission
sudo chmod +x "${DEST_DIR}/place.sh"

# exec 2>&-
