DOCKER_CONTAINER ?= riggerthegeek/pibuilder
RUN_USER ?= 0
OUT_DIR ?= /dist

all: setup build

build:
	make docker-run CMD="sh ./scripts/pibuilder.sh"

	@echo "Now write .${OUT_DIR}/cache/os.img to an SD card and put into a Pi. This will take up to 5 minutes to configure"
.PHONY: build

docker-build:
	docker build -t ${DOCKER_CONTAINER} .
.PHONY: docker-build

docker-run:
	mkdir -p .${OUT_DIR}/cache
	mkdir -p .${OUT_DIR}/ssh-keys
	touch .${OUT_DIR}/settings.sh
	docker run \
		-it \
		--privileged \
		--rm \
		-v "${PWD}${OUT_DIR}/settings.sh:/opt/pibuilder/settings.sh" \
		-v "${PWD}${OUT_DIR}/cache:/opt/pibuilder/cache" \
		-v "${PWD}${OUT_DIR}/ssh-keys:/ssh-keys" \
		-v "${PWD}/scripts:/opt/pibuilder/scripts" \
		-u ${RUN_USER} \
		${DOCKER_CONTAINER} \
		${CMD}
.PHONY: docker-run

publish:
	$(eval VERSION := $(shell make version))

	@echo "Tagging Docker images as v${VERSION}"
	docker tag ${DOCKER_CONTAINER}:latest ${DOCKER_CONTAINER}:${VERSION}

	@echo "Pushing images to Docker"
	docker push ${DOCKER_CONTAINER}:latest
	docker push ${DOCKER_CONTAINER}:${VERSION}
.PHONY: publish

setup:
	make docker-run CMD="node ./scripts/setup.js" RUN_USER=1000

	@echo "Now run 'make build' to configure the image"
.PHONY: setup

test:
	make docker-run CMD="npm test" RUN_USER=1000
.PHONY: test

version:
	@echo $(TRAVIS_TAG:v%=%)
.PHONY: version
