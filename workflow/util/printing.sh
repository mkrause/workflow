#!/usr/bin/env bash

# Colors
col_reset="\x1b[39;49;00m"
col_red="\x1b[31;01m"
col_green="\x1b[32;01m"
col_yellow="\x1b[33;01m"
col_blue="\x1b[34;01m"
col_magenta="\x1b[35;01m"
col_cyan="\x1b[36;01m"


print_color() {
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

print_red() { print_color --color=$col_red "$@"; }
print_green() { print_color --color=$col_green "$@"; }
print_yellow() { print_color --color=$col_yellow "$@"; }
print_blue() { print_color --color=$col_blue "$@"; }
print_magenta() { print_color --color=$col_magenta "$@"; }
print_cyan() { print_color --color=$col_cyan "$@"; }

print_info() { print_cyan "[info] $@"; }
print_success() { print_green "[succ] $@"; }
print_warning() { print_yellow "[warn] $@"; }
print_error() { print_red "[fail] $@"; }
