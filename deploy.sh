#!/bin/bash

# 'BASH_SOURCE' refer to an array variable in Bash that contains the source filenames of the current Bash shell and its callers, '[0]' being the one currently executing/sourced in the specific Bash session
    # by combining with 'dirname' you can extract the full path to the script, ensuring that the script locate files relative to the running script (here: 'deploy.sh')̈́
    # print current working directory if the preceding command was successful ('&&' operator)

# using "SCRIPT_DIR" variable to access subfolders within the main repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

# only need to define path variables within 'deploy.sh', as those variables are considered global and can be accessed and modified by any part of the sscript
ASSET_DIR="${SCRIPT_DIR}/assets"
DATA_DIR="${SCRIPT_DIR}/data"
LOGS_DIR="${SCRIPT_DIR}/logs"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"
TMP_DIR="${SCRIPT_DIR}/tmp"
UTIL_DIR="${SCRIPT_DIR}/utilities"

# variables for Apache
SITE_NAME="assignment.whoami"
ADMIN_EMAIL="whoami@ntnu.no"
DEST_DIR="/var/www/main-assignment"

# create function to configure apache, access template.apache.conf
function config_apache() {
    # copy .conf in /etc/apache2/sites-available; while also customizing it
    cat "${TEMPLATE_DIR}/template.apache.conf" |
        sed "s/<<url>>/$SITE_NAME/g" |
        sed "s <<root_dir>> $DEST_DIR g" |
        sed "s/<<email>>/$ADMIN_EMAIL/g" |
        sudo tee "/etc/apache2/sites-available/${SITE_NAME}.conf" > "/dev/null"
    # make sure the site is Apache-enabled
    sudo a2ensite "${SITE_NAME}.conf"
    # make sure it is configured in /etc/hosts 
    if ! grep -q "$SITE_NAME" /etc/hosts; then
        echo "127.0.0.1 $SITE_NAME" | sudo tee -a /etc/hosts
    fi
    # enable cgi scripts on apache
    sudo a2enmod cgi
    sudo systemctl restart apache2
}

# *make sure all scripts will run, but only if they all are succesfully executed consecutively using "&&" operator
source "$SCRIPT_DIR/main.sh" &&
source "$SCRIPT_DIR/weather.sh" &&
source "$SCRIPT_DIR/update.pages.sh" &&
config_apache
