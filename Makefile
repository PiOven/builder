all: setup build

build:
	sh ./scripts/pibuilder.sh

#	Always unmount the images
	kpartx -d ./cache/*.img || true
.PHONY: build

setup:
	node ./scripts/setup
.PHONY: setup
