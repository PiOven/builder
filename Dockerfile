FROM fedora:27

# Setup the user
RUN groupadd --gid 1000 pibuilder \
  && useradd --uid 1000 --gid pibuilder --shell /bin/bash --create-home pibuilder

# Install dependencies
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - \
  && dnf update -y \
  && dnf install -y nodejs \
  && dnf install -y gcc-c++ make \
  && dnf install -y pylint \
  && node --version \
  && npm --version

WORKDIR /opt/pibuilder
ADD . .

ARG SSH_KEY_DIR="/ssh-keys"

VOLUME ${SSH_KEY_DIR}

ENV SSH_KEY_DIR=${SSH_KEY_DIR}

# Install dependencies
RUN dnf install -y git kpartx openssh-clients unzip \
  && npm install
