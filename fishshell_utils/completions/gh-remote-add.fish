function __fish_gh_fork_remotes
    set -l cache_path ~/.cache/gh-remote-add
    set -l cache_age 300 # 5 minutes
    set -x UTILS_LOG $cache_path/debug.log # if no UTILS_LOG is set, it will not log anything

    log "1. checking if inside a git repository"
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        log "Not inside a git repository. Returning empty array."
        return
    end
    log "inside a git repository"

    set -l repo_name (git rev-parse --show-toplevel | xargs basename)
    set -l cache_file $cache_path/$repo_name.cache
    mkdir -p $cache_path

    set -l authors ""

    log "2. getting remotes"
    set -l remotes (git remote)
    log "remotes: $remotes"

    log "3. checking if cache file needs to be refreshed"
    if cache-refresh-needed $cache_file $cache_age
        log "3.1, new cache file needed"
        log "3.2, getting authors from github"
        set -l git_urls (gh pr list --json author,headRepository --state all | jq -r '.[] | "git@github.com:\(.author.login)/\(.headRepository.name).git"')

        log "git urls from github"
        log $git_urls
        set -l unique_git_urls ""
        log "3.3 make unique git urls list"
        for line in $git_urls 
            log "filtering line $line"
            if contains $line $unique_git_urls
                log "line $line already in unique_git_urls"
            else
                set unique_git_urls "$unique_git_urls$line\n"
                log "line $line added to unique_git_urls"
            end
        end
        log "3.4 write unique authors and remotes to cache file"
        set -l first_line 1
        for line in $unique_git_urls
            if test $first_line -eq 1
                echo $line > $cache_file
                set first_line 0
            else
                echo $line >> $cache_file
            end
        end
        log "3.5 cache file updated"
        log "Refreshed cache file contents:"
        for line in (cat $cache_file | string split '\n')
            log "  $line"
        end
    end

    log "4. checking for new authors"
    set -l new_authors ""
    set -l processed_authors 0
    for git_url in (cat $cache_file | string split '\n')
        log "4.1 processing git_url $git_url"
        set author (echo $git_url | string match -r --groups-only 'git@github\.com:(.*)/.*\.git')
        log "author $author"
        if not contains $author $remotes
            echo $git_url
            log "Author $author not in remotes"
            set new_authors "$new_authors$git_url\n"
        else
            log "Author $author already in remotes"
        end
        set processed_authors (math $processed_authors + 1)
    end

    log "Processed $processed_authors authors in the loop"
    log "New authors added:"
    for line in (echo $new_authors | string split '\n')
        log "  $line"
    end
    log "Loop finished processing authors"
end

complete -f -c gh-remote-add -a '(__fish_gh_fork_remotes)'