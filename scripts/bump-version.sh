#!/bin/sh

BUMPED_VERSION="$1"

sed -i '' -e 's/s.version          \= [^\;]*/s.version          = '"'$BUMPED_VERSION'"'/' FCL-SDK.podspec

# docs
sed -i '' -e 's/pod '\''FCL-SDK'\'', '\''~> [^\;]*'\''/pod '\''FCL-SDK'\'', '\''~> '$BUMPED_VERSION''\''/' README.md
sed -i '' -e 's/.package(url: "https:\/\/github.com\/portto\/fcl-swift.git", .upToNextMinor(from: [^\;]*))/.package(url: "https:\/\/github.com\/portto\/fcl-swift.git", .upToNextMinor(from: "'$BUMPED_VERSION'"))/' README.md
