
# Distribution files that need to be copied and modified locally
config_dist_files=()

config_remote_host='example.com'
config_remote_username='example'
config_remote_path='/var/www/example'

# Import local params
if [ -f "${script_dir}/params.sh" ]; then
    . "${script_dir}/params.sh"
fi
