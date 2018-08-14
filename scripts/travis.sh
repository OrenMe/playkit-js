#!/bin/sh
# https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
set -ev

#setup_npm() {
#  # write the token to config
#  # see https://docs.npmjs.com/private-modules/ci-server-config
#  echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> .npmrc
#}
#
#setup_git() {
#  git config --global user.email "travis@travis-ci.org"
#  git config --global user.name "Travis CI"
#  git remote rm origin
#
#  # Add new "origin" with access token in the git URL for authentication
#  git remote add origin https://${GH_TOKEN}@github.com/OrenMe/playkit-js.git
#}

yarn install

if [ "${TRAVIS_MODE}" = "lint" ]; then
  yarn run eslint
elif [ "${TRAVIS_MODE}" = "flow" ]; then
  yarn run flow
elif [ "${TRAVIS_MODE}" = "unitTests" ]; then
	yarn run test
elif [ "${TRAVIS_MODE}" = "release" ] || [ "${TRAVIS_MODE}" = "releaseCanary" ]; then
  # update the version
  # make sure everything is fetched https://github.com/travis-ci/travis-ci/issues/3412
  echo "Update git source"
  git fetch --unshallow 1>&2
  echo "Switch to master"
  git checkout master
  if [ "${TRAVIS_MODE}" = "release" ]; then
    echo "Run standard-version"
    yarn run release
    echo "Building..."
    yarn run build
    echo "Finish building"
  elif [ "${TRAVIS_MODE}" = "releaseCanary" ]; then
    echo "Run standard-version"
    yarn run release --prerelease canary --skip.commit=true --skip.tag=true
    sha=$(git rev-parse --verify --short HEAD)
    echo "Current sha ${sha}"
    currentVersion=$(npx -c 'echo "$npm_package_version"')
    echo "Current version ${currentVersion}"
    newVersion=$(echo $currentVersion | sed -e "s/canary\.[[:digit:]]/canary.${sha}/g")
    echo "New version ${newVersion}"
    sed -i "" "s/$currentVersion/$newVersion/g" package.json
    sed -i "" "s/$currentVersion/$newVersion/g" CHANGELOG.md
    echo "Building..."
    yarn run build
    echo "Finish building"
  fi
else
	echo "Unknown travis mode: ${TRAVIS_MODE}" 1>&2
	exit 1
fi
