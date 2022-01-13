#!/bin/bash

# ------------------------------------------------------------------
# [Title] : Archange
# [Description] : Save the history of a server with ls -R and scp command
# [Version] : v1.1.0
# [Author] : Lucas Noga
# [Usage] : ./archange.sh
#           ./archange.sh -d
# ------------------------------------------------------------------

PROJECT_NAME=ARCHANGE
PROJECT_VERSION=v1.1.0

# Config params to get access to the server
typeset -A SERVER=(
    [ip]=""       # ip of the server set in config
    [port]=""     # port of the server set in config
    [user]=""     # user of the server set in config
    [password]="" # password of the server set in config
    [path]=""     # path of the server set in config
)

# File created on the server
SERVER_FILE="HISTORY.txt"

# Configuration file
CONFIG_FILE="./settings.conf"

# Name of the file which will get the copy (default HISTORY_date)
FILENAME=HISTORY_$(date +"%Y-%m-%d").txt

# Options params setup with command parameters
typeset -A OPTIONS=(
    [debug]=false       # Debug mode to show more log
    [debug_color]=blue  # Color to show log in debug mode
    [erase_trace]=false # if true we erase trace on the remote machine
)

###
# Main body of script starts here
###
main() {
    read_options $@

    read_config_server $CONFIG_FILE

    log_debug "Server keys: ${!SERVER[@]}"
    log_debug "Server values: ${SERVER[@]}"

    log_debug "Options keys: ${!OPTIONS[@]}"
    log_debug "Options values: ${OPTIONS[@]}"

    log_debug "Launch Project ${PROJECT_NAME} : ${PROJECT_VERSION}"

    folder=$(get_folder)
    log "Folder when you save your history: $(log_color "$(pwd)" yellow)"

    log "Default name is: $(log_color $FILENAME yellow)"

    get_server_path_history

    # Ask password if no filled in config
    read_server_password

    create_history
    copy_history_to_local $folder

    # remove file(s) from servers if option is activated
    if [ "${OPTIONS[erase_trace]}" = true ]; then
        erase_trace
    fi
}

###
# Setup variable from config file
# $1 = path to the config file (default: ./setting.conf)
###
read_config_server() {
    CONFIG_FILE=$1
    log_debug "Read configuration file: $CONFIG_FILE"

    # if configuration file doesn't exists

    if [ ! -f "$CONFIG_FILE" ]; then
        log_color "ERROR: $CONFIG_FILE doesn't exists." "red"
        log "Exiting..."
        exit 1
    fi

    # Load configuration file
    source $CONFIG_FILE
    SERVER+=(
        [ip]=$(eval echo $IP)
        [port]=$(eval echo $PORT)
        [user]=$(eval echo \$$PROJECT_NAME"_USER") # Env variable already defined in the system ($USER) so we prefix it with ARCHANGE_
        [password]=$(eval echo $PASSWORD)
        [path]=$(eval echo \$$PROJECT_NAME"_PATH") # Env variable already defined in the system ($PATH) so we prefix it with ARCHANGE_
    )

    # Check empty values
    if [ -z ${SERVER[ip]} ]; then
        log_color "ERROR: IP is not defined into $CONFIG_FILE" "red"
        log "Exiting..."
        exit 1
    fi
    if [ -z ${SERVER[port]} ]; then
        log_color "ERROR: PORT is not defined into $CONFIG_FILE" "red"
        log "Exiting..."
        exit 1
    fi
    if [ -z ${SERVER[user]} ]; then
        log_color "ERROR: USER is not defined into $CONFIG_FILE" "red"
        log "Exiting..."
        exit 1
    fi
}

################################################################### Params Scripts ###################################################################

###
# Setup params passed with the script
# -d | --debug : Setup debug mode
# --erase-trace : Erase file and your trace on remote machine
###
read_options() {
    params=("$@") # Convert params into an array

    # Step through all param passed
    for param in "${params[@]}"; do
        case $param in
        "-d")
            active_debug_mode
            ;;
        "--debug")
            active_debug_mode
            ;;
        "--erase-trace")
            handle_erase_trace
            ;;
        *) ;;
        esac
        log_debug "Option '$param' founded"
    done
}

###
# Active the debug mode changing options params
###
active_debug_mode() {
    OPTIONS+=([debug]=true)
    log_debug "Debug Mode Activated"
}

###
# Check if erase trace is asked in parameter
###
handle_erase_trace() {
    OPTIONS+=([erase_trace]=true)
    log_debug "Erase Trace active" $DEBUG_COLOR
}

################################################################### Core ###################################################################

###
# Get folder to copy the file on your local machine and test if it's exist
# $1: Folder path
# Return: [string] folder where we copy the file
###
get_folder() {
    folder=$1

    if [ -z $folder ] || [ ! -d $folder ]; then
        folder="."
    fi
    echo $folder
}

