#!/usr/bin/env bash
########################################################################################################################
# Crawling Functions
#
# Handles crawling and parsing responses
#
########################################################################################################################

##
# Get Link List
#
# Crawls a URL $1 and queues those URLs for pickup by other threads
#
crawl_url () {
    # The URL to be loaded
    URL=$1

    # Have we already crawled it?  If so, don't crawl it again
    if [[ $(is_completed $URL) == 1 ]]; then
        return 1
    fi

    # Load the URL and parse the link list
    local result=''
    if [[ $CRAWL_ENGINE == 'wget' ]]; then
        result="$(crawl_url_wget ${URL})"
    else
        result="$(crawl_url_curl ${URL})"
    fi
    list=$(echo ${result} | grep -Eoi '<a [^>]+>' |  grep -Eo 'href="[^\"]+"' |  grep -Eo '"(.*?)"' | sed 's/\"//g' | sort | uniq)

    # Add this URL to the completed list
    add_completed ${URL}

    # Did we not return anything?
    if [[ -z "$list" ]]; then
        return 1
    fi

    # Add any found links to the queue to be processed
    while IFS= read -r line; do
        # Parse the full URL
        local my_url=$line
        if [[ $my_url == \#* ]]; then
            continue
        elif [[ $line == /* ]]; then
            my_url="$BASE_URL$line"
        fi

        # Check that it's at the correct BASE_DOMAIN
        if [[ $my_url != *$BASE_DOMAIN/* ]]; then
            continue
        fi

        # Is this URL already in the queue or has already been completed?
        if [[ $(queue_exists $my_url) == 1 || $(is_completed $my_url) == 1 ]]; then
            continue
        fi

        # Add URL to queue
        echo $my_url
        queue_push $my_url
    done <<< "$list"
}

##
# Get Link List (wget)
#
# Loads the link using wget and returns the result
#
crawl_url_wget () {
    local URL=$1
    wget -qO- $URL 2>&1
}

##
# Get Link List (curl)
#
# Loads the link using wget and returns the result
#
crawl_url_curl () {
    local URL=$1
    curl -Lvs $URL 2>&1
}