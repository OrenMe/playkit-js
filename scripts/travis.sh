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
  git fetch --unshallow
#  node ./scripts/set-package-version.js
#  yarn run lint
#  yarn run flow
#  yarn run test
  yarn run release
  yarn run build
  echo "1111"
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  echo "2222"
  git remote rm origin
  
  # Add new "origin" with access token in the git URL for authentication
  git remote add origin https://${GH_TOKEN}@github.com/OrenMe/playkit-js.git
  git push --follow-tags --no-verify origin master
  git describe --abbrev=0
  echo $(git describe --tags)
  git push origin $(git describe --tags)
  echo "3333"

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
