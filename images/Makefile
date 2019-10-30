VERSION ?= latest
CASSANDRA_VERSION ?= 3.11.5
# JMX -> json bridge agent(needed for getting metrics from Cassandra)
JOLOKIA_VERSION ?= 1.6.0
TELEGRAF_VERSION ?= 1.7.4

BOOTSTRAP_TAG := pithos-bootstrap:$(VERSION)
UNINSTALL_TAG := pithos-uninstall:$(VERSION)
PITHOS_TAG := pithos:$(VERSION)
CASSANDRA_TAG := cassandra:$(VERSION)
PROXY_TAG := pithos-proxy:$(VERSION)
HOOK_TAG := pithos-hook:$(VERSION)
PITHOSCTL_TAG := pithosctl:$(VERSION)

IMAGES_WITH_PITHOSCTL := bootstrap pithosctl

.PHONY: all
all: images

.PHONY: images
images: bootstrap uninstall cassandra pithos proxy hook pithosctl
	docker tag $(BOOTSTRAP_TAG) pithos-bootstrap:latest
	docker tag $(UNINSTALL_TAG) pithos-uninstall:latest
	docker tag $(PITHOS_TAG) pithos:latest
	docker tag $(CASSANDRA_TAG) cassandra:latest
	docker tag $(PROXY_TAG) pithos-proxy:latest
	docker tag $(HOOK_TAG) pithos-hook:latest
	docker tag $(PITHOSCTL_TAG) pithosctl:latest

.PHONY: build-pithosctl
build-pithosctl:
	$(MAKE) -C ../ build-pithosctl

TAG_VARIABLE_NAME = $(shell echo '$@' | tr '[:lower:]' '[:upper:]')_TAG
.PHONY: $(IMAGES_WITH_PITHOSCTL)
$(IMAGES_WITH_PITHOSCTL): build-pithosctl
	docker build --pull -t $($(TAG_VARIABLE_NAME)) $@

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

.PHONY: clean
clean:
	-rm -f cassandra/rootfs/kubernetes-cassandra.jar
