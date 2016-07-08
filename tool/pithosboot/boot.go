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
		log.Errorf("%s", out)
		return trace.Wrap(err)
	}

	log.Infof("creating ConfigMap/pithos-cfg")
	out, err = rigging.CreateConfigMap("pithos-cfg", "/var/lib/gravity/resources/pithos-cfg")
	if err != nil {
		log.Errorf("%s", out)
		return trace.Wrap(err)
	}

	log.Infof("creating pithos services + daemonset")
	out, err = rigging.CreateFromFile("/var/lib/gravity/resources/pithos.yaml")
	log.Info(out)
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

	return nil
}
