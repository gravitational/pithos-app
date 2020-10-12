export VERSION ?= $(shell ./version.sh)
REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009
TELE ?= $(shell which tele)
GRAVITY ?= $(shell which gravity)
RUNTIME_VERSION ?= $(shell $(TELE) version | awk '/^[vV]ersion:/ {print $$2}')
INTERMEDIATE_RUNTIME_VERSION ?=
GRAVITY_VERSION ?= 5.5.21
CLUSTER_SSL_APP_VERSION ?= "0.0.0+latest"

SRCDIR=/go/src/github.com/gravitational/pithos-app
DOCKERFLAGS=--rm=true -v $(PWD):$(SRCDIR) -v $(GOPATH)/pkg:/gopath/pkg -w $(SRCDIR)
BUILDIMAGE=quay.io/gravitational/debian-venti:go1.12.9-buster

EXTRA_GRAVITY_OPTIONS ?=
TELE_BUILD_EXTRA_OPTIONS ?=
# if variable is not empty add an extra parameter to tele build
ifneq ($(INTERMEDIATE_RUNTIME_VERSION),)
	TELE_BUILD_EXTRA_OPTIONS +=  --upgrade-via=$(INTERMEDIATE_RUNTIME_VERSION)
endif

CONTAINERS := pithos-bootstrap:$(VERSION) \
	pithos-uninstall:$(VERSION) \
	cassandra:$(VERSION) \
	pithos:$(VERSION) \
	pithos-proxy:$(VERSION) \
	pithos-hook:$(VERSION) \
	pithosctl:$(VERSION)

IMPORT_IMAGE_FLAGS := --set-image=pithos-bootstrap:$(VERSION) \
	--set-image=pithos-uninstall:$(VERSION) \
	--set-image=cassandra:$(VERSION) \
	--set-image=pithos:$(VERSION) \
	--set-image=pithos-proxy:$(VERSION) \
	--set-image=pithos-hook:$(VERSION) \
	--set-image=pithosctl:$(VERSION)

IMPORT_OPTIONS := --vendor \
		--ops-url=$(OPS_URL) \
		--repository=$(REPOSITORY) \
		--name=$(NAME) \
		--version=$(VERSION) \
		--glob=**/*.yaml \
		--include="resources" \
		--include="registry" \
		--ignore="pithos-cfg" \
		--ignore="vendor/**/*.yaml" \
		--ignore="alerts.yaml" \
		$(IMPORT_IMAGE_FLAGS)

TELE_BUILD_OPTIONS := --repository=$(OPS_URL) \
		--name=$(NAME) \
		--version=$(VERSION) \
		--glob=**/*.yaml \
		--ignore="pithos-cfg/*.yaml" \
		--ignore="alerts.yaml" \
		$(TELE_BUILD_EXTRA_OPTIONS) \
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
	-$(GRAVITY) app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) --force $(EXTRA_GRAVITY_OPTIONS)
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
	-$(TELE) build -f -o build/installer.tar $(TELE_BUILD_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) resources/app.yaml
	sed -i "s/version: \"$(RUNTIME_VERSION)\"/version: \"0.0.0+latest\"/" resources/app.yaml
	sed -i "s#gravitational.io/cluster-ssl-app:$(CLUSTER_SSL_APP_VERSION)#gravitational.io/cluster-ssl-app:0.0.0+latest#" resources/app.yaml

.PHONY: build-pithosctl
build-pithosctl: $(BUILD_DIR)
	docker run $(DOCKERFLAGS) $(BUILDIMAGE) make build-pithosctl-docker
	for dir in bootstrap pithosctl hook; do mkdir -p images/$${dir}/bin; cp build/pithosctl images/$${dir}/bin/; done

.PHONY: build-pithosctl-docker
build-pithosctl-docker:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a -installsuffix cgo -o build/pithosctl cmd/pithosctl/*.go

#
# number of environment variables are expected to be set
# see https://github.com/gravitational/robotest/blob/master/suite/README.md
#
.PHONY: robotest-run-suite
robotest-run-suite:
	./scripts/robotest_run_suite.sh $(shell pwd)/upgrade_from

.PHONY: download-binaries
download-binaries: $(BINARIES_DIR)
	for name in gravity tele; \
	do \
		curl https://get.gravitational.io/telekube/bin/$(GRAVITY_VERSION)/linux/x86_64/$$name -o $(BINARIES_DIR)/$$name; \
		chmod +x $(BINARIES_DIR)/$$name; \
	done

.PHONY: clean
clean:
	$(MAKE) -C images clean
	-rm -rf images/{bootstrap,pithosctl,hook}/bin
	-rm -rf $(BUILD_DIR)
	-rm -rf wd_suite

.PHONY: push
push:
	$(TELE) push -f $(EXTRA_GRAVITY_OPTIONS) $(BUILD_DIR)/installer.tar
