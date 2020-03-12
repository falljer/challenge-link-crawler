#!/usr/bin/env bash

TMP_DIR='./tmp'
COMPLETED_FILENAME='completed.txt'
QUEUE_FILENAME='queue.txt'
CRAWL_ENGINE='wget'
THREADS=0
BASE_URL=''
BASE_DOMAIN=''
IS_CHILD_THREAD=0

# Include our Libraries
. ./lib/db.sh
. ./lib/queue.sh
. ./lib/crawl.sh

########################################################################################################################
# CLI Arguments
#
# Handles valid CLI arguments and usage information
#
########################################################################################################################

##
# Get script options from command-line
#
get_opts () {
    # Load command-line args
    OPTIND=1
    while getopts "h?n:e:t" opt; do
        case ${opt} in
            h|\? ) show_help
                ;;
            n ) THREADS=$OPTARG
                ;;
            e ) set_engine $OPTARG
                ;;
            t )
                THREADS=1
                IS_CHILD_THREAD=1
                ;;
        esac
    done

    # Load base_url
    shift $((OPTIND -1))
    BASE_URL=$1
    BASE_DOMAIN=$(echo "$BASE_URL" | sed 's/https:\/\///g' | sed 's/http:\/\///g' | sed 's/\///g')
    if [[ $BASE_URL != */ ]]; then
        BASE_URL="$BASE_URL/"
    fi

    # Check for errors
    CONTINUE=1
    if [ $THREADS == 0 ]; then
        echo
        echo "Error: Number of threads not set.  Please specify threads"
        CONTINUE=0
    fi

    if [ -z "$BASE_URL" ]; then
        echo
        echo "Error: Base URL not set.  Please specify base_url"
        CONTINUE=0
    fi

    if [ $CONTINUE == 0 ]; then
        show_help
    fi
}

##
# Output usage
#
show_help () {
    echo
    echo "Usage:"
    echo
    echo "  ./crawl -n threads [-e engine] base_url"
    echo
    echo "  threads: # of threads to use to crawl the site"
    echo "  engine: http engine to use (default wget, options: wget, curl)"
    echo
    exit 0
}

##
# Set crawl engine
#
set_engine () {
    local engine=$1
    case ${engine} in
        curl )
            CRAWL_ENGINE='curl'
            ;;
        wget )
            CRAWL_ENGINE='wget'
            ;;

        *)
            echo
            echo "Error: Invalid engine '$engine'"
            echo
            show_help
            ;;
    esac
}

########################################################################################################################
# Script Init
########################################################################################################################

# Load command-line opts
get_opts "$@"

# If this is a child thread, exit because we are done
if [ $IS_CHILD_THREAD == 1 ]; then
    # Is there anything in queue?
    queue=$(queue_get)
    if [ -z "$queue" ]; then
        exit 1
    fi

    # Get the next URL
    url=$(queue_pop)
    while true; do
        # Crawl URL
        crawl_url $url

        # Wait 1-2 seconds to not flood the site
        sleep $[ ( $RANDOM % 2 )  + 1 ]s
        url=$(queue_pop)

        # If no more urls, then exit
        if [ -z "$url" ]; then
            exit 0
        fi
    done
    exit 0
fi

# Not a thread, tell the user what we're going to do
echo
echo "Crawling $BASE_URL ($BASE_DOMAIN) using $CRAWL_ENGINE with $THREADS threads..."
echo

# Get the initial URLs from home page
crawl_url $BASE_URL

# Did we not return anything?
list=$(queue_get)
if [[ -z "$list" ]]; then
    echo "Nothing was returned"
    exit 1
fi

# And start more threads
pids=''
for (( thread=0; thread<$THREADS; thread++ )); do
    # Start a thread and track its PID
    ./crawl.sh -e $CRAWL_ENGINE -t $BASE_URL &
    pids[$thread]=$!

    # Wait 1-10 seconds
    sleep $[ ( $RANDOM % 10 )  + 1 ]s
done

# Wait for threads to complete
for pid in ${pids[*]}; do
    wait $pid
done

# And, cleanup
queue_clear
reset_db
echo "done."