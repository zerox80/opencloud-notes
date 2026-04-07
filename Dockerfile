FROM busybox@sha256:1487d0af5f52b4ba31c7e465126ee2123fe3f2305d638e7827681e7cf6c83d5e

LABEL org.opencontainers.image.title="opencloud-notes" \
  org.opencontainers.image.description="Modern file-native notes app for OpenCloud" \
  org.opencontainers.image.vendor="zerox80" \
  org.opencontainers.image.licenses="AGPL-3.0" \
  org.opencontainers.image.source="https://github.com/zerox80/opencloud-notes"

ADD dist /web/apps/notes
RUN mkdir -p /usr/share/nginx/html && ln -s /web/apps /usr/share/nginx/html/apps \
  && find /web/apps

WORKDIR /web/apps
