#!/bin/bash
# Workflow automatization tool

# This script expects the following variables to be set:
# - root_dir        Directory containing the project.
# - script_dir      Directory containing the workflow script and configuration.

# We need to be called with a root directory variable already set
if [ -z "$root_dir" ]; then
    echo "Error: no root directory given."
    exit 1
fi

# Bash configuration
shopt -s nullglob # Expand globs with zero matches to zero arguments instead of the glob pattern
shopt -s dotglob # Match dot files
#shopt -s globstar # Not supported in Bash < 4 :'(

cli_args=("$@") # Save a copy of the CLI arguments so we're free to mangle `$@`

show_help() {
    cat <<'EOT'
usage: workflow [--help] [--version]
                <command> [<args>]

Commands:
install     Set up a newly created working directory.
configure   Configure the project.
update      Update dependencies.
outdated    Check for any outdated dependencies.
status      Check the state of the project.
build       Run build scripts.
test        Run test scripts.
run         Run the project.
deploy      Deploy the project.
sync        Upload files to a remote server.
watch       Watch for changes in the project directory, and synchronize automatically.
edit        Edit files on a remote server.
EOT
}

show_version() {
    echo "version 0.1"
}

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

# -----------------
# Util
# -----------------

# Verify that a certain tool is installed
verify_installed() {
    for cmd in $@; do
        if ! which $cmd >/dev/null; then
            echo_red "ERROR: This script requires \"$cmd\", which is not currently installed"
            exit 1
        fi
    done
}

# Colors
col_reset="\x1b[39;49;00m"
col_red="\x1b[31;01m"
col_green="\x1b[32;01m"
col_yellow="\x1b[33;01m"
col_blue="\x1b[34;01m"
col_magenta="\x1b[35;01m"
col_cyan="\x1b[36;01m"

echo_color() {
    if [ "$2" = "-n" ]; then
        text="${@:3}" # Array slice starting from 3
        echo -en "${1}${text}${col_reset}"
    else
        text="${@:2}" # Array slice starting from 2
        echo -e "${1}${text}${col_reset}"
    fi
}

echo_red() { echo_color $col_red $@; }
echo_green() { echo_color $col_green $@; }
echo_yellow() { echo_color $col_yellow $@; }
echo_blue() { echo_color $col_blue $@; }
echo_magenta() { echo_color $col_magenta $@; }
echo_cyan() { echo_color $col_cyan $@; }

# -----------------
# Commands
# -----------------

cmd_install() {
    cmd_configure "$@"
    cmd_update "$@"
    
    # Check permissions/owners (e.g. file write permissions)
    #TODO
}

cmd_configure() {
    echo_green "Configuring local configuration..."
    
    local force=0
    
    # Options parsing
    for arg in "$@"; do
        case "$arg" in
            --) break ;; # Use "--" as a signal to stop options processing
            --force) force=1 ;;
        esac
    done
    
    for dist_file in "${config_dist_files[@]}"; do
        src="$dist_file"
        dst="${dist_file%.dist}" # Remove .dist extension
        
        if [ -f "${root_dir}/${dst}" ]; then
            # Skip if already exists
            echo "Already exists: $dst"
            
            # Skip the rest of configuration command, unless we're using --force
            if [ "$force" = 0 ]; then
                continue
            fi
        else
            # Copy file
            echo "Copying from .dist: $dst"
            (set -x; cp "${root_dir}/${src}" "${root_dir}/${dst}") # Subshell with debug mode
        fi
        
        # Allow the user to edit the newly copied file
        subl -wn "${root_dir}/${dst}"
    done
}

cmd_update() {
    verify_installed npm bower
    
    echo_green "Updating dependencies."
    
    # npm
    npm update
    
    # bower
    (cd "${root_dir}/web" && bower --allow-root update)
}

cmd_outdated() {
    verify_installed npm bower
    
    # npm
    echo_green "Checking npm..."
    # Get all outdated packages, filter on lines that look like "[package]@[version]"
    npm outdated | grep -E '^[^ ]+@[^ ]+'
    # Note: older versions of npm don't include devDependencies in "npm outdated":
    # https://github.com/npm/npm/issues/3250
    echo_yellow "To update, run \"npm update\""
    
    # bower
    echo_green "Checking bower..."
    # Have bower generate the list of dependencies, then check for lines indicating a new release
    # (Also, remove the tree display prefix)
    cd "${root_dir}/web"
    bower --allow-root list # | grep 'available\|latest' | sed -E 's/^[^a-zA-Z0-9]+//'
    cd "${root_dir}"
    echo_yellow "To update, run \"bower update\""
}

cmd_status() {
    verify_installed git
    git status
}

cmd_build() {
    verify_installed grunt
    grunt
}

cmd_test() {
    #...
    return
}

cmd_run() {
    verify_installed npm
    npm start
}

