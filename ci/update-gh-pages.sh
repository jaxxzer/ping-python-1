#!/usr/bin/env bash

# Deploy repository documentation

# Variables
bold=$(tput bold)
normal=$(tput sgr0)
doc_path="doc"
project_path=${doc_path}/..
clone_folder=/tmp/update-repos

repository_name="ping-python"
repository_githash=$(git -C ${project_path} rev-parse HEAD)

# Functions
. ci/functions.sh

echob "Check git configuration."
if [ "${TRAVIS}" = "true" ] || ! git config --list | grep -q "user.name"; then
    # Config for auto-building
    echo "- Git configuration does not exist, a new one will be configured."
    git config --global user.email "support@bluerobotics.com"
    git config --global user.name "BlueRobotics-CI"
else
    echo "- Git configuration already exist."
fi

echob "Build doxygen documentation."
echob $doc_path
if ! ( cd $doc_path && doxygen "Doxyfile" ); then
    echo "- Doxygen generation failed."
    exit 1
fi
echo "- Check files"
ls -A "${doc_path}/html/"

repo_path=${clone_folder}/${repository_name}
echo "- Clone ${repository_name}"
rm -rf ${repo_path}
git clone https://${GITHUB_TOKEN}@github.com/bluerobotics/${repository_name} ${repo_path}
echo "- Checkout gh-pages"
git -C ${clone_folder}/${repository_name} checkout gh-pages

echob "Update gh-pages"
mv ${doc_path}/html/* ${repo_path}

echo "- Check ${repository_name}"
if [[ $(git -C ${repo_path} diff) ]]; then
    echo "- Something is different, a commit will be done."
    git -C ${repo_path} add --all
    COMMIT_MESSAGE="Update autogenerated files
From https://github.com/bluerobotics/ping-protocol/tree/"$repository_githash
    git -C ${repo_path} commit -sm "${COMMIT_MESSAGE}"

    echob "Check build type."
    # Do not build pull requests
    if [ ${TRAVIS_PULL_REQUEST} != "false" ]; then
        echo "- Do not deploy PRs."
        exit 0
    fi

    echob "Check branch."
    # Do only build master branch
    if [ ${TRAVIS_BRANCH} != "master" ]; then
        echo "- Only master branch will be deployed."
        exit 0
    fi

    git -C ${repo_path} push origin gh-pages
else
    echo "- Ok."
fi
