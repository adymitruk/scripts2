function __fish_gh_get_pr_list
    # use gh pr list --json number,title,author,headRepository | jq -r '.[] | "\(.number)\t\(.author.login)\t\(.title)\tgit@github.com:\(.author.login)/\(.headRepository.name).git"' to get the list
    gh pr list --json number,title,author,headRepository | jq -r '.[] | "\(.number) \(.author.login) \(.title) \(.author.login)\tgit@github.com:\(.author.login)/\(.headRepository.name).git"'
end

function __fish_gh_pr_list_for_remotes
    
    #get the git repo path
    set -l repo_path (git rev-parse --show-toplevel)

    #check for a cache file for this function for this git repo
    set -l cache_dir ~/.cache/gh_pr_list
    set -l cache_file $cache_dir/$repo_path/pr_cache.txt
    #get dir of pr_cache
    set -l cache_dir (dirname $cache_file)
    #create dir if not present
    mkdir -p $cache_dir

    if test -f $cache_file
        #check if older than 5 mins, if so, get new list
        set -l current_time (date +%s)
        set -l file_mod_time (stat -c %Y $cache_file)
        set -l time_diff (math $current_time - $file_mod_time)
        if test $time_diff -gt 300
            __fish_gh_get_pr_list > $cache_file
        end
    else
        __fish_gh_get_pr_list > $cache_file
    end
    cat $cache_file
end

complete -c gh_add_remote_from_pr -f -a "\('option 1' 'value 1'\)" -d "select an option