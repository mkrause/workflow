
config_editor=vim

config_open() {
    # Needs to be defined locally
    return
}

# Import local params
if [ -f "${script_dir}/config/params.sh" ]; then
    . "${script_dir}/config/params.sh"
fi
