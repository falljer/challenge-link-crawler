#!/usr/bin/env bash
########################################################################################################################
# Database Functions
#
# Includes methods for maintaining the database of already visited URLs
#
########################################################################################################################

##
# Initializes the tmp data source
#
init_db () {
    # Ensure tmp data store exists
    local filename=$TMP_DIR/$COMPLETED_FILENAME
    mkdir -p $TMP_DIR
    test -f $filename || touch $filename
    echo $filename
}

##
# Returns everything in DB
#
db_get () {
    # Ensure tmp data store exists
    local filename=$(init_db)

    # Load the list of completed URLs so far
    cat $filename
}

##
# Checks if the current URL has already been crawled by any thread
#
is_completed () {
    # Ensure tmp data store exists
    local filename=$(init_db)

    # Load the list of completed URLs so far
    IFS=$'\n' read -d '' -r -a list < $filename

    # Check if current URL is in the completed list
    if [[ " ${list[@]} " =~ " ${1} " ]]; then
        echo 1
        return 1
    fi

    echo 0
    return 0
}

##
# Adds a new link to the completed URL list
#
add_completed () {
    # Ensure tmp data store exists
    local filename=$(init_db)

    # Append the URL to the end of the file
    echo $1 >> $filename
}

##
# Resets the local database
#
reset_db () {
    # Ensure tmp data store exists
    local filename=$(init_db)

    # Empty the file
    cat /dev/null > $filename
}