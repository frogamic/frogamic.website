#! /usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

cd "$(dirname "${BASH_SOURCE[0]}")"

aws cloudformation deploy \
  --stack-name frogamic-dns \
  --template-file ./hostedzones.yml \
  --region ap-southeast-2

./email/update.sh frogamic.com
./email/update.sh frogamic.website

./static-site/deploy.sh with-cert with-state
