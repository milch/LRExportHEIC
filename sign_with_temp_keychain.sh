#!/bin/bash -Eeu -o pipefail

TEMP_KEYCHAIN_PASSWORD=$(date '+%s')
TEMP_KEYCHAIN=$(date '+%s').keychain
EXTRA_CODESIGN_ARGS="$*"
CURRENT_DEFAULT_KEYCHAIN=$(security default-keychain)
CURRENT_KEYCHAINS=$(security list-keychains | xargs basename)
CERT_FILE=certificate.p12

trap "rm -f $CERT_FILE; security delete-keychain $TEMP_KEYCHAIN; security list-keychains -s $CURRENT_KEYCHAINS; security default-keychain -s $CURRENT_DEFAULT_KEYCHAIN" EXIT
echo $SIGNING_CERT | base64 --decode > $CERT_FILE

security create-keychain -p $TEMP_KEYCHAIN_PASSWORD $TEMP_KEYCHAIN
security default-keychain -s $TEMP_KEYCHAIN
security list-keychains -s $CURRENT_KEYCHAINS $TEMP_KEYCHAIN

security unlock-keychain -p $TEMP_KEYCHAIN_PASSWORD $TEMP_KEYCHAIN
security import $CERT_FILE -k $TEMP_KEYCHAIN -P $SIGNING_CERT_PASSWORD -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k $TEMP_KEYCHAIN_PASSWORD $TEMP_KEYCHAIN

/usr/bin/codesign --verbose --force --sign '004650c51e4d110cd543b9511ec5f2ce153f423d' --timestamp --options runtime "$EXTRA_CODESIGN_ARGS"
