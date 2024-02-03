#!/bin/bash

check_sudo() {
    sudo -v || (echo "Error: This script requires sudo privileges. Exiting." && exit 1)
}

create_temp_dir() {
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit
}

install_dependencies() {
    sudo pacman -S --needed git base-devel
}

clone_yay() {
    git clone https://aur.archlinux.org/yay.git
}

build_and_install_yay() {
    cd yay
    makepkg -si
}

cleanup() {
    cd "$temp_dir" && rm -rf yay
}

main() {
    check_sudo
    create_temp_dir
    install_dependencies
    clone_yay
    build_and_install_yay
    cleanup
}

main