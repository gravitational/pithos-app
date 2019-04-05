export VERSION ?= $(shell ./version.sh)
REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009
TELE ?= $(shell which tele)
GRAVITY ?= $(shell which gravity)
RUNTIME_VERSION ?= $(shell $(TELE) version | awk '/version:/ {print $$2}')

TOP := $(dir $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))

EXTRA_GRAVITY_OPTIONS ?=

CONTAINERS := pithos-bootstrap:$(VERSION) \
	pithos-uninstall:$(VERSION) \
	cassandra:$(VERSION) \
	pithos:$(VERSION) \
	pithos-proxy:$(VERSION) \
	pithos-hook:$(VERSION) \
	pithos-healthz:$(VERSION)

IMPORT_IMAGE_FLAGS := --set-image=pithos-bootstrap:$(VERSION) \
	--set-image=pithos-uninstall:$(VERSION) \
	--set-image=cassandra:$(VERSION) \
	--set-image=pithos:$(VERSION) \
	--set-image=pithos-proxy:$(VERSION) \
	--set-image=pithos-hook:$(VERSION) \
	--set-image=pithos-healthz:$(VERSION)

IMPORT_OPTIONS := --vendor \
		--ops-url=$(OPS_URL) \
		--insecure \
		--repository=$(REPOSITORY) \
		--name=$(NAME) \
		--version=$(VERSION) \
		--glob=**/*.yaml \
		--ignore="alerts.yaml" \
		--ignore=pithos-cfg \
		--exclude="build" \
		--exclude="images" \
		--exclude="Makefile" \
		--exclude="tool" \
		--exclude=".git" \
		$(IMPORT_IMAGE_FLAGS)

TELE_BUILD_OPTIONS := --insecure \
                --repository=$(OPS_URL) \
                --name=$(NAME) \
                --version=$(VERSION) \
                --glob=**/*.yaml \
                --ignore=".git" \
                --ignore="images" \
                --ignore="tool" \
                --ignore="pithos-cfg" \
                --ignore="alerts.yaml" \
                $(IMPORT_IMAGE_FLAGS)

BUILD_DIR := build

.PHONY: all
all: clean images

.PHONY: what-version
what-version:
	@echo $(VERSION)

.PHONY: images
images:
	$(MAKE) -C images VERSION=$(VERSION)

.PHONY: import
import: images
	-$(GRAVITY) app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) --force --insecure $(EXTRA_GRAVITY_OPTIONS)
	$(GRAVITY) app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARBALL): import $(BUILD_DIR)
	$(GRAVITY) package export $(REPOSITORY)/$(NAME):$(VERSION) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

.PHONY: build-app
build-app: $(BUILD_DIR) images
	sed -i "s/version: \"0.0.0+latest\"/version: \"$(RUNTIME_VERSION)\"/" resources/app.yaml
	$(TELE) build -f -o build/installer.tar $(TELE_BUILD_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) resources/app.yaml
	if grep $(RUNTIME_VERSION) resources/app.yaml; then sed -i "s/version: \"$(RUNTIME_VERSION)\"/version: \"0.0.0+latest\"/" resources/app.yaml; fi

.PHONY: clean
clean:
	$(MAKE) -C $(TOP)/images clean
	$(MAKE) -C $(TOP)/tool/pithosboot clean
	$(MAKE) -C $(TOP)/tool/healthz clean
	-rm -rf $(BUILD_DIR)
