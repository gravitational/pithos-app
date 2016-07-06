.PHONY: all
all: images

VERSION ?= 0.0.1

BOOTSTRAP_TAG:=pithos-bootstrap:$(VERSION)
UNINSTALL_TAG:=pithos-uninstall:$(VERSION)
CASSANDRA_TAG:=cassandra:$(VERSION)

.PHONY: images
images: bootstrap uninstall cassandra

.PHONY: bootstrap
bootstrap:
	docker build -t $(BOOTSTRAP_TAG) $(PWD)/bootstrap

.PHONY: uninstall
uninstall:
	docker build -t $(UNINSTALL_TAG) $(PWD)/uninstall

.PHONY: cassandra
cassandra:
	docker build -t $(CASSANDRA_TAG) $(PWD)/cassandra

.PHONY: clean
clean:
	-rm bootstrap/pithosboot

