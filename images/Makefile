VERSION ?= latest

BOOTSTRAP_TAG := pithos-bootstrap:$(VERSION)
UNINSTALL_TAG := pithos-uninstall:$(VERSION)
PITHOS_TAG := pithos:$(VERSION)
CASSANDRA_TAG := cassandra:$(VERSION)
PROXY_TAG := pithos-proxy:$(VERSION)

.PHONY: all
all: images

.PHONY: images
images: bootstrap uninstall cassandra pithos proxy
	docker tag $(BOOTSTRAP_TAG) pithos-bootstrap:latest
	docker tag $(UNINSTALL_TAG) pithos-uninstall:latest
	docker tag $(PITHOS_TAG) pithos:latest
	docker tag $(CASSANDRA_TAG) cassandra:latest
	docker tag $(PROXY_TAG) pithos-proxy:latest

BOOTSTRAP_BINS := bootstrap/bin
$(BOOTSTRAP_BINS):
	mkdir -p $(BOOTSTRAP_BINS)
	cd ../tool/pithosboot && make clean build
	cp ../tool/pithosboot/bin/pithosboot bootstrap/bin/pithosboot
	wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O bootstrap/bin/cfssl
	wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O bootstrap/bin/cfssljson

.PHONY: bootstrap
bootstrap: $(BOOTSTRAP_BINS)
	docker build -t $(BOOTSTRAP_TAG) $(PWD)/bootstrap

.PHONY: uninstall
uninstall:
	docker build -t $(UNINSTALL_TAG) $(PWD)/uninstall

.PHONY: cassandra
cassandra:
	docker build -t $(CASSANDRA_TAG) $(PWD)/cassandra

.PHONY: proxy
proxy:
	docker build -t $(PROXY_TAG) $(PWD)/proxy

.PHONY: pithos
pithos:
	cd pithos && $(MAKE) TAG=$(PITHOS_TAG)

,PHONY: clean
clean:
	-rm -rf $(BOOTSTRAP_BINS)
