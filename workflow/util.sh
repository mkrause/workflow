#!/bin/bash
# Utility functions

# Colors
col_reset="\x1b[39;49;00m"
col_red="\x1b[31;01m"
col_green="\x1b[32;01m"
col_yellow="\x1b[33;01m"
col_blue="\x1b[34;01m"
col_magenta="\x1b[35;01m"
col_cyan="\x1b[36;01m"

echo_color() {
    local color=$col_green
    local options=()
    local text=""
    
    # Options parsing
    for arg in "${@}"; do
        case "$arg" in
            --color=*) color="${arg#--color=}" ;;
            # Anything else that looks like an option
            -*) options+=($arg) ;;
            # Non-option arguments
            *) text="${text}${arg} " ;;
        esac
    done
    
    text="${text%?}" # Remove the last space character
    echo -e ${options[@]} "${color}${text}${col_reset}"
}

echo_red() { echo_color --color=$col_red "$@"; }
echo_green() { echo_color --color=$col_green "$@"; }
echo_yellow() { echo_color --color=$col_yellow "$@"; }
echo_blue() { echo_color --color=$col_blue "$@"; }
echo_magenta() { echo_color --color=$col_magenta "$@"; }
echo_cyan() { echo_color --color=$col_cyan "$@"; }

echo_info() { echo_green "$@"; }
echo_warning() { echo_yellow "$@"; }
echo_error() { echo_red "$@"; }

# Useful functions to simulate maps (because Bash 3 lacks support)

map_get_key() {
    echo ${1%%:*}
}

map_get_value() {
    echo ${1#*:}
}


# Set IFS (Internal Field Separator) to only split on newlines (i.e. don't split on spaces)
# http://stackoverflow.com/questions/4128235/bash-shell-scripting-what-is-the-exact-meaning-of-ifs-n
ifs_newlines() {
    OLD_IFS=$IFS; IFS=$'\n'
}

# Restore IFS after having been changed
ifs_restore() {
    IFS="$OLD_IFS"
}

# Get an array of file names in a given directory
# Returned through a global variable named `__result__`
# 
# Usage:
# get_file_names "/some/path"
# file_names=("${__result__[@]}")
get_file_names() {
    ifs_newlines
    __result__=($(ls -A1 "$1"))
    ifs_restore
}

# Check if an array contains an element
# Usage: contains_element [element] [array]
contains_element() {
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
}

# Verify that a certain tool is installed
verify_installed() {
    for cmd in $@; do
        if ! which $cmd >/dev/null; then
            echo_error "ERROR: This script requires \"$cmd\", which is not currently installed"
            exit 1
        fi
    done
}

# Compare two files to see if they're the same
# Returns true if the file contents are identical
files_same() {
    diff "$file_local" "$file_remote" >/dev/null 2>/dev/null
    return $?
}
