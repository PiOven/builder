DOCKER_CONTAINER ?= riggerthegeek/pibuilder
RUN_USER ?= 0

all: setup build

build:
	make docker-run CMD="sh ./scripts/pibuilder.sh"
.PHONY: build

docker-build:
	docker build -t ${DOCKER_CONTAINER} .
.PHONY: docker-build

docker-run:
	touch settings.sh
	mkdir -p ./cache
	mkdir -p ./ssh-keys
	docker run \
		-it \
		--privileged \
		--rm \
		-v "${PWD}/settings.sh:/opt/pibuilder/settings.sh" \
		-v "${PWD}/cache:/opt/pibuilder/cache" \
		-v "${PWD}/ssh-keys:/ssh-keys" \
		-v "${PWD}/scripts:/opt/pibuilder/scripts" \
		-u ${RUN_USER} \
		${DOCKER_CONTAINER} \
		${CMD}
.PHONY: docker-run

setup:
	make docker-run CMD="node ./scripts/setup.js" RUN_USER=1000
.PHONY: setup
