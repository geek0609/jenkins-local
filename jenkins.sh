#!/bin/bash
if [ ! -d "jenkins-local" ]; then
    git clone https://github.com/geek0609/jenkins-local
fi
cd jenkins-local
export PATH="${PATH}:$(pwd)/bin"
export branch="master"
git checkout -- .
git fetch --all
git checkout origin/"${branch}"
git branch -D "${branch}"
git checkout -b "${branch}"
source config.sh
export GITHUB_TOKEN=""
export TELEGRAM_TOKEN=""
export TELEGRAM_CHAT=""
export BUILD_NUMBER=""
source init.sh
