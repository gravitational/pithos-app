VERSION ?= latest
CASSANDRA_VERSION ?= 3.11.4
# JMX -> json bridge agent(needed for getting metrics from Cassandra)
JOLOKIA_VERSION ?= 1.5.0
TELEGRAF_VERSION ?= 1.6.4

BOOTSTRAP_TAG := pithos-bootstrap:$(VERSION)
UNINSTALL_TAG := pithos-uninstall:$(VERSION)
PITHOS_TAG := pithos:$(VERSION)
CASSANDRA_TAG := cassandra:$(VERSION)
PROXY_TAG := pithos-proxy:$(VERSION)
HOOK_TAG := pithos-hook:$(VERSION)
HEALTHZ_TAG := pithos-healthz:$(VERSION)

TOOL_DIR := ../tool

.PHONY: all
all: images

.PHONY: images
images: bootstrap uninstall cassandra pithos proxy hook healthz
	docker tag $(BOOTSTRAP_TAG) pithos-bootstrap:latest
	docker tag $(UNINSTALL_TAG) pithos-uninstall:latest
	docker tag $(PITHOS_TAG) pithos:latest
	docker tag $(CASSANDRA_TAG) cassandra:latest
	docker tag $(PROXY_TAG) pithos-proxy:latest
	docker tag $(HOOK_TAG) pithos-hook:latest
	docker tag $(HEALTHZ_TAG) pithos-healthz:latest

.PHONY: bootstrap-build
bootstrap-build:
	$(MAKE) -C $(TOOL_DIR)/pithosboot build

BOOTSTRAP_BINS := bootstrap/bin
$(BOOTSTRAP_BINS): bootstrap-build
	mkdir -p $(BOOTSTRAP_BINS)
	cp $(TOOL_DIR)/pithosboot/bin/pithosboot $(BOOTSTRAP_BINS)/pithosboot

.PHONY: healthz-build
healthz-build:
	$(MAKE) -C $(TOOL_DIR)/healthz build

HEALTHZ_BINS := healthz/bin
$(HEALTHZ_BINS): healthz-build
	mkdir -p $(HEALTHZ_BINS)
	cp $(TOOL_DIR)/healthz/bin/healthz $(HEALTHZ_BINS)/healthz

.PHONY: bootstrap
bootstrap: $(BOOTSTRAP_BINS)
	docker build --pull -t $(BOOTSTRAP_TAG) bootstrap

.PHONY: uninstall
uninstall:
	docker build --pull -t $(UNINSTALL_TAG) uninstall

.PHONY: cassandra
cassandra:
	docker build --pull --build-arg CASSANDRA_VERSION=$(CASSANDRA_VERSION) \
		--build-arg JOLOKIA_VERSION=$(JOLOKIA_VERSION) \
		--build-arg TELEGRAF_VERSION=$(TELEGRAF_VERSION) \
		-t $(CASSANDRA_TAG) cassandra

.PHONY: proxy
proxy:
	docker build --pull -t $(PROXY_TAG) proxy

.PHONY: pithos
pithos:
	$(MAKE) -C pithos TAG=$(PITHOS_TAG)

.PHONY: hook
hook:
	$(eval CHANGESET = $(shell echo $$VERSION | sed -e 's/[\.]//g'))
	if [ -z "$(CHANGESET)" ]; then \
		echo "CHANGESET is not set"; exit 1; \
	fi;
	docker build --pull --build-arg CHANGESET=pithos-$(CHANGESET) -t $(HOOK_TAG) hook

.PHONY: healthz
healthz: $(HEALTHZ_BINS)
	docker build --pull -t $(HEALTHZ_TAG) healthz

.PHONY: clean
clean:
	-rm -rf $(BOOTSTRAP_BINS)
	-rm -rf $(HEALTHZ_BINS)
	-rm -f cassandra/rootfs/kubernetes-cassandra.jar
