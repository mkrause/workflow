#!/bin/bash
# Workflow automatization tool
# https://github.com/mkrause/workflow

# This script expects the following variables to be set:
# - path_root        Directory containing the project.
# - path_script      Directory containing the workflow script and configuration.
if [ -z "$path_root" ] || [ -z "$path_script" ]; then
    echo "Error: missing path variable."
    exit 1
fi

# Bash configuration
shopt -s nullglob # Expand globs with zero matches to zero arguments instead of the glob pattern
shopt -s dotglob # Match dot files
#shopt -s globstar # Not supported in Bash < 4 :'(

cli_args=("$@") # Save a copy of the CLI arguments so we're free to mangle `$@`

# Keep track of command metadata
command_names=()
command_descriptions=()


# --------------------------------
# About this program
# --------------------------------

show_version() {
    echo "version 1.1"
}

show_help() {
    local script_name="$(basename "${BASH_SOURCE[0]}")"
    cat <<EOT
usage: ${script_name} [--help] [--version]
    <command> [<args>]

Commands:
EOT
    
    # Calculate maximum string length among command names (needed for spacing)
    local max_name_length=0
    for command_name in "${command_names[@]}"; do
        local name_length=$(expr length $command_name)
        if [ "$name_length" -gt "$max_name_length" ]; then
            max_name_length=$name_length
        fi
    done
    
    for idx in "${!command_names[@]}"; do
        # Echo information about each command
        echo -n "${command_names[idx]}"
        
        # Add spacing to separate names and descriptions in two columns
        local name_length=$(expr length ${command_names[idx]})
        local col=$(expr $max_name_length - $name_length + 8)
        for (( i=1; i<=col; i++)); do echo -n ' '; done
        
        echo "${command_descriptions[idx]}"
    done
    
    # Extra newline
    echo ""
}


# --------------------------------
# Basic commands
# --------------------------------

command_names+=("self-install")
command_descriptions+=("Install workflow")
cmd_self_install() {
    local force=0
    local path_params="${path_script}/config/params.sh"
    local path_params_dist="${path_script}/config/params.sh.dist"
    
    # Options parsing
    for arg in "${cli_args[@]}"; do
        case "$arg" in
            --force) force=1 ;;
        esac
    done
    
    if [ -f "$path_params" ] && [ "$force" != 1 ]; then
        echo_error "Already installed."
        exit 1
    fi
    
    echo_info "Installing..."
    
    cp "${path_params_dist}" "${path_params}"
    $config_editor "${path_params}"
    
    echo_info "Done"
}


# --------------------------------
# Option parsing
# --------------------------------

# Parse command line options (sets: cmd, args, options)
parse_options() {
    cmd=""
    args=()
    options=()
    
    # http://stackoverflow.com/questions/402377
    for arg in $@; do
        case "$arg" in
            -h | --help)
                show_help
                exit 0
                ;;
            -v | --version)
                show_version
                exit 0
                ;;
            # Anything that looks like an option
            -*)
                # Other options may be parsed later
                options+=($arg)
                ;;
            # Anything else (either a command or argument)
            *)
                if [ -z "$cmd" ]; then
                    cmd=$arg
                else
                    args+=($arg)
                fi
                ;;
        esac
    done
}


# --------------------------------
# Init
# --------------------------------

# Import configuration
. "${path_script}/config/config.sh"

# Import utility functions
. "${path_script}/util.sh"

# Import modules
# (Add your own project modules here)
. "${path_script}/modules/idealbody.sh"

# Parse command line options
cmd=""
args=()
options=()
parse_options "$@"

# Not installed yet?
path_params_rel="config/params.sh"
path_params="${path_script}/${path_params_rel}"
if [ ! -f "$path_params" ] && [ "$cmd" != "self-install" ]; then
    echo_error -n "Couldn't find local configuration. Please create and modify"
    echo_error " '${path_params_rel}' or run the 'self-install' command."
    exit 1
fi

wf_main() {
    # Try to find a matching command, and run it
    local found=0
    for command_name in "${command_names[@]}"; do
        if [ "$command_name" = "$cmd" ]; then
            # Convert to corresponding function name
            local cmd_fn_name="cmd_${command_name/-/_}"
            
            # Run the command
            $cmd_fn_name "${args[@]}" "${options[@]}"
            
            found=1
        fi
    done

    # Fallback
    if [ "$found" == 0 ]; then
        case "$cmd" in
            ?*) # Fallback (non-empty string)
                echo "Unrecognized command \"$cmd\""
                exit 1
                ;;
            *) # Fallback (empty string)
                show_help
                exit 0
                ;;
        esac
    fi
}

# Run
wf_main

# Exit with the status code of the last command run
exit $?
