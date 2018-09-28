export VERSION ?= $(shell git describe --long --tags --always|awk -F'[.-]' '{print $$1 "." $$2 "." $$4}')
REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009

SRCDIR=/go/src/github.com/gravitational/pithos-app
DOCKERFLAGS=--rm=true -v $(PWD):$(SRCDIR) -v $(GOPATH)/pkg:/gopath/pkg -w $(SRCDIR)
BUILDIMAGE=quay.io/gravitational/debian-venti:go1.9-stretch

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
                $(IMPORT_IMAGE_FLAGS)

BUILD_DIR := build
TARBALL := $(BUILD_DIR)/pithos-app.tar.gz

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
	-gravity app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) --force --insecure $(EXTRA_GRAVITY_OPTIONS)
	gravity app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

.PHONY: export
export: $(TARBALL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARBALL): import $(BUILD_DIR)
	gravity package export $(REPOSITORY)/$(NAME):$(VERSION) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

.PHONY: build-app
build-app: clean images | $(BUILD_DIR)
	tele build -o build/installer.tar $(TELE_BUILD_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) resources/app.yaml

.PHONY: build-pithosctl
build-pithosctl: $(BUILD_DIR)
	docker run $(DOCKERFLAGS) $(BUILDIMAGE) make build/pithosctl
	for dir in bootstrap healthz; do mkdir -p images/$${dir}/bin; cp build/pithosctl images/$${dir}/bin/; done

.PHONY: pithosctl
build/pithosctl:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a -installsuffix cgo -o $@ cmd/pithosctl/*.go

.PHONY: clean
clean:
	$(MAKE) -C images clean
	for dir in bootstrap healthz; do rm -rf images/$${dir}/bin; done
	-rm -rf $(BUILD_DIR)
