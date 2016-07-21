.PHONY: all
all: images

BOOTSTRAP_TAG:=pithos-bootstrap:$(VERSION)
UNINSTALL_TAG:=pithos-uninstall:$(VERSION)
PITHOS_TAG:=pithos:$(VERSION)
CASSANDRA_TAG:=cassandra:$(VERSION)

.PHONY: images
images: bootstrap uninstall cassandra pithos
	docker tag $(BOOTSTRAP_TAG) pithos-bootstrap:latest
	docker tag $(UNINSTALL_TAG) pithos-uninstall:latest
	docker tag $(PITHOS_TAG) pithos:latest
	docker tag $(CASSANDRA_TAG) cassandra:latest

PITHOSBOOT_BINS:=bootstrap/pithosboot
$(PITHOSBOOT_BINS):
	cd ../tool/pithosboot && make clean build
	cp ../tool/pithosboot/bin/pithosboot bootstrap/pithosboot

.PHONY: bootstrap
bootstrap: $(PITHOSBOOT_BINS)
	docker build -t $(BOOTSTRAP_TAG) $(PWD)/bootstrap

.PHONY: uninstall
uninstall:
	docker build -t $(UNINSTALL_TAG) $(PWD)/uninstall

.PHONY: cassandra
cassandra:
	docker build -t $(CASSANDRA_TAG) $(PWD)/cassandra

.PHONY: pithos
pithos:
	cd pithos && $(MAKE) TAG=$(PITHOS_TAG)

