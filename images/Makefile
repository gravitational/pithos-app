VERSION ?= latest

BOOTSTRAP_TAG := pithos-bootstrap:$(VERSION)
UNINSTALL_TAG := pithos-uninstall:$(VERSION)
PITHOS_TAG := pithos:$(VERSION)
CASSANDRA_TAG := cassandra:$(VERSION)
PROXY_TAG := pithos-proxy:$(VERSION)
HOOK_TAG := pithos-hook:$(VERSION)
HEALTHZ_TAG := pithos-healthz:$(VERSION)

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

BOOTSTRAP_BINS := bootstrap/bin
$(BOOTSTRAP_BINS):
	mkdir -p $(BOOTSTRAP_BINS)
	cd ../tool/pithosboot && make clean build
	cp ../tool/pithosboot/bin/pithosboot $(BOOTSTRAP_BINS)/pithosboot

HEALTHZ_BINS := healthz/bin
$(HEALTHZ_BINS):
	mkdir -p $(HEALTHZ_BINS)
	cd ../tool/healthz && make clean build
	cp ../tool/healthz/bin/healthz $(HEALTHZ_BINS)/healthz

.PHONY: bootstrap
bootstrap: $(BOOTSTRAP_BINS)
	docker build --pull -t $(BOOTSTRAP_TAG) $(PWD)/bootstrap

.PHONY: uninstall
uninstall:
	docker build --pull -t $(UNINSTALL_TAG) $(PWD)/uninstall

.PHONY: cassandra
cassandra:
	docker build --pull -t $(CASSANDRA_TAG) $(PWD)/cassandra

.PHONY: proxy
proxy:
	docker build --pull -t $(PROXY_TAG) $(PWD)/proxy

.PHONY: pithos
pithos: $(PITHOS_BINS)
	cd pithos && $(MAKE) TAG=$(PITHOS_TAG)

.PHONY: hook
hook:
	$(eval CHANGESET = $(shell echo $$VERSION | sed -e 's/[\.]//g'))
	if [ -z "$(CHANGESET)" ]; then \
		echo "CHANGESET is not set"; exit 1; \
	fi;
	docker build --pull --build-arg CHANGESET=pithos-$(CHANGESET) -t $(HOOK_TAG) $(PWD)/hook

.PHONY: heathz
healthz: $(HEALTHZ_BINS)
	docker build --pull -t $(HEALTHZ_TAG) $(PWD)/healthz

.PHONY: clean
clean:
	-rm -rf $(BOOTSTRAP_BINS)
