FROM node:8-alpine

WORKDIR /opt/builder
ADD ./src ./src
ADD package*.json ./

VOLUME /opt/builder/cache

ENV CACHE_DIR=/opt/builder/cache

RUN apk add --no-cache device-mapper multipath-tools openssh-client zip \
  && npm install

USER node