###
# Read server password asked if it's not set in config
###
read_server_password() {
    if [ -z ${SERVER[password]} ]; then
        read -s -p "Type your nas admin password: " SERVER[password]
    fi
}

###
# Get path on the server to get the history
###
get_server_path_history() {
    if [ -z ${SERVER[path]} ]; then
        read -p "Type the path you want to get history: " SERVER[path]
    fi
    log "You will get the history file of this path: $(log_color ${SERVER[path]} yellow)"
}

###
# Create ssh connection to server and create a file with all history
###
create_history() {
    log "Creating SERVER history..."
    log "Connection to the SERVER..."
    sshpass -p ${SERVER[password]} ssh ${SERVER[user]}@${SERVER[ip]} -p ${SERVER[port]} "cd ${SERVER[path]} && ls . -R > $SERVER_FILE"
    ret=$?
    if [ $ret -eq 0 ]; then
        log_color "History created" "green"
    else
        log_color "ERROR: Failed to create history with your credentials." "red"
        log "Exiting..."
        exit 1
    fi
}

###
# Copy history file from server to local
###
copy_history_to_local() {
    log "Copy History in local machine..."
    folder=$1
    log "Connection to the SERVER..."
    log Copy the file $(log_color "${SERVER[ip]}:${SERVER[path]}/$SERVER_FILE" yellow) into $(log_color "$folder/$FILENAME" yellow)
    sshpass -p ${SERVER[password]} scp -P ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]}:${SERVER[path]}/$SERVER_FILE $folder/$FILENAME
    ret=$?

    if [ $ret -eq 0 ]; then
        log_color "History retrieve" "green"
        log History copied: $(log_color "$folder/$FILENAME" yellow)
    else
        log_color "ERROR: Failed to retrieve history with your credentials." "red"
        log "Exiting..."
        exit 1
    fi
}

###
# Remove trace of your pass on the server
# For now removing HISTORY.txt file
###
erase_trace() {
    log "Erasing trace..."
    folder=$1
    filepath=${SERVER[path]}/$SERVER_FILE

    remove_server_file $filepath

    ret=$?

    if [ $ret -eq 0 ]; then
        log_color "Trace erased from remote machine" "green"
    else
        log_color "ERROR: Trace not erased from server" "red"
        exit 1
    fi
}

###
# Remove on remote machine file in filepath in param $1
###
remove_server_file() {
    filepath=$1
    log Removing File : $(log_color "$filepath" red)

    # check if file exists
    file_exists=$(check_server_file_exists $1)

    # if not exists do nothing
    if [ $file_exists -eq 0 ]; then
        log_color "File $filepath doesn't exist anymore" "light_yellow"
        return
    fi

    # remove file
    sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -t "rm $filepath"

    ret=$?

    if [ $ret -eq 0 ]; then
        log "File $(log_color $filepath yellow) removed"
    else
        log_color "ERROR: Failed to remove your file $filepath" "red"
        log "Exiting..."
        exit 1
    fi
}

###
# Check on remote machine if file exists in param $1
# $1 : filepath to test
# Return: [bool] 1 file exists, 0 if not
###
check_server_file_exists() {
    filepath=$1
    sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -q [[ -f $filepath ]] && echo 1 || echo 0
}

################################################################### Logging functions ###################################################################

###
# Simple log function to support color
###
log() {
    echo -e $@
}

typeset -A COLORS=(
    [default]='\033[0;39m'
    [black]='\033[0;30m'
    [red]='\033[0;31m'
    [green]='\033[0;32m'
    [yellow]='\033[0;33m'
    [blue]='\033[0;34m'
    [magenta]='\033[0;35m'
    [cyan]='\033[0;36m'
    [light_gray]='\033[0;37m'
    [light_grey]='\033[0;37m'
    [dark_gray]='\033[0;90m'
    [dark_grey]='\033[0;90m'
    [light_red]='\033[0;91m'
    [light_green]='\033[0;92m'
    [light_yellow]='\033[0;93m'
    [light_blue]='\033[0;94m'
    [light_magenta]='\033[0;95m'
    [light_cyan]='\033[0;96m'
    [nc]='\033[0m'
) # No Color

###
# Log the message in specific color
###
log_color() {
    message=$1
    color=$2
    log ${COLORS[$color]}$message${COLORS[nc]}
}

###
# Log the message if debug mode is activated
###
log_debug() {
    message=$@
    date=$(get_datetime)
    if [ "${OPTIONS[debug]}" = true ]; then log_color "[$date] $message" ${OPTIONS[debug_color]}; fi
}

###
# Return datetime of now (ex: 2022-01-10 23:20:35)
###
get_datetime() {
    log $(date '+%Y-%m-%d %H:%M:%S')
}

main $@
