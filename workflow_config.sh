config_dist_files=(
    'app/workflow_params.sh.dist'
    # ...
)

config_remote_host=''
config_remote_username=''
config_remote_path=''

config_open() {
    # Needs to be defined locally
    return
}

# Import local params
if [ -f "${script_dir}/workflow_params.sh" ]; then
    . "${script_dir}/workflow_params.sh"
fi
