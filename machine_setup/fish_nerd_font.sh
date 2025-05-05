#!/bin/bash


function check_if_installed {
    # Check if fonts are installed
    if fc-list | grep -q "MesloLGS NF"
    then
        echo "Meslo Nerd Fonts are already installed."
        return 0
    else
        return 1
    fi
}

if [ "$1" == "check" ]; then
    check_if_installed
    exit $?
fi


if check_if_installed; then
    read -p "The fonts are already installed. Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
fi

# check if wget is installed
if ! command -v wget >/dev/null 2>&1; then
    echo "wget is not installed. Please install it first."
    exit 1
fi

# Download and install the Meslo Nerd Font
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

# Move the downloaded fonts to the correct directory
mkdir -p ~/.local/share/fonts
mv MesloLGS*.ttf ~/.local/share/fonts/

# Update the font cache
fc-cache -f -v



