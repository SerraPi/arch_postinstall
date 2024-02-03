#!/bin/bash

YELLOW='\033[93m'
GREEN='\033[92m'
NC='\033[0m' 

makepkg_conf="/etc/makepkg.conf"
num_threads=
verbose_mode=true
sed_commands=()

main() {
    check_sudo
    calculate_num_threads
    display_message "Checking $makepkg_conf" "Makepkg.conf"

    if [ -s "$makepkg_conf" ]; then
        if is_makeflags_commented; then
            uncomment_makeflags
        fi

        if is_j_value_present; then
            update_j_value
        else
            add_j_flag_if_missing
        fi

        execute_sed_commands

        if [ "$verbose_mode" = true ]; then
            display_message "${GREEN}Makepkg configuration updated successfully!${NC}" "Makepkg.conf"
        fi
    else
        display_message "Error: $makepkg_conf not found or is empty." "Makepkg.conf"
    fi
}

check_sudo() {
    sudo -v || (display_message "Error: This script requires sudo privileges. Exiting." "Makepkg.conf" && exit 1)
}

calculate_num_threads() {
    num_threads=$(nproc --all)
    ((num_threads <= 2)) && num_threads=2 || ((num_threads -= 2))
}

is_makeflags_commented() {
    sudo grep -qE '^\s*#.*MAKEFLAGS' "$makepkg_conf"
}

is_j_value_present() {
    if sudo grep -qE '^\s*(#)?MAKEFLAGS\s*=\s*.*-j[0-9]+' "$makepkg_conf" && ! sudo grep -qE '^\s*(#)?MAKEFLAGS\s*=\s*""' "$makepkg_conf"; then
        display_message "Detected -j value in MAKEFLAGS of $makepkg_conf" "Makepkg.conf"
        return 0
    fi
    display_message "No -j value detected in $makepkg_conf" "Makepkg.conf"
    return 1
}

add_sed_command() {
    sed_commands+=("$1")
}

execute_sed_commands() {
    for cmd in "${sed_commands[@]}"; do
        eval "$cmd"
    done
}

uncomment_makeflags() {
    add_sed_command "sudo sed -i -e '/^\s*#.*MAKEFLAGS/s/^#//' \"$makepkg_conf\""
    display_message "Uncommenting MAKEFLAGS in $makepkg_conf" "Makepkg.conf"
}

update_j_value() {
    add_sed_command "sudo sed -i -e \"/^\s*MAKEFLAGS/s/-j[0-9]*/-j$num_threads/\" \"$makepkg_conf\""
    display_message "Changing -j value in $makepkg_conf to -j$num_threads" "Makepkg.conf"
}

add_j_flag_if_missing() {
    if sudo grep -qE '^\s*MAKEFLAGS\s*=\s*".*"' "$makepkg_conf"; then
        add_sed_command "sudo sed -i -e 's/^\s*MAKEFLAGS\s*=\s*\"\(.*\)\"/MAKEFLAGS=\"\1 -j$num_threads\"/' \"$makepkg_conf\""
    elif sudo grep -qE '^\s*MAKEFLAGS\s*=""' "$makepkg_conf" || sudo grep -qE '^\s*MAKEFLAGS\s*=\s*""' "$makepkg_conf"; then
        add_sed_command "sudo sed -i -e 's/^\s*MAKEFLAGS\s*=\s*\"\(.*\)\"/MAKEFLAGS=\"-j$num_threads\"/' \"$makepkg_conf\""
    fi
    display_message "Adding -j$num_threads to $makepkg_conf (MAKEFLAGS)" "Makepkg.conf"
}

display_message() {
    [ "$verbose_mode" = false ] && return
    local message="$1"
    local file_name="${YELLOW}$2${NC}"
    echo -e "[$file_name] $message"
}


while getopts ":s" opt; do
    case $opt in
        s) verbose_mode=false ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

main
