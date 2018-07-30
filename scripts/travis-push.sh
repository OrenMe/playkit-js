#!/bin/sh
# Credit: https://gist.github.com/willprice/e07efd73fb7f13f917ea

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_changelog() {
  git checkout master
  # Current month and year, e.g: Apr 2018
  dateAndMonth=`date "+%b %Y"`
  # Stage the modified files in dist/output
#  git add -f dist/output/*.json
  # Create a new commit with a custom build message
  # with "[skip ci]" to avoid a build loop
  # and Travis build number for reference
  git commit -m "Travis update: $dateAndMonth (Build $TRAVIS_BUILD_NUMBER)" -m "[skip ci]"
}

push_master_and_tag() {
  echo "push_master_and_tag"
  # Remove existing "origin"
  git remote rm origin
  # Add new "origin" with access token in the git URL for authentication
  git remote add origin https://${GH_TOKEN}@github.com/OrenMe/playkit-js.git > /dev/null 2>&1
  git push --follow-tags --no-verify origin master
}

setup_git

#commit_country_json_files

# Attempt to commit to git only if "git commit" succeeded
#if [ $? -eq 0 ]; then
  echo "A new changelog was created. Uploading to GitHub"
  push_master_and_tag
#else
#  echo "No changes in country JSON files. Nothing to do"
#fi
