VER := 0.0.5
REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009

CONTAINERS := pithos-bootstrap:$(VER) pithos-uninstall:$(VER) cassandra:$(VER) pithos:$(VER) pithos-proxy:$(VER)

IMPORT_IMAGE_FLAGS := --set-image=pithos-bootstrap:$(VER) \
	--set-image=pithos-uninstall:$(VER) \
	--set-image=cassandra:$(VER) \
	--set-image=pithos:$(VER) \
	--set-image=pithos-proxy:$(VER) \
	--set-dep=gravitational.io/k8s-onprem:$$(gravity app list --ops-url=$(OPS_URL) --insecure|grep -m 1 k8s-onprem|awk '{print $$3}'|cut -d: -f2|cut -d, -f1)

IMPORT_OPTIONS := --vendor \
		--ops-url=$(OPS_URL) \
		--insecure \
		--repository=$(REPOSITORY) \
		--name=$(NAME) \
		--version=$(VER) \
		--glob=**/*.yaml \
		--ignore=dev \
		--ignore=cassandra-cfg \
		--ignore=pithos-cfg \
		--registry-url=apiserver:5000 \
		$(IMPORT_IMAGE_FLAGS)

.PHONY: all
all: clean images

.PHONY: images
images:
	cd images && $(MAKE) -f Makefile VERSION=$(VER)

.PHONY: import
import: clean images
	-gravity app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VER) --force --insecure
	gravity app import $(IMPORT_OPTIONS) .

.PHONY: clean
clean:
	-rm images/bootstrap/pithosboot
