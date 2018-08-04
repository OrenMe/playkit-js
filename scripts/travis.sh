#!/bin/sh
# https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
set -ev

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
  git fetch --unshallow
  echo "Switch to master"
  git checkout master
#  node ./scripts/set-package-version.js
#  yarn run lint
#  yarn run flow
#  yarn run test

#  setup_npm
  echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> .npmrc
  setup_git

  if [ "${TRAVIS_MODE}" = "release" ]; then
    yarn run release
    yarn run build
    yarn run publish
    yarn publish
    echo "Published."
  elif [ "${TRAVIS_MODE}" = "releaseCanary" ]; then
    canaryVersion=$(git describe --long --tags --always | sed -e 's/\(.*-\)\([[:digit:]]*-.*\)/\canary-\2/g')
    yarn run release --prerelease ${canaryVersion} --skip.commit=true --skip.changelog=true --skip.tag=true
    yarn run build
#    reset the changelog file
    git checkout -- CHANGELOG.md
    yarn publish --tag canary
    echo "Published canary."
    curl https://purge.jsdelivr.net/npm/playkit-js-test@canary
    echo "Cleared jsdelivr cache."
  fi

#  yarn run build
#  if [[ $(node ./scripts/check-already-published.js) = "not published" ]]; then
    # write the token to config
    # see https://docs.npmjs.com/private-modules/ci-server-config
#    echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> .npmrc
#    if [ "${TRAVIS_MODE}" = "releaseCanary" ]; then
#      npm publish --tag canary
#      echo "Published canary."
#      curl https://purge.jsdelivr.net/npm/hls.js@canary
#      echo "Cleared jsdelivr cache."
#    elif [ "${TRAVIS_MODE}" = "release" ]; then
#      npm publish
#      echo "Published."
#    fi
#  else
#    echo "Already published."
#  fi
else
	echo "Unknown travis mode: ${TRAVIS_MODE}" 1>&2
	exit 1
fi

#setup_npm() {
  # write the token to config
  # see https://docs.npmjs.com/private-modules/ci-server-config
#  echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> .npmrc
#}

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  git remote rm origin

  # Add new "origin" with access token in the git URL for authentication
  git remote add origin https://${GH_TOKEN}@github.com/OrenMe/playkit-js.git
}
