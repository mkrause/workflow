#!/bin/bash
# Workflow automatization tool
# https://github.com/mkrause/workflow

# This script expects the following variables to be set:
# - path_root        Directory containing the project
# - path_script      Directory containing the workflow script and configuration
if [ -z "$path_root" ] || [ -z "$path_script" ]; then
    echo "Error: missing path variable. Note: this script should not be called directly."
    exit 1
fi

# Bash configuration
shopt -s nullglob # Expand globs with zero matches to zero arguments (instead of failing)
shopt -s dotglob # Let globs match dot files
#shopt -s globstar # Not supported in Bash < 4 :'(

cli_args=("$@") # Save a copy of the CLI arguments so we're free to mangle `$@`

# Initialize command list
command_names=()
command_descriptions=()


# --------------------------------
# About this program
# --------------------------------

show_version() {
    echo "version 2.0.1"
}

show_help() {
    local script_name="$(basename "${BASH_SOURCE[0]}")"
    cat <<EOT
usage: ${script_name} [--help] [--version]
    <command> [<arg>...]

Commands:
EOT
    
    # Calculate maximum string length among command names (needed for column spacing)
    local max_name_length=0
    for command_name in "${command_names[@]}"; do
        local name_length="${#command_name}"
        if [ "$name_length" -gt "$max_name_length" ]; then
            max_name_length="$name_length"
        fi
    done
    
    for idx in "${!command_names[@]}"; do
        # Echo information about each command
        echo -n "${command_names[idx]}"
        
        # Add spacing to separate names and descriptions in two columns
        local command_name="${command_names[idx]}"
        local name_length=${#command_name}
        local col_space=8
        local col=$(($max_name_length - $name_length + $col_space))
        for (( i=1; i<=col; i++)); do echo -n ' '; done
        
        echo "${command_descriptions[idx]}"
    done
    
    echo # Extra newline
}


# --------------------------------
# Basic commands
# --------------------------------

command_names+=("self-installed")
command_descriptions+=("Whether workflow has been installed")
cmd_self_installed() {
    local path_env="${path_root}/.env"
    local path_env_dist="${path_root}/.env.example"
    
    test -f "$path_env"
    exit $?
}

command_names+=("self-install")
command_descriptions+=("Install workflow")
cmd_self_install() {
    local force=0
    local path_env="${path_root}/.env"
    local path_env_dist="${path_root}/.env.example"
    
    # Options parsing
    for arg in "${cli_args[@]}"; do
        case "$arg" in
            --force) force=1 ;;
        esac
    done
    
    if [ -f "$path_env" ] && [ "$force" != 1 ]; then
        print_error "Already installed."
        exit 1
    fi
    
    print_info "Installing..."
    
    cp "${path_env_dist}" "${path_env}"
    $config_editor "${path_env}"
    
    print_info "Done"
}

command_names+=("wf-config-path")
command_descriptions+=("Get path to config file")
cmd_wf_config_path() {
    echo "${path_script}/config/config.sh"
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
for module_path in ${path_script}/modules/*.sh; do
    . "$module_path"
done

# Parse command line options
cmd=""
args=()
options=()
parse_options "$@"

# Not installed yet?
path_env_rel=".env"
path_env="${path_root}/${path_env_rel}"
if [ ! -f "$path_env" ] && [ "$cmd" != "self-installed" ] && [ "$cmd" != "self-install" ]; then
    print_error -n "Couldn't find local configuration. Please create and modify"
    print_error " '${path_env_rel}' or run the 'self-install' command."
    exit 1
fi

wf_main() {
    # Try to find a matching command, and run it
    local found=0
    for command_name in "${command_names[@]}"; do
        if [ "$command_name" = "$cmd" ]; then
            # Convert to corresponding function name
            local cmd_fn_name="cmd_$(echo ${command_name} | tr - _)"
            
            # Run the command
            $cmd_fn_name "${args[@]}" "${options[@]}"
            local cmd_return=$?
            
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
    
    # Return with the status code of the last command run
    return $cmd_return
}

# Run
wf_main
