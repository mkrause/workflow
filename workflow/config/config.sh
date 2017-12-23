
wf_configure() {
    local path_current="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local path_wf="${path_current}/.."
    local path_project="${path_current}/../../.."
    
    . "${path_wf}/util/bash_setup.sh"
    . "${path_wf}/util/printing.sh"
    . "${path_wf}/util/configuration.sh"
    
    
    # Defaults
    
    config_editor=vim
    
    config_open() {
        # Needs to be defined locally
        return
    }
    
    
    # Load machine-local environment variables
    
    config_load || { print_error "Missing config: .env has not yet been installed"; exit 1; }
}

wf_configure
