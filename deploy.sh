#!/bin/bash

# 'BASH_SOURCE' refer to an array variable in Bash that contains the source filenames of the current Bash shell and its callers, '[0]' being the one currently executing/sourced in the specific Bash session
# by combining with 'dirname' you can extract the full path to the script, ensuring that the script locate files relative to the running script (here: 'deploy.sh')̈́
# print current working directory if the preceding command was successful ('&&' operator)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
RESOURCES_DIR="${SCRIPT_DIR}/resources"
SITE_NAME="assignment.chriskng"
ADMIN_EMAIL="chriskng@ntnu.no"
DESTINATION_DIR="/var/www/main-assignment"

# create function to make a weather check crontab (part of 'B', guess I'll need to include one lol)
# create function to configure apache, access template.apache.conf
# use 'source' combined with '&&' to only make the deployment script when every side-script and function works as it's supposed to
    # just need to create those side-scripts and functions T_T