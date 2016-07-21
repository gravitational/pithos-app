VER := 0.0.3
REPOSITORY := gravitational.io
NAME := pithos-app
OPS_URL ?= https://opscenter.localhost.localdomain:33009

CONTAINERS := pithos-bootstrap:$(VER) pithos-uninstall:$(VER) cassandra:$(VER) pithos:$(VER)

.PHONY: all
all: clean images

.PHONY: images
images:
	cd images && $(MAKE) -f Makefile VERSION=$(VER)

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
	kubectl create -f dev/pithos.yaml

.PHONY: dev-clean
dev-clean:
	-kubectl delete -f dev/pithos.yaml
	-kubectl delete configmap cassandra-cfg pithos-cfg
	-kubectl label nodes -l pithos-role=node pithos-role-

.PHONY: import
import: clean images
	-gravity app delete --ops-url=$(OPS_URL) $(REPOSITORY)/$(NAME):$(VER) --force --insecure
	gravity app import --vendor --glob=**/*.yaml --ignore=dev --ignore=cassandra-cfg --ignore=pithos-cfg --registry-url=apiserver:5000 --ops-url=$(OPS_URL) --repository=$(REPOSITORY) --name=$(NAME) --version=$(VER) --rewrite-version=latest:$(VER) --insecure .

.PHONY: clean
clean:
	rm images/bootstrap/pithosboot
