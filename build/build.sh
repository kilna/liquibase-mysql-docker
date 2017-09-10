#!/bin/bash
set -e -o pipefail

tag=0
while [[ "${1:-NULL}" != 'NULL' ]]; do
  case "$1" in
    -v|--version)  version="$2"; shift; shift ;;
    -t|--tag)      tag=1; shift ;;
    *)             echo "Unknown argument $1" >&2; exit 1 ;;
  esac
done

project="liquibase-mysql"
driver_pretty="MySQL JDBC Driver"
github_user="kilna"

if (( $tag )); then
  dockerhub_user=$(docker info | grep Username | cut -d ' ' -f 2)
  git fetch -p origin
  git pull
  [[ "$dockerhub_user" == '' ]] && echo "Must be logged into dockerhub with docker login" >&2 && exit 180
  [[ "$github_token" == '' ]] && echo "Environment variable github_token must be set" >&2 && exit 181
fi

latest_version=$(tail -1 build/versions.txt)
version="${version:-$latest_version}"


header() { printf '=%.0s' {1..79}; echo; echo $@; printf '=%.0s' {1..79}; echo; }

header "Building $project $version"
echo "jdbc_driver_version=$version" > .env
docker build --tag "$project:build" --no-cache --pull --compress --build-arg jdbc_driver_version="$version" .

header "Testing $project $version"
docker-compose -f docker-compose.test.yml down &>/dev/null || true
docker-compose -f docker-compose.test.yml up --exit-code-from sut --force-recreate --remove-orphans
docker-compose -f docker-compose.test.yml down

(( $tag )) || exit 0

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
docker tag "$project:build" "$dockerhub_user/$project:$version"
docker push "$dockerhub_user/$project:$version"

if [[ "$version" == "$latest_version" ]]; then
  header "Docker Tagging and Pushing $project:latest"
  docker tag "$project:build" "$dockerhub_user/$project:latest"
  docker push "$dockerhub_user/$project:latest"
fi

