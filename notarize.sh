#!/bin/bash -Eeu -o pipefail

PATH_TO_NOTARIZE="$*"
API_KEY_PATH=$(mktemp -t 'asc')
ZIP_PATH=$(basename $PATH_TO_NOTARIZE).zip

trap "rm -f $ZIP_PATH; rm -f $API_KEY_PATH" EXIT

zip -r $ZIP_PATH $PATH_TO_NOTARIZE

echo "$API_KEY" > $API_KEY_PATH
AUTH_OPTIONS="--key $API_KEY_PATH --key-id $API_KEY_ID --issuer $API_KEY_ISSUER"
xcrun notarytool \
      submit $ZIP_PATH \
      --wait \
      $AUTH_OPTIONS
