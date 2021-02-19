ifeq ($(origin VERSION), undefined)
# avoid ?= lazily evaluating version.sh (and thus rerunning the shell command several times)
VERSION := $(shell ./version.sh)
endif

REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?=
TELE ?= $(shell which tele)
GRAVITY ?= $(shell which gravity)
INTERMEDIATE_RUNTIME_VERSION ?=
GRAVITY_VERSION ?= 7.0.30
CLUSTER_SSL_APP_VERSION ?= 0.8.4
CLUSTER_SSL_APP_URL ?= https://github.com/gravitational/cluster-ssl-app/releases/download/${CLUSTER_SSL_APP_VERSION}/cluster-ssl-app-${CLUSTER_SSL_APP_VERSION}.tar.gz
STATEDIR ?= state

SRCDIR=/go/src/github.com/gravitational/pithos-app
DOCKERFLAGS=--rm=true -u $$(id -u):$$(id -g) -e GOCACHE=/tmp/.cache -v $(PWD):$(SRCDIR) -v $(GOPATH)/pkg:/gopath/pkg -w $(SRCDIR)
BUILDIMAGE=quay.io/gravitational/debian-venti:go1.12.9-buster

EXTRA_GRAVITY_OPTIONS ?=
TELE_BUILD_EXTRA_OPTIONS ?=
# if variable is not empty add an extra parameter to tele build
ifneq ($(INTERMEDIATE_RUNTIME_VERSION),)
	TELE_BUILD_EXTRA_OPTIONS +=  --upgrade-via=$(INTERMEDIATE_RUNTIME_VERSION)
endif

# add state directory to the commands if STATEDIR variable not empty
ifneq ($(STATEDIR),)
	EXTRA_GRAVITY_OPTIONS +=  --state-dir=$(STATEDIR)
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

ifneq ($(OPS_URL),)
	TELE_BUILD_EXTRA_OPTIONS +=  --repository=$(OPS_URL)
endif

TELE_BUILD_OPTIONS := --name=$(NAME) \
		--version=$(VERSION) \
		--glob=**/*.yaml \
		--ignore="pithos-cfg/*.yaml" \
		--ignore="alerts.yaml" \
		$(TELE_BUILD_EXTRA_OPTIONS) \
		$(IMPORT_IMAGE_FLAGS)

BUILD_DIR := build
BINARIES_DIR := bin
TARBALL := build/application.tar

.PHONY: all
all: clean images

.PHONY: what-version
what-version:
	@echo $(VERSION)

.PHONY: images
images:
	$(MAKE) -C images VERSION=$(VERSION)

.PHONY: import
import: images | $(BUILD_DIR)
	$(GRAVITY) app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VERSION) --force $(EXTRA_GRAVITY_OPTIONS)
	$(GRAVITY) app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BINARIES_DIR):
	mkdir -p $(BINARIES_DIR)

$(STATEDIR):
	mkdir -p $(STATEDIR)

.PHONY: export
export: import $(TARBALL)

$(TARBALL):
	$(GRAVITY) package export $(REPOSITORY)/$(NAME):$(VERSION) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

# .PHONY because VERSION is dynamic
.PHONY: $(BUILD_DIR)/resources/app.yaml
$(BUILD_DIR)/resources/app.yaml: | $(BUILD_DIR)
	cp --archive resources build
	sed -i "s#gravitational.io/cluster-ssl-app:0.0.0+latest#gravitational.io/cluster-ssl-app:$(CLUSTER_SSL_APP_VERSION)#" build/resources/app.yaml

.PHONY: build-app
build-app: images $(BUILD_DIR)/resources/app.yaml | $(BUILD_DIR)
	$(GRAVITY) $(EXTRA_GRAVITY_OPTIONS) package list
	$(TELE) build -f -o build/installer.tar $(TELE_BUILD_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) build/resources/app.yaml

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

.PHONY: robotest-run-suite
robotest-run-suite:
	./robotest/run.sh pr

.PHONY: download-binaries
download-binaries: $(BINARIES_DIR)
	for name in gravity tele; \
	do \
		curl https://get.gravitational.io/telekube/bin/$(GRAVITY_VERSION)/linux/x86_64/$$name -o $(BINARIES_DIR)/$$name; \
		chmod +x $(BINARIES_DIR)/$$name; \
	done

.PHONY: install-dependent-packages
install-dependent-packages: clean-state-dir $(STATEDIR) $(BUILD_DIR)
	$(TELE) pull gravity:$(GRAVITY_VERSION) $(EXTRA_GRAVITY_OPTIONS) -o $(BUILD_DIR)/gravity.tar --force
	tar xf $(BUILD_DIR)/gravity.tar -C $(STATEDIR) gravity.db packages
	curl -L $(CLUSTER_SSL_APP_URL) -o $(BUILD_DIR)/cluster-ssl-app.tar.gz
	$(GRAVITY) $(EXTRA_GRAVITY_OPTIONS) app import $(BUILD_DIR)/cluster-ssl-app.tar.gz

.PHONY: clean
clean: clean-state-dir
	$(MAKE) -C images clean
	-rm -rf images/{bootstrap,pithosctl,hook}/bin
	-rm -rf $(BUILD_DIR)
	-rm -rf wd_suite

clean-state-dir:
	-rm -rf $(STATEDIR)

.PHONY: push
push:
	$(TELE) push -f $(EXTRA_GRAVITY_OPTIONS) $(BUILD_DIR)/installer.tar

.PHONY: get-version
get-version:
	@echo $(VERSION)
