TAG ?= pithos:0.0.1

.PHONY: all
all: image

.PHONY: image
image:
	docker build -t $(TAG) .

.PHONY: clean
clean:
	rm -rf $(OUT)


