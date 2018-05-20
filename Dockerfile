FROM node:8-alpine

WORKDIR /opt/builder
ADD . .

VOLUME /opt/builder/cache

ENV CACHE_DIR=/opt/builder/cache

RUN apk add --no-cache device-mapper multipath-tools openssh-client zip \
  && npm install

USER node
