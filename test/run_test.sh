#!/bin/bash
#set -e -o pipefail

until nc -z -v -w1 testdb 3306; do
  echo "Waiting for database connection..."
  sleep 3
done

echo "Applying changelog"
liquibase updateTestingRollback

