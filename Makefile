all: setup build

build:
	sh ./scripts/pibuilder.sh
.PHONY: build

setup:
	node ./scripts/setup.js
.PHONY: setup
