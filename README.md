# pithos-app

Pithos Application is [Pithos](https://github.com/exoscale/pithos) packaged for deployment
in a [Gravity](https://github.com/gravitational/gravity) cluster.

## Provides

Once deployed or installed, this app will provide:

 * [Pithos](https://github.com/exoscale/pithos), an S3 compatible, Cassandra based, object store

Requires client compatibility with V2 signatures, and ability to specify custom endpoints.

## Building

### Building images
Execute `all` make target(could be omiited as it is default target).
```sh
$ make
```

### Building self-sufficient gravity image(a.k.a `Cluster Image`)
Download gravity and tele binaries
```
make download-binaries
```

Dowload and unpack dependent application packages into state directory(`./state` by default)
```
make install-dependent-packages
```

Build cluster image
```
export PATH=$(pwd)/bin:$PATH
make build-app
```

*Optional*: Build cluster image with intermediate runtime
```
export PATH=$(pwd)/bin:$PATH
make build-app INTERMEDIATE_RUNTIME_VERSION=6.1.47
```

## Prerequisites

* docker >=  1.8
* golang >= 1.13
* GNU make
* kubectl >= 1.15
