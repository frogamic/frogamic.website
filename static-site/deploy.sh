#! /usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

DOMAIN_NAME="frogamic.website"
DOMAIN_NAME2="frogamic.com"
PROJECT="frogamic-website"
STAGE="prod"

cd "$(dirname "$0")"

if [ $# -gt 0 ] && [[ " $@ " =~ " with-state " ]]; then
  echo "Deploying state buckets for ${DOMAIN_NAME}"

  aws cloudformation deploy --stack-name "${PROJECT}-state" --template-file ./state.yml \
    --parameter-overrides \
      "Stage=${STAGE}" \
      "Project=${PROJECT}"
fi

if [ $# -gt 0 ] && [[ " $@ " =~ " with-cert " ]]; then
  echo "Deploying HTTPS certificate in us-east-1 for ${DOMAIN_NAME}"

  HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN_NAME" --query 'HostedZones[0].Id' --output text)"
  HOSTED_ZONE_ID2="$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN_NAME2" --query 'HostedZones[0].Id' --output text)"

  aws cloudformation deploy --stack-name "${PROJECT}-cert" --template-file ./cert.yml \
    --parameter-overrides \
      "Stage=${STAGE}" \
      "Project=${PROJECT}" \
      "DomainName=${DOMAIN_NAME}" \
      "HostedZoneId=${HOSTED_ZONE_ID}" \
      "DomainName2=${DOMAIN_NAME2}" \
      "HostedZoneId2=${HOSTED_ZONE_ID2}" \
    --region us-east-1

  CERT_ARN="$(aws cloudformation describe-stacks --region us-east-1 --query 'Stacks[0].Outputs[?OutputKey==`CertArn`].OutputValue' --output text --stack-name "${PROJECT}-cert")"

  aws ssm put-parameter --overwrite --type "String" --name "/infra/${STAGE}/${PROJECT}/Cert" --value "${CERT_ARN}"
fi

echo "Deploying CloudFront stack for ${DOMAIN_NAME}"
aws cloudformation deploy --stack-name "$PROJECT" --template-file ./distribution.yml \
  --parameter-overrides \
    "Stage=${STAGE}" \
    "Project=${PROJECT}" \
    "DomainName=${DOMAIN_NAME}" \
    "DomainName2=${DOMAIN_NAME2}" \
    "CertArn=/infra/${STAGE}/${PROJECT}/Cert" \
    "ContentBucket=/infra/${STAGE}/${PROJECT}/ContentBucket" \
    "LogsBucket=/infra/${STAGE}/${PROJECT}/LogsBucket"
