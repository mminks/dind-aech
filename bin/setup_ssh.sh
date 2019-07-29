#!/usr/bin/env sh

set -e

AWS_KEYFILE=${1?"Missing AWS s3 path to private key"}

# initialize the ssh agent with the key
aws s3 cp s3://${AWS_KEYFILE} - | ssh-add -
