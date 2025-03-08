#! /bin/bash

# find the latest start tag
start_tag=$(git tag --sort=-v:refname | grep start- | head -n 1)
echo "Starting from tag: $start_tag"

# get cherry-pick commits 
all_cherry_picks=$(git log --all --ancestry-path ^$start_tag --grep cherry-pick --pretty=format:"%h %at %ct %s" )
# filter out the commits that don't have the same committer time as the author time
cherry_picks=$(echo "$all_cherry_picks" | awk '{if ($2 == $3) print $0}')

# sort by the second column (author time)
cherry_picks=$(echo "$cherry_picks" | sort -k2,2n)

echo "Cherry picks:"
echo "$cherry_picks"

# prompt the user to continue
read -p "Continue? (y/n) " continue
if [ "$continue" != "y" ]; then
    echo "Aborting"
    exit 1
fi

# cherry-pick the commits
echo "$cherry_picks" | while read -r commit author_time commit_time message; do
    echo "sha: $commit"
    echo "author_time: $author_time"
    echo "commit_time: $commit_time"
    echo "message: $message"
    git cherry-pick $commit
	# check if failed
	if [ $? -ne 0 ]; then
		echo "Failed to cherry-pick $commit"
		exit 1
	fi
done
