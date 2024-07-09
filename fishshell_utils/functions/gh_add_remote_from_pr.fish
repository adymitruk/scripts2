function gh_add_remote_from_pr --description 'Add a remote using the author login as the remote name from a GitHub PR'
    set pr_number $argv[1]
    if test -z "$pr_number"
        echo "Usage: add_remote_from_pr <pr_number>" >&2
        return 1
    end

    set pr_info (gh pr view $pr_number --json headRepository,author | jq -r '"\(.author.login) git@github.com:\(.author.login)/\(.headRepository.name).git"')
    set remote_name (echo $pr_info | awk '{print $1}')
    set remote_url (echo $pr_info | awk '{print $2}')

    #get all remote names
    set remote_names (git remote)
    # compare each remote name to the remote name we're trying to add
    # if it's not in the list, add it
    if not contains $remote_name $remote_names
        git remote add $remote_name $remote_url
        echo "Remote '$remote_name' added with URL '$remote_url'"
    else
        echo "Remote '$remote_name' already exists"
    end
end