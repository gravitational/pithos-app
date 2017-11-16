.PHONY: all
all: bin/pithosboot

NOROOT=-u $$(id -u):$$(id -g)
SRCDIR=/go/src/github.com/gravitational/pithos-app/tool/pithosboot
DOCKERFLAGS=--rm=true $(NOROOT) -v $(CURDIR):$(SRCDIR) -w $(SRCDIR)
BUILDIMAGE=golang:1.9

.PHONY: build
build:
	echo $(CURDIR)
	docker run $(DOCKERFLAGS) $(BUILDIMAGE) make all

bin/pithosboot: *.go
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -a -installsuffix cgo -o $@ .

.PHONY: clean
clean:
	rm -rf bin
