.PHONY: all
all: bin/pithosboot

NOROOT=-u $$(id -u):$$(id -g)
SRCDIR=/go/src/github.com/gravitational/pithos-app
DOCKERFLAGS=--rm=true $(NOROOT) -v $(PWD):$(SRCDIR) -w $(SRCDIR) -e GO15VENDOREXPERIMENT=1
BUILDIMAGE=golang:1.9

.PHONY: build
build:
	docker run $(DOCKERFLAGS) $(BUILDIMAGE) make clean all

bin/pithosboot: *.go
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a -installsuffix cgo -o $@ .

.PHONY: clean
clean:
	rm -rf bin
