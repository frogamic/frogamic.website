#! /usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

DOMAIN_NAME="frogamic.website"
STACK="frogamic-website"

if [ $# -gt 0 ] && [ "$1" = "with-cert" ]; then
  echo "Deploying HTTPS certificate in us-east-1 for ${DOMAIN_NAME}"

  HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN_NAME" --query 'HostedZones[0].Id' --output text)"

  aws cloudformation deploy --stack-name "${STACK}-cert" --template-file static-site-cert.yml \
    --parameter-overrides "Domain=${DOMAIN_NAME}" "HostedZoneId=${HOSTED_ZONE_ID}" \
    --region us-east-1
fi

CERT_ARN="$(aws cloudformation describe-stacks --region us-east-1 --query 'Stacks[0].Outputs[?OutputKey==`CertArn`].OutputValue' --output text --stack-name "${STACK}-cert")"

echo "Deploying CloudFront stack for ${DOMAIN_NAME}"
aws cloudformation deploy --stack-name "$STACK" --template-file static-site.yml \
  --parameter-overrides "DomainName=${DOMAIN_NAME}" "CertArn=${CERT_ARN}"
