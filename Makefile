VER ?= $(shell git describe --long --tags --always|awk -F'[.-]' '{print $$1 "." $$2 "." $$4}')
REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009

EXTRA_GRAVITY_OPTIONS ?=

CONTAINERS := pithos-bootstrap:$(VER) \
	pithos-uninstall:$(VER) \
	cassandra:$(VER) \
	pithos:$(VER) \
	pithos-proxy:$(VER) \
	pithos-test-content:$(VER)

IMPORT_IMAGE_FLAGS := --set-image=pithos-bootstrap:$(VER) \
	--set-image=pithos-uninstall:$(VER) \
	--set-image=cassandra:$(VER) \
	--set-image=pithos:$(VER) \
	--set-image=pithos-proxy:$(VER) \
	--set-image=pithos-test-content:$(VER)

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
		--exclude="build" \
		--exclude="gravity.log" \
		--exclude="images" \
		--exclude="Makefile" \
		--exclude="tool" \
		--exclude=".git" \
		--exclude="load-test" \
		--registry-url=apiserver:5000 \
		$(IMPORT_IMAGE_FLAGS)

BUILD_DIR := build
TARBALL := $(BUILD_DIR)/pithos-app.tar.gz

.PHONY: all
all: clean images

.PHONY: what-version
what-version:
	@echo $(VER)

.PHONY: images
images:
	cd images && $(MAKE) -f Makefile VERSION=$(VER)

.PHONY: import
import: images
	-gravity app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VER) --force --insecure $(EXTRA_GRAVITY_OPTIONS)
	gravity app import $(IMPORT_OPTIONS) $(EXTRA_GRAVITY_OPTIONS) .

.PHONY: export
export: $(TARBALL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARBALL): import $(BUILD_DIR)
	gravity package export $(REPOSITORY)/$(NAME):$(VER) $(TARBALL) $(EXTRA_GRAVITY_OPTIONS)

.PHONY: clean
clean:
	$(MAKE) -C images clean

.PHONY: dev-push
dev-push: images
	for container in $(CONTAINERS); do \
		docker tag $$container apiserver:5000/$$container ;\
		docker push apiserver:5000/$$container ;\
	done

.PHONY: dev-redeploy
dev-redeploy: dev-clean dev-deploy

.PHONY: dev-deploy
dev-deploy: dev-push
	-kubectl label nodes -l role=node pithos-role=node
	kubectl create configmap cassandra-cfg --from-file=resources/cassandra-cfg
	kubectl create configmap pithos-cfg --from-file=resources/pithos-cfg
	kubectl create -f resources/pithos.yaml

.PHONY: dev-clean
dev-clean:
	-kubectl delete -f resources/pithos.yaml
	-kubectl delete configmap cassandra-cfg pithos-cfg
	-kubectl label nodes -l pithos-role=node pithos-role-

.PHONY: dev-test-content
dev-test-content:
	-kubectl delete -f resources/test-content.yaml
	kubectl create -f resources/test-content.yaml
