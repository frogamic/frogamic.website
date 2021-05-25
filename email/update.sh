#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

cd "$(dirname "$0")"

ACTION="update"
DOMAIN=$1
if [[ $# -eq "2" ]]; then
	ACTION="${2}"
fi

aws cloudformation "${ACTION}-stack"  \
	--stack-name "protonmail-${DOMAIN/./-}"  \
	--template-body "file://$(pwd)/protonmail.yml"  \
	--parameters "file://$(pwd)/${DOMAIN}.json"  \
	--region ap-southeast-2
