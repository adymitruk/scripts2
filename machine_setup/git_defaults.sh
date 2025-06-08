#!/bin/bash
# This script is used to configure git default settings

# order: 101

declare -A git_config_map
git_config_map=(
    ["pull.rebase"]="false"
    ["push.default"]="current"
    ["core.editor"]="vim"
    ["log.decorate"]="true"
    ["status.showUntrackedFiles"]="all"
)

function git_defaults_check() {
    for key in "${!git_config_map[@]}"; do
        if ! git config --global --get "$key" > /dev/null; then
            return 1
        fi
    done
    return 0
}

if [ "$1" == "check" ]; then
    git_defaults_check
    exit $?
fi

if git_defaults_check; then
    read -p "Some git config settings are already set. Do you want to reconfigure them? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            for key in "${!git_config_map[@]}"; do
                git config --global "$key" "${git_config_map[$key]}"
            done
        ;;
        * )
            echo "Skipping reconfiguration."
        ;;
    esac
else
    for key in "${!git_config_map[@]}"; do
        git config --global "$key" "${git_config_map[$key]}"
    done
    echo "Current global git config:"
    git config --global --list
fi



