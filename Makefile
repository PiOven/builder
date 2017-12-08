all: setup build

build:
	sh ./scripts/pibuilder.sh
.PHONY: build

setup:
	bash ./scripts/setup.sh
.PHONY: setup
