#!/bin/bash

function fisher_check() {
    if fish -c "type fisher >/dev/null 2>&1"; then
        return 0
    else
        return 1
    fi
}
if [ "$1" == "check" ]; then
    fisher_check
    exit $?
fi

if ! fisher_check; then
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi
