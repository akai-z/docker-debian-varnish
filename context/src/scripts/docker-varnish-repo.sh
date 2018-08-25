#!/bin/sh

set -e

readonly VERSION="60"
readonly GPGKEY_FINGERPRINT="4E8B9DBA"
readonly REPO_BASE_URL="https://packagecloud.io/varnishcache/varnish${VERSION}"
readonly REPO_URL="${REPO_BASE_URL}/debian/"
readonly GPGKEY_URL="${REPO_BASE_URL}/gpgkey"
readonly GPGKEY_FILE="docker_varnish_gpgkey"
readonly GPGKEY_PUB_LABEL="pub:-:"
readonly GNUPG_DIR="/root/.gnupg"

function add()
{
  if [ ! -d $GNUPG_DIR ]; then
    mkdir $GNUPG_DIR
    chmod 700 $GNUPG_DIR
  fi

  curl -fsSL -o $GPGKEY_FILE $GPGKEY_URL

  gpgkey="$( \
    gpg -q \
      --dry-run \
      --with-colons \
      --import-options import-show \
      --import $GPGKEY_FILE \
  )"

  echo "$gpgkey" \
    | grep -q $GPGKEY_FINGERPRINT \
    || exit 1 # Wrong/Malicious key.

  gpgkeys_count=$( \
    echo "$gpgkey" \
    | grep -c "^${GPGKEY_PUB_LABEL}" \
  )

  if [ $gpgkeys_count -gt 1 ]; then
    exit 1 # Malicious key.
  fi

  apt-key add $GPGKEY_FILE

  echo "deb $REPO_URL $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/docker_varnish.list

  rm -rf $GPGKEY_FILE $GNUPG_DIR
}

add
