#!/usr/bin/env bash
########################################################################################################################
# Queue Functions
#
# Includes methods for maintaining the URL queue
#
########################################################################################################################

##
# Queue init
#
queue_init () {
    # Ensure tmp data queue exists
    local filename=$TMP_DIR/$QUEUE_FILENAME
    mkdir -p $TMP_DIR
    test -f $filename || touch $filename
    echo $filename
}

##
# Returns everything in Queue
#
queue_get () {
    # Ensure tmp data store exists
    local filename=$(queue_init)

    # Load the queue
    cat $filename
}

##
# Checks if the current URL is already in the queue
#
queue_exists () {
    # Ensure tmp data store exists
    local filename=$(queue_init)

    # Load the list of queued URLs
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
# Queue URL to be crawled
#
queue_push () {
    # Ensure tmp data queue exists
    local filename=$(queue_init)

    # Append the URL to the end of the file
    echo $1 >> $filename
}

##
# Pull the top item from the queue
#
queue_pop () {
    # Ensure tmp data queue exists
    local filename=$(queue_init)

    # Load the first line
    local url=$(head -1 $filename)

    # Delete the first line
    newqueue=$(tail -n +2 $filename)
    echo "$newqueue" | sed 's/\n\n//g' > $filename

    # Return URL
    echo "$url"
}

##
# Clear queue
#
queue_clear () {
    # Ensure tmp data queue exists
    local filename=$(queue_init)

    # Empty the file
    cat /dev/null > $filename
}