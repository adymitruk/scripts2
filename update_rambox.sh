#!/bin/bash

global_url=""
global_version=""
global_file_path=""

function get_latest_version() {
    echo getting latest version
    global_url=$(curl -sI https://github.com/ramboxapp/download/releases/latest | grep ^location: | sed -n 's/^location: //p' | tr -d '\r')
    if [[ -z "$global_url" ]]; then
        echo "Failed to fetch the URL. Exiting..." $global_url
        exit 1
    fi
    echo "url: $global_url"
    global_version=$(echo "$global_url" | awk -F"/" '{print $NF}' | sed 's/v//')
    if [[ -z "$global_version" ]]; then
        echo "Failed to parse the version. Exiting..."
        exit 1
    fi
    echo -e "Latest version: $global_version"
}

function download_file() {
    echo downloading file
    global_file_path="$HOME/Downloads/Rambox-$global_version-linux-x64.deb"
    echo -e "file_path with hidden characters: $(echo -e "$global_file_path" | cat -v)"
    echo "file path: $global_file_path"
    if [ -f "$global_file_path" ]; then
        echo "File already downloaded."
    else
        echo "File not found. Downloading..."
        url="https://github.com/ramboxapp/download/releases/download/v${global_version}/Rambox-${global_version}-linux-x64.deb"
        echo "url:"
        echo "URL: ${url}"
        curl -L --output "$global_file_path"  "$url"
        if [[ $? -ne 0 ]]; then
            echo "Failed to download the file. Exiting..."
            exit 1
        fi
    fi
}

function install_package() {
    echo "Installing the package" $global_file_path
    sudo dpkg -i "$global_file_path"
    if [[ $? -ne 0 ]]; then
        echo "Failed to install the package. Exiting..."
        exit 1
    fi
}

installed_version=$(zcat /usr/share/doc/rambox/changelog.gz | awk 'NR==1{print $2}' | tr -d '(' | tr -d ')')
if [[ -z "$installed_version" ]]; then
    echo "Rambox is not installed. Proceeding with the download and installation..."
    get_latest_version
    download_file
    install_package
else
    echo "Installed version: $installed_version"
    get_latest_version
    if [[ "$global_version" == "$installed_version" ]]; then
        echo "Rambox is already at the latest version. Exiting..."
        exit 0
    fi
    download_file
    install_package
fi



