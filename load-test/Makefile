VER ?= latest

CONTENT_GENERATE_TAG := pithos-content-generate:$(VER)

.PHONY: all
all: content-generate

.PHONY: content-generate
content-generate:
	docker build -t $(BACKUP_TAG) $(PWD)/content-generate
