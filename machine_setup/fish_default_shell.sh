#!/bin/bash

function fish_default_shell_check() {
    if grep -q "$(which fish)" /etc/passwd; then
        return 0
    else
        return 1
    fi
}
if [ "$1" == "check" ]; then
    fish_default_shell_check
    exit $?
fi



if ! grep -q "/usr/bin/fish" /etc/shells; then
    echo "/usr/bin/fish" | sudo tee -a /etc/shells
fi
chsh -s /usr/bin/fish
