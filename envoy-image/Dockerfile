FROM envoyproxy/envoy:v1.24.0

RUN apt-get update && apt-get install -y gettext-base

COPY envoy.yaml /etc/envoy/envoy-tmpl.yaml
COPY entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["envoy", "-c", "/etc/envoy/envoy.yaml"]