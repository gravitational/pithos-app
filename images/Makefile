.PHONY: all
all: images

VERSION ?= 0.0.3

BOOTSTRAP_TAG:=pithos-bootstrap:$(VERSION)
UNINSTALL_TAG:=pithos-uninstall:$(VERSION)
PITHOS_TAG:=pithos:$(VERSION)
CASSANDRA_TAG:=cassandra:$(VERSION)
S3CMD_TAG:=s3cmd:$(VERSION)

.PHONY: images
images: bootstrap uninstall cassandra pithos s3cmd

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

.PHONY: s3cmd
s3cmd:
	docker build -t $(S3CMD_TAG) $(PWD)/s3cmd
