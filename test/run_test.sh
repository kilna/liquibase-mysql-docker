#!/bin/bash
set -e -o pipefail

echo "Applying changelog"
liquibase updateTestingRollback

