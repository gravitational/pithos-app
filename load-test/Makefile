VER ?= latest

CONTENT_GENERATE_TAG := pithos-content-generate:$(VER)

.PHONY: content-generate
content-generate:
	docker build -t $(BACKUP_TAG) $(PWD)/content-generate

.PHONY: dev-push
dev-push:
	docker tag pithos-content-generate apiserver:5000/pithos-content-generate
	docker push apiserver:5000/pithos-content-generate

.PHONY: dev-hatest
dev-hatest:
	-kubectl delete -f content-generate.yaml
	kubectl create -f content-generate.yaml
