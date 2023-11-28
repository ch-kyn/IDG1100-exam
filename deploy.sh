#!/bin/bash

# 'BASH_SOURCE' refer to an array variable in Bash that contains the source filenames of the current Bash shell and its callers, '[0]' being the one currently executing/sourced in the specific Bash session
# by combining with 'dirname' you can extract the full path to the script, and print the current working directory if the preceding command was successful ('&&' operator)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
