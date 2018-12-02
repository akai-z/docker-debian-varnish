#!/bin/sh

set -e

readonly VERSION="60lts"
readonly GPGKEY_FINGERPRINT="48D81A24CB0456F5D59431D94CFCFD6BA750EDCD"
readonly GPG_SUBKEY_FINGERPRINT="DD2C378724BD39C18AAA47FE3AEAFFBB82FBBA5F"
readonly REPO_BASE_URL="https://packagecloud.io/varnishcache/varnish${VERSION}"
readonly REPO_URL="${REPO_BASE_URL}/debian/"
readonly GPGKEY_URL="${REPO_BASE_URL}/gpgkey"
readonly GPGKEY_FINGERPRINT_LENGTH=40
readonly PACKAGE_ARCHIVE_TYPE="deb"
readonly PACKAGE_ARCH=""
readonly PACKAGE_SOURCE_COMPONENTS="main"
readonly GPGKEY_PUB_LABEL="pub:-:"
readonly GPGKEY_FILE="docker-varnish-gpgkey"
readonly GPG_DIR="/root/.gnupg"
readonly SOURCES_LIST_DIR="/etc/apt/sources.list.d"
readonly PACKAGE_SOURCE_FILE="${SOURCES_LIST_DIR}/docker-varnish.list"
readonly PACKAGE_SOURCE_FORMAT="%s%s %s %s %s"
readonly FETCH_DEPS="
  apt-transport-https
  ca-certificates
  curl
  gnupg2
  software-properties-common
"

repo_add() {
  fetch_deps_install
  gpg_dir_create
  gpgkey_file_fetch
  gpgkey_verification
  trusted_keys_list_gpgkey_add
  package_source_add
  gpgkey_file_remove
}

fetch_deps_clean() {
  apt-get purge -y --auto-remove $FETCH_DEPS
  rm -rf "$GPG_DIR" "$PACKAGE_SOURCE_FILE"
}

fetch_deps_install() {
  apt-get update
  apt-get install --no-install-recommends --no-install-suggests -y \
    $FETCH_DEPS
}

gpg_dir_create() {
  if [ ! -d "$GPG_DIR" ]; then
    mkdir "$GPG_DIR"
    chmod 700 "$GPG_DIR"
  fi
}

gpgkey_file_fetch() {
  curl -fsSL -o "$GPGKEY_FILE" "$GPGKEY_URL"
}

gpgkey_verification() {
  local gpgkey="$(gpgkey)"
  local gpgkeys_count="$(gpgkeys_count "$gpgkey")"

  if [ "$gpgkeys_count" -ne 1 ]; then
    exit 1 # Malicious key.
  fi

  if [ "${#GPGKEY_FINGERPRINT}" -ne "$GPGKEY_FINGERPRINT_LENGTH" ] || \
    [ "${#GPG_SUBKEY_FINGERPRINT}" -ne "$GPGKEY_FINGERPRINT_LENGTH" ]
  then
    exit 1 # Invalid key fingerprint.
  fi

  gpgkey_fingerprint_find "$gpgkey" "$GPGKEY_FINGERPRINT" \
    || exit 1 # Wrong/Malicious key.

  gpgkey_fingerprint_find "$gpgkey" "$GPG_SUBKEY_FINGERPRINT" \
    || exit 1 # Wrong/Malicious key.
}

gpgkey() {
  echo "$( \
    gpg -q \
      --dry-run \
      --with-colons \
      --with-subkey-fingerprint \
      --import-options import-show \
      --import "$GPGKEY_FILE" \
  )"
}

gpgkeys_count() {
  local gpgkey="$1"

  echo "$gpgkey" | grep -c "^${GPGKEY_PUB_LABEL}"
}

gpgkey_fingerprint_find() {
  local gpgkey="$1"
  local fingerprint="$2"

  echo "$gpgkey" | grep -q "$fingerprint"
}

trusted_keys_list_gpgkey_add() {
  apt-key add "$GPGKEY_FILE"
}

package_source_add() {
  echo "$(package_source)" > $PACKAGE_SOURCE_FILE
}

package_source() {
  echo "$( \
    printf "$PACKAGE_SOURCE_FORMAT" \
      "$PACKAGE_ARCHIVE_TYPE" \
      "$(package_arch)" \
      "$REPO_URL" \
      "$(distribution_name)" \
      "$PACKAGE_SOURCE_COMPONENTS" \
  )"
}

package_arch() {
  local arch=""

  if [ "$PACKAGE_ARCH" ]; then
    arch=" [arch=${PACKAGE_ARCH}]"
  fi

  echo "$arch"
}

distribution_name() {
  echo "$(lsb_release -cs)"
}

gpgkey_file_remove() {
  rm -rf "$GPGKEY_FILE"
}

main() {
  case "$1" in
    add)     repo_add;;
    clean)   fetch_deps_clean;;
    *)       repo_add;;
  esac
}

main "$@"
