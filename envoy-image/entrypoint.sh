#!/usr/bin/env sh

set -x

/usr/bin/envsubst < /etc/envoy/envoy-tmpl.yaml > /etc/envoy/envoy.yaml
/bin/cat /etc/envoy/envoy.yaml

exec /docker-entrypoint.sh "${@}"