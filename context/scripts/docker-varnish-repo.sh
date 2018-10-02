#!/bin/sh

set -e

readonly VERSION="60"
readonly GPGKEY_FINGERPRINT="4E8B9DBA"
readonly REPO_BASE_URL="https://packagecloud.io/varnishcache/varnish${VERSION}"
readonly REPO_URL="${REPO_BASE_URL}/debian/"
readonly GPGKEY_URL="${REPO_BASE_URL}/gpgkey"
readonly GPGKEY_PUB_LABEL="pub:-:"
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
  fetch_deps_install
  gnupg_dir_create
  gpgkey_file_fetch
  gpgkey_verification
  trusted_keys_list_gpgkey_add
  sources_list_repo_url_add
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
  curl -fsSL -o $GPGKEY_FILE $GPGKEY_URL
}

gpgkey_verification() {
  local gpgkey="$(gpgkey)"
  local gpgkeys_count

  echo "$gpgkey" \
    | grep -q $GPGKEY_FINGERPRINT \
    || exit 1 # Wrong/Malicious key.

  gpgkeys_count=$( \
    echo "$gpgkey" \
    | grep -c "^${GPGKEY_PUB_LABEL}" \
  )

  if [ $gpgkeys_count -ne 1 ]; then
    exit 1 # Malicious key.
  fi
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

trusted_keys_list_gpgkey_add() {
  apt-key add $GPGKEY_FILE
}

package_source_add() {
  local dist_name="$(distribution_name)"

  echo "deb $REPO_URL $dist_name main" \
    > $SOURCE_LIST_FILE
}

distribution_name() {
  echo "$(lsb_release -cs)"
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