cmd_deploy() {
    local host="$config_remote_host"
    local username="$config_remote_username"
    local path_remote="$config_remote_path"
    
    local update=0
    local build=0
    local restart_server=0
    
    # Options parsing
    for arg in "$@"; do
        case "$arg" in
            --) break ;; # Use "--" as a signal to stop options processing
            --update) update=1 ;;
            --no-update) update=0 ;;
            --build) build=1 ;;
            --no-build) build=0 ;;
            --restart-server) restart_server=1 ;;
            --no-restart-server) restart_server=0 ;;
        esac
    done
    
    # Start server (only when not already started)
    # cmd="forever -m 1 --sourceDir ${path_remote}/src --watch --watchDirectory ${path_remote}/src -o /tmp/out.log -e /tmp/error.log start main.js"
    
    cmd_sync "$@"
    
    # Update
    if [ "$update" = 1 ]; then
        ssh "${username}@${host}" "cd ${path_remote} && ./wf update"
    fi
    
    # Build
    if [ "$build" = 1 ]; then
        echo_green "Building files..."
        ssh "${username}@${host}" "cd ${path_remote} && grunt"
    fi
    
    # Restart server
    if [ "$restart_server" = 1 ]; then
        echo_green "Restarting server..."
        local forever_cmd="forever restart main.js"
        ssh "${username}@${host}" "$forever_cmd"
    fi
}

cmd_sync() {
    local host="$config_remote_host"
    local username="$config_remote_username"
    local path_local="${root_dir}/" # Trailing slash so it syncs the directory contents
    local path_remote="$config_remote_path"
    
    # Paths to exclude from syncing
    # Note: all paths are relative to the source directory, and if you don't add a preceding "/"
    # it will match *all* paths with that name
    # http://askubuntu.com/questions/349613
    local excludes="--exclude-from .gitignore --exclude .DS_Store --exclude /.git"
    local includes=""
    
    local options=""
    local dry_run=0
    
    # Options parsing
    for arg in "$@"; do
        case "$arg" in
            --) break ;; # Use "--" as a signal to stop options processing
            --exclude=*)
                local path=${arg#--exclude=} # Remove the prefixed option name
                excludes="$excludes --exclude $path" # Append the exclude to the list
                ;;
            --include=*)
                local path=${arg#--include=} # Remove the prefixed option name
                includes="$includes --include $path" # Append the include to the list
                ;;
            --rsync-options=*)
                rsync_options=${arg#--rsync-options=}
                options="$options $rsync_options"
                ;;
            --dry-run) dry_run=1; options="$options --dry-run" ;;
        esac
    done
    
    echo_green "Synchronizing files..."
    
    if [ "$dry_run" = 1 ]; then
        echo_yellow "(Dry run)"
    fi
    
    # Sync files
    # -rvtpl recursive, verbose, preserve timestamps and permissions, sync symlinks
    set -x;
    rsync -rvtpl "${path_local}" "${username}@${host}:${path_remote}"\
        $includes $excludes $options --delete
    { set +x; } 2>/dev/null # Quietly disable set -x
    
    #TODO: provide a way to actually install the project if it hasn't been installed yet?
}

cmd_edit() {
    local host="$config_remote_host"
    local username="$config_remote_username"
    local path_remote="$config_remote_path"
    
    local restart_server=0
    local custom_path=''
    
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
        echo_green "Restarting server..."
        ssh "${username}@${host}" "/etc/init.d/apache2 restart"
    fi
}

cmd_watch() {
    # A few alternatives:
    # inotify (Linux)
    # https://github.com/alandipert/fswatch (OS X)
    # https://github.com/axkibe/lsyncd
    
    verify_installed fswatch && fswatch . "${root_dir}/wf deploy $@"
}


# Parse command line options
cmd=""
args=()
options=()
parse_options "$@"

# Import configuration
. "${script_dir}/config.sh"

# Not installed yet?
if [ "$cmd" != "install" ] && [ ! -f "${script_dir}/params.sh" ]; then
    echo_red "This app is not yet installed! Run the \"install\" command."
    exit 1
fi

# Run the specified command
case "$cmd" in
    install)
        cmd_install "${args[@]}" "${options[@]}" ;;
    configure)
        cmd_configure "${args[@]}" "${options[@]}" ;;
    update)
        cmd_update "${args[@]}" "${options[@]}" ;;
    outdated)
        cmd_outdated "${args[@]}" "${options[@]}" ;;
    status)
        cmd_status "${args[@]}" "${options[@]}" ;;
    build)
        cmd_build "${args[@]}" "${options[@]}" ;;
    test)
        cmd_test "${args[@]}" "${options[@]}" ;;
    run)
        cmd_run "${args[@]}" "${options[@]}" ;;
    deploy)
        cmd_deploy "${args[@]}" "${options[@]}" ;;
    sync)
        cmd_sync "${args[@]}" "${options[@]}" ;;
    edit)
        cmd_edit "${args[@]}" "${options[@]}" ;;
    watch)
        cmd_watch "${args[@]}" "${options[@]}" ;;
    ?*) # Fallback (non-empty string)
        echo "Unrecognized command \"$cmd\""
        exit 1
        ;;
    *) # Fallback (empty string)
        show_help
        exit 0
        ;;
esac

echo_green "Done."
