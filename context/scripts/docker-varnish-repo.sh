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

repo_add() {
  local version="60"
  local gpgkey_fingerprint="4E8B9DBA"
  local repo_base_url="https://packagecloud.io/varnishcache/varnish${version}"
  local repo_url="${repo_base_url}/debian/"
  local gpgkey_url="${repo_base_url}/gpgkey"
  local gpgkey_pub_label="pub:-:"

  fetch_deps_install
  gnupg_dir_create
  gpgkey_file_fetch $gpgkey_url
  gpgkey_verification $gpgkey_fingerprint $gpgkey_pub_label
  trusted_keys_list_gpgkey_add
  sources_list_repo_url_add $repo_url
  gpgkey_file_remove
}

fetch_deps_clean() {
  apt-get purge -y --auto-remove $FETCH_DEPS
  rm -rf $GNUPG_DIR $SOURCE_LIST_FILE
}

fetch_deps_install() {
  apt-get update
  apt-get install --no-install-recommends --no-install-suggests -y \
    $FETCH_DEPS
}

gnupg_dir_create() {
  if [ ! -d $GNUPG_DIR ]; then
    mkdir $GNUPG_DIR
    chmod 700 $GNUPG_DIR
  fi
}

gpgkey_file_fetch() {
  local gpgkey_url="$1"
  curl -fsSL -o $GPGKEY_FILE $gpgkey_url
}

gpgkey() {
  echo "$( \
    gpg -q \
      --dry-run \
      --with-colons \
      --import-options import-show \
      --import $GPGKEY_FILE \
  )"
}

gpgkey_verification() {
  local gpgkey_fingerprint="$1"
  local gpgkey_pub_label="$2"
  local gpgkey="$(gpgkey)"
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

trusted_keys_list_gpgkey_add() {
  apt-key add $GPGKEY_FILE
}

sources_list_repo_url_add() {
  local repo_url="$1"

  echo "deb $repo_url $(lsb_release -cs) main" \
    > $SOURCE_LIST_FILE
}

gpgkey_file_remove() {
  rm -rf $GPGKEY_FILE
}

main() {
  case "$1" in
    add)     repo_add;;
    clean)   fetch_deps_clean;;
    *)       repo_add;;
  esac
}

main "$@"
