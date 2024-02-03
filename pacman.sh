#!/bin/bash

YELLOW='\033[93m'
GREEN='\033[92m'
NC='\033[0m'

pacman_conf="/etc/pacman.conf"
color_enabled=true
parallel_downloads=true
parallel_download_count=8
verbose_mode=true
sed_commands=()

main() {
    check_sudo
    display_message "Checking $pacman_conf"
    if [ -s "$pacman_conf" ]; then
        display_message "Success: $pacman_conf exists and is not empty."
        if $color_enabled; then
            if is_color_commented; then
                uncomment_color
            fi
        fi
        if $parallel_downloads; then
            if is_paralleldownloads_commented; then
                uncomment_paralleldownloads
            fi
            set_paralleldownloads_value
        fi
        execute_sed_commands
    else
        display_message "Error: $pacman_conf not found or is empty."
    fi
}

check_sudo() {
    sudo -v || (display_message "Error: This script requires sudo privileges. Exiting." && exit 1)
}

is_color_commented() {
    sudo grep -qE '^\s*#.*Color' "$pacman_conf"
}

is_paralleldownloads_commented() {
    sudo grep -qE '^\s*#.*ParallelDownloads' "$pacman_conf"
}

uncomment_color() {
    add_sed_command "sudo sed -i '/^\s*#.*Color/s/^#//g' \"$pacman_conf\""
}

uncomment_paralleldownloads() {
    add_sed_command "sudo sed -i '/^\s*#.*ParallelDownloads/s/^#//g' \"$pacman_conf\""
}

set_paralleldownloads_value() {
    add_sed_command "sudo sed -i '/^\s*ParallelDownloads\s*=/s/\(=.*\)/= $parallel_download_count/' \"$pacman_conf\""
    display_message "ParallelDownloads value set to $parallel_download_count"
}

add_sed_command() {
    sed_commands+=("$1")
}

execute_sed_commands() {
    for cmd in "${sed_commands[@]}"; do
        eval "$cmd"
    done
}

display_message() {
    [ "$verbose_mode" = false ] && return
    local message="$1"
    local file_name="${YELLOW}$(basename "$pacman_conf")${NC}"
    echo -e "[$file_name] $message"
}

while getopts ":s" opt; do
    case $opt in
        s) verbose_mode=false ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

main
