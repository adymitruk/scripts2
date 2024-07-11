function __fish_gh_fork_remotes
    # use gh to grab all remotes from the users that made PRs include date of pr
    gh pr list --json author,headRepository --state all | jq -r '.[] | "\(.author.login) git@github.com:\(.author.login)/\(.headRepository.name).git"' | sort | uniq 
end

complete -f -c gh-remote-add -a '(__fish_gh_fork_remotes)'

