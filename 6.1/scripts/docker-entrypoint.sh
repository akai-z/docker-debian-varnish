#!/bin/sh

set -e

default_run() {
  local vcl_file="/etc/varnish/default.vcl"

  vcl_file_set $vcl_file

  varnishd -a $LISTEN_ADDRESS:$LISTEN_PORT \
    -T $MANAGEMENT_INTERFACE_ADDRESS:$MANAGEMENT_INTERFACE_PORT \
    -Ff $vcl_file \
    -p feature=+esi_disable_xml_check,+esi_ignore_other_elements \
    -p vsl_reclen=$VSL_RECLEN \
    -p vcc_allow_inline_c=on \
    -p 'cc_command=exec cc -fpic -shared -Wl,-x -o %o %s -lcrypto -lssl' \
    -s malloc,$MALLOC
}

clean_run() {
  set -- varnishd "$@"
  exec "$@"

  exit 0
}

vcl_file_set() {
  local vcl_file="$1"

  envsubst \
    < "${vcl_file}.template" \
    > $vcl_file
}

main() {
  if [ "${1#-}" != "$1" ]; then
    clean_run "$@"
  fi

  default_run
}

main "$@"
