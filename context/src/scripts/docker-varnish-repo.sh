#!/bin/sh

set -e

readonly GPGKEY_FILE="docker_varnish_gpgkey"
readonly GNUPG_DIR="/root/.gnupg"
readonly SOURCE_LIST_FILE="/etc/apt/sources.list.d/docker_varnish.list"
readonly FETCH_DEPS="
  apt-transport-https
  ca-certificates
  curl
  gnupg2
  software-properties-common
"

add()
{
  local version="60"
  local gpgkey_fingerprint="4E8B9DBA"
  local repo_base_url="https://packagecloud.io/varnishcache/varnish${version}"
  local repo_url="${repo_base_url}/debian/"
  local gpgkey_url="${repo_base_url}/gpgkey"
  local gpgkey_pub_label="pub:-:"

  apt-get update
  apt-get install --no-install-recommends --no-install-suggests -y \
    $FETCH_DEPS

  if [ ! -d $GNUPG_DIR ]; then
    mkdir $GNUPG_DIR
    chmod 700 $GNUPG_DIR
  fi

  curl -fsSL -o $GPGKEY_FILE $gpgkey_url

  gpgkey="$( \
    gpg -q \
      --dry-run \
      --with-colons \
      --import-options import-show \
      --import $GPGKEY_FILE \
  )"

  echo "$gpgkey" \
    | grep -q $gpgkey_fingerprint \
    || exit 1 # Wrong/Malicious key.

  gpgkeys_count=$( \
    echo "$gpgkey" \
    | grep -c "^${gpgkey_pub_label}" \
  )

  if [ $gpgkeys_count -gt 1 ]; then
    exit 1 # Malicious key.
  fi

  apt-key add $GPGKEY_FILE

  echo "deb $repo_url $(lsb_release -cs) main" \
    > $SOURCE_LIST_FILE
}

clean()
{
  apt-get purge -y --auto-remove $FETCH_DEPS
  rm -rf $GPGKEY_FILE $GNUPG_DIR $SOURCE_LIST_FILE
}

main()
{
  case "$1" in
    add)     add;;
    clean)   clean;;
    *)       add;;
  esac
}

main "$@"
