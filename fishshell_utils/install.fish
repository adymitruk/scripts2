#!/usr/bin/env fish

# Define your directories here
set -l directories ./functions ./completions
for dir in $directories
    echo (set_color --background magenta)"Processing $dir"(set_color normal)
    # iterate over each file in the directory
    for file in (ls $dir)
        echo (set_color --background blue)"  Processing $file"(set_color normal)
        # install the function if it doesn't exist or if the contents differ
        echo "  file existence check"
        if not test -e ~/.config/fish/$dir/$file
            echo (set_color --background green)"    Installing $file because it does not exist"(set_color normal)
            cp $dir/$file ~/.config/fish/$dir/$file
        else if not diff -q $dir/$file ~/.config/fish/$dir/$file
            echo (set_color --background yellow)"    Updating $file because it differs from the installed version"(set_color normal)
            cp $dir/$file ~/.config/fish/$dir/$file
        else
            echo (set_color --background red)"    Not copying $file because it is already installed and up to date"(set_color normal)
        end
    end
end