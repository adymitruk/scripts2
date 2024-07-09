#!/usr/bin/env fish

# Define your directories here
set -l directories ./functions ./completions
set -l report ""
set -l debug_mode; for arg in $argv; if test $arg = "--debug"; set debug_mode true; break; end; end

for dir in $directories
    test $debug_mode; and echo (set_color --background magenta)"Processing $dir"(set_color normal)
    # iterate over each file in the directory
    for file in (ls $dir)
        test $debug_mode; and echo (set_color --background blue)"  Processing $file"(set_color normal)
        test $debug_mode; and echo "  file existence check"
        # install the function if it doesn't exist or if the contents differ
        if not test -e ~/.config/fish/$dir/$file
            test $debug_mode; and echo (set_color --background green)"    Installing $file because it does not exist"(set_color normal)
            cp $dir/$file ~/.config/fish/$dir/$file
            set report "$report\n✅ Installed $file for the first time in $dir"
        else if not diff -q $dir/$file ~/.config/fish/$dir/$file
            test $debug_mode; and echo (set_color --background yellow)"    Updating $file because it differs from the installed version"(set_color normal)
            cp $dir/$file ~/.config/fish/$dir/$file
            set report "$report\n🔄 Updated $file in $dir"
        else
            test $debug_mode; and echo (set_color --background red)"    Not copying $file because it is already installed and up to date"(set_color normal)
            set report "$report\n⏭️ Skipped $file in $dir"
        end
    end
end
echo -e $report