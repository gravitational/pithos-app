package main

import (
	"strings"
	"time"

	log "github.com/Sirupsen/logrus"
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
)

func bootCluster() error {
	err := createPithosConfig()
	if err != nil {
		return trace.Wrap(err)
	}

	log.Infof("creating cassandra services + statefulset")
	out, err := rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/cassandra.yaml")
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
