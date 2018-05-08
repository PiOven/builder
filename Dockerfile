FROM node:8-alpine

WORKDIR /opt/builder
ADD ./src ./src
ADD package*.json ./

VOLUME /opt/builder/cache

ENV CACHE_DIR=/opt/builder/cache

RUN apk add --no-cache multipath-tools openssh-client \
  && npm install

USER node
