#!/bin/bash
set -eu

declare currentDir=$(cd $(dirname $0);pwd)
declare parentDir=$(cd $(dirname $(cd $(dirname $0);pwd));pwd)
declare repositoryUrl="git@github.com:almin/almin.github.io.git"
declare toBranch="master"
declare commitMessage="Deploy docusaurus build [skip ci]"
declare websiteDir="${parentDir}/website/"
declare distDir="${parentDir}/website/build/almin"

if [ "$TRAVIS_PULL_REQUEST" != "false" ]
then
  echo "This is Pull Request. Not deploy"
  exit 0;
fi
# commit and push
# commit_and_push_changes "message" "branch"
commit_and_push_changes() {
    # Commit and push changes upstream, and
    # overwrite the content from the specified branch

    git config --global user.email "$GH_USER_EMAIL" \
        && git config --global user.name "$GH_USER_NAME" \
        && git init \
        && git add -A \
        && git commit --message "$2" \
        && (

            # If the distribution branch is `master`,
            # there is no need to switch as that is the default

            if [ "$1" != "master" ]; then
                git checkout --quiet -b "$1"
            fi

        ) \
        && git push --quiet --force "${repositoryUrl}" "$1"

}

execute() {
    eval ${1}
}
# remove_files_in_dir "dir"
remove_files_in_dir() {
    find "$1" -type f -delete
}
tmpDir=$(mktemp -d 2>/dev/null||mktemp -d -t tmp)
echo "Clone content"
git clone ${repositoryUrl} "${tmpDir}/almin.github.io"
# delete all files
echo "Remove files"
remove_files_in_dir "${tmpDir}/almin.github.io"
# execute command
echo "Install"
cd "${websiteDir}"
yarn install
echo "Update content"
yarn run build
echo "Copy files"
cp -Rf "${distDir}/"* "${tmpDir}/almin.github.io/"
echo "Copy CNAME"
cp "${parentDir}/CNAME" "${tmpDir}/almin.github.io/"
echo "Commit and push"
cd "${tmpDir}/almin.github.io/"
commit_and_push_changes  "${toBranch}" "${commitMessage}"
