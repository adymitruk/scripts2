function gh-remote-add
    set -l cache_path ~/.cache/gh-remote-add
    set -x UTILS_LOG $cache_path/debug.log

    log "gh-remote-add called with arguments: $argv"

    set -l author (string match -r --groups-only 'git@github\.com:(.*)/.*\.git' $argv[1])

    git remote add $author $argv[1]
    if test $status -eq 0
        log "Successfully added remote $author $args[1]"
    else
        log "Failed to add remote $author $args[1]"
    end
end