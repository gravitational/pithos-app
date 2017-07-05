TAG ?= pithos:0.0.1

OUT:=pithos.jar

.PHONY: all
all: image

.PHONY: image
image: $(OUT)
	docker build -t $(TAG) .

#$(OUT):
#	wget https://github.com/exoscale/pithos/releases/download/0.7.5/pithos-0.7.5-standalone.jar -O $(PWD)/$(OUT)

.PHONY: clean
clean:
	rm -rf $(OUT)


