#!/bin/bash
# Workflow automization tool

# Bash configuration
shopt -s nullglob # Expand globs with zero matches to zero arguments instead of the glob pattern
shopt -s dotglob # Match dot files
#shopt -s globstar # Not supported in Bash < 4 :'(

cli_args=("$@") # Save a copy of the CLI arguments so we're free to mangle `$@`

# Get the absolute path for the current script
# Source: http://stackoverflow.com/questions/59895
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# This needs to refer to the project root (change this if this script is in a subdirectory)
root_dir="${script_dir}"

# Colors
col_reset="\x1b[39;49;00m"
col_red="\x1b[31;01m"
col_green="\x1b[32;01m"
col_yellow="\x1b[33;01m"
col_blue="\x1b[34;01m"
col_magenta="\x1b[35;01m"
col_cyan="\x1b[36;01m"

show_help() {
    script_name="$(basename "${BASH_SOURCE[0]}")"
    echo "usage: $script_name [--help] [--version]"
}

show_version() {
    echo "version 0.1"
}

# Parse command line options (sets: $cmd, $args, $options)
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
            -*)
                # Other options may be parsed later
                options+=($arg)
                ;;
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

# -----------------
# Commands
# -----------------

cmd_install() {
    echo -e "${col_green}Installing local configuration...${col_reset}"
    
    for dist_file in "${config_dist_files[@]}"; do
        src="$dist_file"
        dst="${dist_file%.dist}" # Remove .dist extension
        
        # Skip if already exists
        if [ -f "${root_dir}/${dst}" ]; then
            echo "Skipping $dst (already exists)"
            continue
        fi
        
        (set -x; cp "${root_dir}/${src}" "${root_dir}/${dst}")
    done
    
    # Check permissions/owners (writables, executables, etc.)
    #TODO
    
    # Install third-party dependencies
    echo -e "${col_green}Installing dependencies...${col_reset}"
    
    # composer install
    # npm install
    # bower install
    
    echo -e "${col_green}Done.${col_reset}"
}

cmd_update() {
    echo -e "${col_green}Updating dependencies.${col_reset}"
    
    # composer install
    # npm install
    # bower install
    
    echo -e "${col_green}Done.${col_reset}"
}

cmd_sync() {
    host="$config_remote_host"
    username="$config_remote_username"
    path_local="$root_dir"
    path_remote="$config_remote_path"
    
    # Paths to exclude from syncing
    # Note: all paths are relative to the source directory, and if you don't add a preceding "/"
    # it will match *all* paths with that name
    # http://askubuntu.com/questions/349613
    excludes="--exclude=.DS_Store --exclude /.git --exclude /.vagrant"
    includes=""
    
    options=""
    restart_server=0
    dry_run=0
    
    # Options parsing
    for arg in "$@"; do
        case "$arg" in
            --) break ;; # Use "--" as a signal to stop options processing
            --exclude=*)
                path=${arg#--exclude=} # Remove the prefixed option name
                excludes="$excludes --exclude $path" # Append the exclude to the list
                ;;
            --include=*)
                path=${arg#--include=} # Remove the prefixed option name
                includes="$includes --include $path" # Append the include to the list
                ;;
            --rsync-options=*)
                rsync_options=${arg#--rsync-options=}
                options="$options $rsync_options"
                ;;
            --restart-server) restart_server=1 ;;
            --dry-run) dry_run=1; options="$options --dry-run" ;;
        esac
    done
    
    echo -e "${col_green}Synchronizing files...${col_reset}"
    
    if [ "$dry_run" = 1 ]; then
        echo -e "${col_yellow}(Dry run)${col_reset}"
    fi
    
    # Sync files
    # -rvtpl recursive, verbose, preserve timestamps and permissions, sync symlinks
    set -x;
    rsync -rvtpl "${path_local}" "${username}@${host}:${path_remote}"\
        $excludes $includes $options --delete
    { set +x; } 2>/dev/null # Quietly disable set -x
    
    if [ "$restart_server" = 1 ]; then
        echo -e "${col_green}Restarting server...${col_reset}"
        ssh "${username}@${host}" "/etc/init.d/apache2 restart"
    fi
    
    echo -e "${col_green}Done.${col_reset}"
}

cmd_edit() {
    host="$config_remote_host"
    username="$config_remote_username"
    path_remote="$config_remote_path"
    
    restart_server=0
    custom_path=''
    
    # Options parsing
    for arg in "$@"; do
        case "$arg" in
            --) break ;;
            --php-ini) custom_path='/etc/php5/cli/conf.d/custom.ini'; restart_server=1 ;;
        esac
    done
    
    if [ -n "$custom_path" ]; then
        vim "scp://${username}@${host}/${custom_path}"
    else
        vim "scp://${username}@${host}/${path_remote}/$1"
    fi
    
    if [ "$restart_server" = 1 ]; then
        echo -e "${col_green}Restarting server...${col_reset}"
        ssh "${username}@${host}" "/etc/init.d/apache2 restart"
    fi
    
    echo -e "${col_green}Done.${col_reset}"
}

cmd_watch() {
    fswatch . "${script_dir}/workflow sync"
}

cmd_open() {
    # User-defined project open command
    config_open
}


# Parse command line options
cmd=""
args=()
options=()
parse_options "$@"

# Not installed yet?
if [ "$cmd" != install ] && [ ! -f "${script_dir}/workflow_params.sh" ]; then
    echo -e "${col_red}This app is not yet installed! Run the \"install\" command.${col_reset}"
    exit 1
fi

# Import configuration
. "${script_dir}/workflow_config.sh"

# Run the specified command
case "$cmd" in
    install) cmd_install "${args[@]}" "${options[@]}" ;;
    update) cmd_update "${args[@]}" "${options[@]}" ;;
    sync) cmd_sync "${args[@]}" "${options[@]}" ;;
    edit) cmd_edit "${args[@]}" "${options[@]}" ;;
    watch) cmd_watch "${args[@]}" "${options[@]}" ;;
    open) cmd_open "${args[@]}" "${options[@]}" ;;
    ?*) # Fallback (non-empty string)
        echo "Unrecognized command \"$cmd\""
        exit 1
        ;;
    *) # Fallback (empty string)
        show_help
        exit 0
        ;;
esac
