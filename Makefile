ARTIFACTS := out
REGISTRY ?= ghcr.io
VENDOR ?= sentinelos
REGISTRY_AND_VENDOR ?= $(REGISTRY)/$(VENDOR)

SOURCE_DATE_EPOCH ?= "1559424892"

# Sync packer image with Pkgfile
PACKER ?= nerdctl run --rm --volume $(PWD):/packages --entrypoint=packer ghcr.io/sentinelos/packer:0.0.1 graph --root=/packages

# nerdctl build settings
BUILD := nerdctl build
PLATFORM ?= linux/amd64,linux/arm64
PROGRESS ?= auto
COMMON_ARGS = --file=Pkgfile
COMMON_ARGS += --progress=$(PROGRESS)
COMMON_ARGS += --platform=$(PLATFORM)
COMMON_ARGS += --build-arg=http_proxy=$(http_proxy)
COMMON_ARGS += --build-arg=https_proxy=$(https_proxy)
COMMON_ARGS += --build-arg=SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH)
CI_ARGS ?=
PUSH ?= false

TARGETS = \
	certificates \
	fhs

all: $(TARGETS) ## Builds all known packages.

.PHONY: $(TARGETS)
$(TARGETS):
	@$(MAKE) $@-image

%-local: ## Builds the specified target. The build result will be output to the specified local destination.
	@$(MAKE) $*-target TARGET_ARGS="--output=type=local,dest=$(ARTIFACTS) $(TARGET_ARGS)"

%-image: TAG=$(shell cat Pkgfile | grep "$*_version" | sed 's/[^0-9.-]//g')
%-image: ## Builds the specified target. The build result will be loaded into image.
	@$(MAKE) $*-target TARGET_ARGS="--tag=$(REGISTRY_AND_VENDOR)/$*:$(TAG) --output type=image,name=$(REGISTRY_AND_VENDOR)/$*:$(TAG),push=$(PUSH) $(TARGET_ARGS)"

%-target: ## Builds the specified target. The build result will only remain in the build cache.
	@$(BUILD) --target=$* $(COMMON_ARGS) $(TARGET_ARGS) .

.PHONY: deps.png
deps.png:
	@$(PACKER) | dot -Tpng > deps.png

.PHONY: clean
clean:  ## Cleans up all artifacts.
	@rm -rf $(ARTIFACTS)/*

.PHONY: help
help: ## This help menu.
	@grep -E '^[a-zA-Z%_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'