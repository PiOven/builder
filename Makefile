DOCKER_CONTAINER ?= pioven/builder
RUN_USER ?= 0
CACHE_DIR ?= /cache
SRC_DIR ?= /src

all: setup build

build:
	make docker-run CMD="node ./src/build/img"

	@echo "Now write .${CACHE_DIR}/os.img to an SD card and put into a Pi. This will take up to 5 minutes to boot and configure"
.PHONY: build

docker-build:
	docker build -t ${DOCKER_CONTAINER} .
.PHONY: docker-build

docker-run:
	docker run \
		-it \
		--privileged \
		--rm \
		-v /dev:/dev \
		-v "${PWD}${CACHE_DIR}:/opt/builder${CACHE_DIR}" \
		-v "${PWD}${SRC_DIR}:/opt/builder${SRC_DIR}" \
		-u ${RUN_USER} \
		${DOCKER_CONTAINER} \
		${CMD}
.PHONY: docker-run

publish:
	$(eval VERSION := $(shell make version))

	@echo "Tagging Docker images as v${VERSION}"
	docker tag ${DOCKER_CONTAINER}:latest ${DOCKER_CONTAINER}:${VERSION}

	@echo "Pushing images to Docker"
	docker push ${DOCKER_CONTAINER}:${VERSION}
	docker push ${DOCKER_CONTAINER}:latest
.PHONY: publish

setup:
	make docker-run CMD="node ./src/setup" RUN_USER=1000

	@echo "Now run 'make build' to configure the image"
.PHONY: setup

test:
	make docker-run CMD="npm test" RUN_USER=1000
.PHONY: test

version:
	@echo $(TRAVIS_TAG:v%=%)
.PHONY: version
