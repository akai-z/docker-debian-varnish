#!/bin/sh

set -e

default_run()
{
  envsubst < /etc/varnish/default.vcl.template > /etc/varnish/default.vcl

  varnishd -a $LISTEN_ADDRESS:$LISTEN_PORT \
    -T $MANAGEMENT_INTERFACE_ADDRESS:$MANAGEMENT_INTERFACE_PORT \
    -Ff /etc/varnish/default.vcl \
    -p feature=+esi_disable_xml_check,+esi_ignore_other_elements \
    -p vsl_reclen=$VSL_RECLEN \
    -p vcc_allow_inline_c=on \
    -p 'cc_command=exec cc -fpic -shared -Wl,-x -o %o %s -lcrypto -lssl' \
    -s malloc,$MALLOC
}

clean_run()
{
  set -- varnishd "$@"
  exec "$@"

  exit 0
}

main()
{
  if [ "${1#-}" != "$1" ]; then
    clean_run "$@"
  fi

  default_run
}

main "$@"
