#!/bin/bash
set -e -o pipefail
docker-compose -f docker-compose.test.yml down --rmi all &>/dev/null &>/dev/null || true
docker-compose -f docker-compose.test.yml up --exit-code-from sut --build --force-recreate --remove-orphans
docker-compose -f docker-compose.test.yml down --rmi all

