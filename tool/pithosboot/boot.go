package main

import (
	"strings"
	"time"

	log "github.com/Sirupsen/logrus"
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
)

func bootCluster() error {
	log.Infof("creating ConfigMap/cassandra-cfg")
	out, err := rigging.CreateConfigMapFromPath("cassandra-cfg", "/var/lib/gravity/resources/cassandra-cfg")
	if err != nil && !strings.Contains(string(out), "already exists") {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	log.Infof("creating ConfigMap/monitoring-cfg")
	out, err = rigging.CreateConfigMapFromPath("monitoring-cfg", "/var/lib/gravity/resources/monitoring-cfg")
	if err != nil && !strings.Contains(string(out), "already exists") {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	err = createPithosConfig()
	if err != nil && !strings.Contains(string(out), "already exists") {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	log.Infof("creating cassandra services + daemonset")
	out, err = rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/cassandra.yaml")
	if err != nil && !strings.Contains(string(out), "already exists") {
		return trace.Wrap(err)
	}

	log.Infof("initializing pithos")
	out, err = rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/pithos-initialize.yaml")

	if err != nil && !strings.Contains(string(out), "already exists") {
		return trace.Wrap(err)
	}

	log.Infof("waiting for pithos to be initialized")
	err = rigging.WaitForJobSuccess("pithos-initialize", 10*time.Minute)
	if err != nil {
		return trace.Wrap(err)
	}

	log.Infof("creating pithos replication controller")
	out, err = rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/pithos.yaml")
	if err != nil && !strings.Contains(string(out), "already exists") {
		return trace.Wrap(err)
	}

	return nil
}
