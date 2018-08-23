#!/bin/sh

set -eu

readonly VERSION="60"
readonly GPGKEY_FINGERPRINT="4E8B9DBA"
readonly PACKAGE_URL="https://packagecloud.io/varnishcache/varnish${VERSION}"
readonly GPGKEY_URL="${PACKAGE_URL}/gpgkey"
readonly DEB_URL="${PACKAGE_URL}/debian/"
readonly GPGKEY_FILE="docker_varnish_gpgkey"
readonly GPGKEY_PUB_LABEL="pub:-:"
readonly GNUPG_DIR="/root/.gnupg"

alias showgpgkey="gpg -q --dry-run --with-colons --import-options import-show --import $GPGKEY_FILE"

mkdir $GNUPG_DIR
chmod 700 $GNUPG_DIR

curl -fsSL -o $GPGKEY_FILE $GPGKEY_URL

showgpgkey | grep -q $GPGKEY_FINGERPRINT \
  || exit 1 # Wrong/Malicious key.

gpgkeysCount=$(showgpgkey | grep -c "^${GPGKEY_PUB_LABEL}")
if [ $gpgkeysCount -gt 1 ]; then
  exit 1 # Malicious key.
fi

apt-key add $GPGKEY_FILE

echo "deb $DEB_URL $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/docker_varnish.list

rm -rf $GPGKEY_FILE $GNUPG_DIR
