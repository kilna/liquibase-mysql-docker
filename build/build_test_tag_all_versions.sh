#!/bin/bash
set -e -o pipefail

IFS=$'\n' versions=( $(cat build/versions.txt) )
for version in "${versions[@]}"; do
  build/build_test_tag.sh "$version"
done

