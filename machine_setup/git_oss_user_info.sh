#!/bin/bash
# This script is used to configure git user information for a specific directory
# Typically used for open source contributions or different work contexts

alternate_config_path="${HOME}/.gitconfig.oss"

function git_oss_user_info_check() {
   # check for a includeIf section in the global git config
   if git config --global --get-regexp "includeIf.gitdir:*" &> /dev/null; then
      echo "Alternate Git User Email already configured"
      return 0
   else
      echo "Alternate Git User Email not configured"
      return 1
   fi
}

if [ "$1" == "check" ]; then
  git_oss_user_info_check
  exit $?
fi
echo "What is your OSS directory?"
read -p "Enter your OSS directory: " oss_directory

# Expand ~ to $HOME in the oss_directory path
oss_directory="${oss_directory/#\~/$HOME}"

echo "Configuring Alternate Git User Email"
read -p "Enter Your Email: " email

# Create the config file first
touch "$alternate_config_path"

git config --file "$alternate_config_path" user.email "$email"
echo "Git Configuration file for OSS contributions created"
git config --file "$alternate_config_path" --list

# Add trailing slash to directory path for gitconfig
git config --global "includeIf.gitdir:${oss_directory}/".path "$alternate_config_path"
git config --global --get "includeIf.gitdir:${oss_directory}/".path
# push current directory to the stack
pushd "$PWD"
# test that the config is working
cd "$oss_directory"
# make a random directory and init it as git repo. use a random name
random_dir=$(openssl rand -hex 4)
mkdir "$random_dir"
cd "$random_dir"
git init
# do a commit and check that the email is correct using git log --pretty=format:"%ae"

git commit --allow-empty -m "Test Commit"
email=$(git log --pretty=format:"%ae" -1)
if [ "$email" == "$oss_email" ]; then
   echo "Git OSS User Email configured correctly"
else
   echo "Git OSS User Email not configured correctly"
fi
# clean up
popd
rm -rf "$random_dir"
