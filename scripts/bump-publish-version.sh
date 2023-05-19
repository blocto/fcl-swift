#!/bin/sh

if pod spec lint FCL-SDK.podspec
then 
    echo "lint suceess"
else
    echo "failed"
    exit 0
fi

BUMPED_VERSION="$1"

sed -i '' -e 's/s.version          \= [^\;]*/s.version          = '"'$BUMPED_VERSION'"'/' FCL-SDK.podspec

# docs
sed -i '' -e 's/pod '\''FCL-SDK'\'', '\''~> [^\;]*'\''/pod '\''FCL-SDK'\'', '\''~> '$BUMPED_VERSION''\''/' README.md
sed -i '' -e 's/.package(url: "https:\/\/github.com\/portto\/fcl-swift.git", .upToNextMinor(from: [^\;]*))/.package(url: "https:\/\/github.com\/portto\/fcl-swift.git", .upToNextMinor(from: "'$BUMPED_VERSION'"))/' README.md

# commit all changes
git add --all
git commit -m "Bump version"
git push origin main

# add tag and push to remote
git tag $BUMPED_VERSION
git push origin $BUMPED_VERSION

# publish cocoapods
pod trunk push FCL-SDK.podspec --allow-warnings