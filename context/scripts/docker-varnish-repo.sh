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

add() {
  local version="60"
  local gpgkey_fingerprint="4E8B9DBA"
  local repo_base_url="https://packagecloud.io/varnishcache/varnish${version}"
  local repo_url="${repo_base_url}/debian/"
  local gpgkey_url="${repo_base_url}/gpgkey"
  local gpgkey_pub_label="pub:-:"

  install_fetch_deps
  create_gnupg_dir
  fetch_gpgkey_file $gpgkey_url
  verify_gpgkey $gpgkey_fingerprint $gpgkey_pub_label
  add_gpgkey_to_trusted_keys_list

  echo "deb $repo_url $(lsb_release -cs) main" \
    > $SOURCE_LIST_FILE
}

clean() {
  apt-get purge -y --auto-remove $FETCH_DEPS
  rm -rf $GPGKEY_FILE $GNUPG_DIR $SOURCE_LIST_FILE
}

install_fetch_deps() {
  apt-get update
  apt-get install --no-install-recommends --no-install-suggests -y \
    $FETCH_DEPS
}

create_gnupg_dir() {
  if [ ! -d $GNUPG_DIR ]; then
    mkdir $GNUPG_DIR
    chmod 700 $GNUPG_DIR
  fi
}

fetch_gpgkey_file() {
  local gpgkey_url="$1"
  curl -fsSL -o $GPGKEY_FILE $gpgkey_url
}

get_gpgkey() {
  echo "$( \
    gpg -q \
      --dry-run \
      --with-colons \
      --import-options import-show \
      --import $GPGKEY_FILE \
  )"
}

verify_gpgkey() {
  local gpgkey_fingerprint="$1"
  local gpgkey_pub_label="$2"
  local gpgkey="$(get_gpgkey)"
  local gpgkeys_count

  echo "$gpgkey" \
    | grep -q $gpgkey_fingerprint \
    || exit 1 # Wrong/Malicious key.

  gpgkeys_count=$( \
    echo "$gpgkey" \
    | grep -c "^${gpgkey_pub_label}" \
  )

  if [ $gpgkeys_count -ne 1 ]; then
    exit 1 # Malicious key.
  fi
}

add_gpgkey_to_trusted_keys_list() {
  apt-key add $GPGKEY_FILE
}

main() {
  case "$1" in
    add)     add;;
    clean)   clean;;
    *)       add;;
  esac
}

main "$@"
