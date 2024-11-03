#!/bin/bash
# Install the Yubico Authenticator on Kubuntu 24.04.1

url="https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-linux.tar.gz"

function yubico_authenticator_check() {
    # use which to check if yubico-authenticator is in the PATH
    if [ -f "${HOME}/.local/share/applications/com.yubico.authenticator.desktop" ] && \
       systemctl is-active --quiet pcscd; then
        return 0
    fi
    return 1
}

if [ "$1" == "check" ]; then
    yubico_authenticator_check
    exit $?
fi

if yubico_authenticator_check; then
    read -p "Yubico Authenticator is already installed. Do you want to reinstall? (y/n) " answer
    if [[ "$answer" != "y" ]]; then
        exit 0
    fi
fi

# Install the Yubico Authenticator using the link from the Yubico website
mkdir -p $HOME/tools
curl -Ls $url | tar -xzf - -C $HOME/tools
#check if the files were downloaded correctly
if [ ! -d "$HOME/tools"/yubico-authenticator* ]; then
    echo "Failed to download the Yubico Authenticator"
    exit 1
fi
# get the extracted directory name
extracted_dir=$(ls -d $HOME/tools/yubico-authenticator*)
echo "extracted_dir: $extracted_dir"
# Move the application to the applications menu
cd $extracted_dir
./desktop_integration.sh --install
cd -

#install pcscd
sudo apt install -y pcscd
# Start the pcscd service
sudo systemctl enable pcscd
sudo systemctl start pcscd
