#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

cd "$(dirname "$0")"

DOMAIN=$1

aws cloudformation deploy \
	--stack-name "${DOMAIN/./-}-protonmail" \
	--template protonmail.yml \
	--parameter-overrides "file://$(pwd)/${DOMAIN}.json" \
	--region ap-southeast-2
