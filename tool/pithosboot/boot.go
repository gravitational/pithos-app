package main

import (
	"time"

	log "github.com/Sirupsen/logrus"
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
)

func bootCluster() error {
	log.Infof("creating ConfigMap/cassandra-cfg")
	out, err := rigging.CreateConfigMapFromPath("cassandra-cfg", "/var/lib/gravity/resources/cassandra-cfg")
	if err != nil {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	err = createPithosConfig()
	if err != nil {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	log.Infof("creating pithos services + daemonset")
	out, err = rigging.CreateFromFile("/var/lib/gravity/resources/pithos.yaml")
	if err != nil {
		return trace.Wrap(err)
	}

	nodes, err := rigging.NodesMatchingLabel("role=node")
	if err != nil {
		return trace.Wrap(err)
	}

	label := "pithos-role=node"
	for _, node := range nodes.Items {
		log.Infof("labeling node: %s with: %s", node.Metadata.Name, label)
		_, err = rigging.LabelNode(node.Metadata.Name, label)
		if err != nil {
			return trace.Wrap(err)
		}
	}

	log.Infof("initializing pithos")
	out, err = rigging.CreateFromFile("/var/lib/gravity/resources/pithos-initialize.yaml")
	if err != nil {
		return trace.Wrap(err)
	}

	log.Infof("waiting for pithos to be initialized")
	err = rigging.WaitForJobSuccess("pithos-initialize", 10*time.Minute)
	if err != nil {
		return trace.Wrap(err)
	}

	log.Infof("creating pithos replication controller")
	out, err = rigging.CreateFromFile("/var/lib/gravity/resources/pithos-rc.yaml")
	if err != nil {
		return trace.Wrap(err)
	}

	return nil
}
