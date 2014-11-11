
config_editor=vim

config_open() {
    # Needs to be defined locally
    return
}

# Import local params
if [ -f "${path_script}/config/params.sh" ]; then
    . "${path_script}/config/params.sh"
fi
