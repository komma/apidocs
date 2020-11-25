#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

target=$dir/target/site/apidocs
deploy_branch=gh-pages
token="$1"
remote_url="https://$GITHUB_ACTOR:$token@github.com/$GITHUB_REPOSITORY"

# author, date and message for deployment commit
name=$(git log -n 1 --format='%aN')
email=$(git log -n 1 --format='%aE')
author="$name <$email>"
date=$(git log -n 1 --format='%aD')
message="Built from $(git rev-parse --short HEAD)"

# create temp dir and clone deploy repository
tempdir=$(mktemp -d -p .)
create_deploy_branch=false
# try to clone only deploy branch
if ! git clone --single-branch --branch "$deploy_branch" "$remote_url" "$tempdir"; then
	create_deploy_branch=true
	# clone the default branch (e.g. master)
	git clone --single-branch "$remote_url" "$tempdir"
fi

# change to deploy repository
cd "$tempdir"

currentbranch=$(git symbolic-ref --short -q HEAD)
# check if the current branch is equal to the deploy branch
# it is not equal if deploy branch does not exist yet
if [ "$create_deploy_branch" = true ]; then
	# create new orphan branch if deploy branch does not exist
	git checkout --orphan "$deploy_branch" &>/dev/null
fi
# delete existing files
rm -rf *
# copy generated files
cp -R "$target/." .

status=$(git status --porcelain)
# if there are any changes
if [ "$status" != "" ]
then
	git config user.email "$email"
	git config user.name "$name"
	git add --all && git commit --message="$message" --author="$author" --date="$date"
	git push -q origin $deploy_branch
fi
