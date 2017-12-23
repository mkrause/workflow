#!/usr/bin/env bash

path_current="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # https://stackoverflow.com/questions/59895
. "${path_current}/printing.sh"


# https://stackoverflow.com/questions/9376904
find_up() {
    # Recursively list a file from current directory up the tree to root
    [[ -n $1 ]] || { echo "find_up [ls-opts] name"; return 1; }
    local THERE=$path_current RC=2
    while [[ $THERE != / ]]
        do [[ -e $THERE/${2:-$1} ]] && { ls ${2:+$1} $THERE/${2:-$1}; RC=0; }
            THERE="$(dirname $THERE)"
        done
    [[ -e $THERE/${2:-$1} ]] && { ls ${2:+$1} /${2:-$1}; RC=0; }
    return $RC
}

config_check() {
    find_up ".env" > /dev/null || { print_info "Search for .env found no matches"; return 1; }
    
    # TODO: check conformance with .env.example?
    
    return 0
}

config_load() {
    config_check || return $?
    
    local path_env="$(find_up ".env")"
    . "${path_env}"
    
    return 0
}
