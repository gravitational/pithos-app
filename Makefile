export VERSION ?= $(shell ./version.sh)
REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009
TELE ?= $(shell which tele)
GRAVITY ?= $(shell which gravity)
RUNTIME_VERSION ?= $(shell $(TELE) version | awk '/^[vV]ersion:/ {print $$2}')
CLUSTER_SSL_APP_VERSION ?= "0.0.0+latest"

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
	pithos-healthz:$(VERSION) \
	pithosctl:$(VERSION)

FILE_LIST := $(shell ls -1A)
WHITELISTED_RESOURCE_NAMES := resources

IMPORT_IMAGE_FLAGS := --set-image=pithos-bootstrap:$(VERSION) \
	--set-image=pithos-uninstall:$(VERSION) \
	--set-image=cassandra:$(VERSION) \
	--set-image=pithos:$(VERSION) \
	--set-image=pithos-proxy:$(VERSION) \
	--set-image=pithos-hook:$(VERSION) \
	--set-image=pithos-healthz:$(VERSION) \
	--set-image=pithosctl:$(VERSION)

IMPORT_OPTIONS := --vendor \
		--ops-url=$(OPS_URL) \
		--insecure \
		--repository=$(REPOSITORY) \
		--name=$(NAME) \
		--version=$(VERSION) \
		--glob=**/*.yaml \
		--include="resources" \
		--include="registry" \
		--ignore="alerts.yaml" \
		--ignore="pithos-cfg" \
		--ignore="vendor/**/*.yaml" \
		$(IMPORT_IMAGE_FLAGS)

TELE_BUILD_OPTIONS := --insecure \
                --repository=$(OPS_URL) \
                --name=$(NAME) \
                --version=$(VERSION) \
                --glob=**/*.yaml \
				$(foreach resource, $(filter-out $(WHITELISTED_RESOURCE_NAMES), $(FILE_LIST)), --ignore="$(resource)") \
                --ignore="pithos-cfg" \
                --ignore="alerts.yaml" \
                $(IMPORT_IMAGE_FLAGS)

BUILD_DIR := build
BINARIES_DIR := bin

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
	sed -i "s/version: \"0.0.0+latest\"/version: \"$(RUNTIME_VERSION)\"/" resources/app.yaml
	sed -i "s#gravitational.io/cluster-ssl-app:0.0.0+latest#gravitational.io/cluster-ssl-app:$(CLUSTER_SSL_APP_VERSION)#" resources/app.yaml
	-$(GRAVITY) app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) --force --insecure $(EXTRA_GRAVITY_OPTIONS)
	$(GRAVITY) app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .
	sed -i "s/version: \"$(RUNTIME_VERSION)\"/version: \"0.0.0+latest\"/" resources/app.yaml
	sed -i "s#gravitational.io/cluster-ssl-app:$(CLUSTER_SSL_APP_VERSION)#gravitational.io/cluster-ssl-app:0.0.0+latest#" resources/app.yaml


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BINARIES_DIR):
	mkdir -p $(BINARIES_DIR)

$(TARBALL): import $(BUILD_DIR)
	$(GRAVITY) package export $(REPOSITORY)/$(NAME):$(VERSION) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

.PHONY: build-app
build-app: images | $(BUILD_DIR)
	sed -i "s/version: \"0.0.0+latest\"/version: \"$(RUNTIME_VERSION)\"/" resources/app.yaml
	sed -i "s#gravitational.io/cluster-ssl-app:0.0.0+latest#gravitational.io/cluster-ssl-app:$(CLUSTER_SSL_APP_VERSION)#" resources/app.yaml
	$(TELE) build -f -o build/installer.tar $(TELE_BUILD_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) resources/app.yaml
	sed -i "s/version: \"$(RUNTIME_VERSION)\"/version: \"0.0.0+latest\"/" resources/app.yaml
	sed -i "s#gravitational.io/cluster-ssl-app:$(CLUSTER_SSL_APP_VERSION)#gravitational.io/cluster-ssl-app:0.0.0+latest#" resources/app.yaml

.PHONY: build-pithosctl
build-pithosctl: $(BUILD_DIR)
	docker run $(DOCKERFLAGS) $(BUILDIMAGE) make build-pithosctl-docker
	for dir in bootstrap healthz pithosctl; do mkdir -p images/$${dir}/bin; cp build/pithosctl images/$${dir}/bin/; done

.PHONY: build-pithosctl-docker
build-pithosctl-docker:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a -installsuffix cgo -o build/pithosctl cmd/pithosctl/*.go

.PHONY: clean
clean:
	$(MAKE) -C images clean
	-rm -rf images/{bootstrap,healthz,pithosctl}/bin
	-rm -rf $(BUILD_DIR)
