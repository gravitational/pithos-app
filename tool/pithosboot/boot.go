package main

import (
	log "github.com/Sirupsen/logrus"
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
)

func bootCluster() error {
	log.Infof("creating ConfigMap/cassandra-cfg")
	out, err := rigging.CreateConfigMap("cassandra-cfg", "/var/lib/gravity/resources/cassandra-cfg")
	if err != nil {
		log.Error(out)
		return trace.Wrap(err)
	}

	log.Infof("creating ConfigMap/pithos-cfg")
	out, err = rigging.CreateConfigMap("pithos-cfg", "/var/lib/gravity/resources/pithos-cfg")
	if err != nil {
		log.Error(out)
		return trace.Wrap(err)
	}

	log.Infof("creating pithos services + daemonset")
	out, err = rigging.CreateFromFile("/var/lib/gravity/resources/pithos.yaml")
	log.Info(out)
	if err != nil {
		return trace.Wrap(err)
	}

	return nil
}
