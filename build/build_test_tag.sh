#!/bin/bash
set -e -o pipefail

project="liquibase-mysql"
driver_pretty="MySQL JDBC Driver"
github_user="kilna"

dockerhub_user=$(docker info | grep Username | cut -d ' ' -f 2)
latest_version=$(tail -1 build/versions.txt)
version="${1:-$latest_version}"

git fetch -p origin
git remote prune origin
#git pull
[[ "$dockerhub_user" == '' ]] && echo "Must be logged into dockerhub with docker login" >&2 && exit 180
[[ "$github_token" == '' ]] && echo "Environment variable github_token must be set" >&2 && exit 181

header() { printf '=%.0s' {1..79}; echo; echo $@; printf '=%.0s' {1..79}; echo; }

header "Testing $project $version"
echo "jdbc_driver_version=$version" > .env
docker-compose -f docker-compose.test.yml down --rmi all &>/dev/null || true
docker-compose -f docker-compose.test.yml up --exit-code-from sut --build --force-recreate --remove-orphans
docker-compose -f docker-compose.test.yml down --rmi all

exit 0

header "Building $project $version"
docker build --tag "$project:build-$version" --build-arg jdbc_driver_version="$version" .

header "GitHub Deleting Prior Release $project $version"
curl -X DELETE https://api.github.com/repos/$github_user/${project}-docker/releases/v$version?access_token=$github_token || true

header "Git Deleting Prior Tag $project $version"
if [[ `git tag | grep -F "v$version"` != '' ]]; then
  git tag -d "v$version" || true
fi
git push origin ":v$version" || true

header "Git Tagging $project $version"
if [[ `git status` != *'working tree clean'* ]]; then
  git add .env
  git commit -m "Updating .env with version $version" || true
  git push origin
fi
git tag -m "From $driver_pretty $version" "v$version"
git push origin "v$version"

header "GitHub Releasing $project $version"
curl --data '{"tag_name": "v'"$version"'","target_commitish": "master","name": "From '"$driver_pretty"' v'"$version"'","draft": false,"prerelease": false}' \
  https://api.github.com/repos/$github_user/${project}-docker/releases?access_token=$github_token

header "Docker Tagging and Pushing $project:$version"
docker tag "$project:build-$version" "$dockerhub_user/$project:$version"
docker push "$dockerhub_user/$project:$version"

if [[ "$version" == "$latest_version" ]]; then
  header "Docker Tagging and Pushing $project:latest"
  docker tag "$project:build-$version" "$dockerhub_user/$project:latest"
  docker push "$dockerhub_user/$project:latest"
fi

