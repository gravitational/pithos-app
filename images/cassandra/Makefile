# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# build the cassandra image.

all: build-go

NOROOT=-u $$(id -u):$$(id -g)
SRCDIR=/go/src/github.com/gravitational/pithos-app/images/cassandra
DOCKERFLAGS=--rm=true $(NOROOT) -v $(CURDIR):$(SRCDIR) -w $(SRCDIR)
BUILDIMAGE=golang:1.9

.PHONY: build-go
build-go:
	mkdir -p build
	docker run $(DOCKERFLAGS) $(BUILDIMAGE) make build

.PHONY: build
build:
	go build -a -installsuffix cgo \
		-ldflags "-s -w" \
		-o build/cassandra-seed.so -buildmode=c-shared go/main.go
