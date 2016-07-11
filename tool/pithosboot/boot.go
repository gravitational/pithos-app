package main

import (
	"bytes"
	"io/ioutil"
	"os"
	"path/filepath"
	"text/template"

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

	err = createPithosConfig()
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

type AccessKeyList struct {
	Keys []AccessKey
}

type AccessKey struct {
	Key    string
	Master bool
	Tenant string
	Secret string
}

func createPithosConfig() error {
	log.Infof("creating ConfigMap/pithos-cfg")

	keys := AccessKeyList{
		Keys: []AccessKey{
			AccessKey{
				Key:    "C28D2EE399E1A4CBC295D677",
				Master: true,
				Tenant: "ops@gravitational.io",
				Secret: "4C22FFEA7A6C9F3AAFD223B30628F0EA1D50318C2F6F173F",
			},
			AccessKey{
				Key:    "CE9ED4F33A988422E7FA5DF1",
				Master: false,
				Tenant: "pithos",
				Secret: "1D8943238E6BC13E9030DF912FD047C4176C7758778E0E90",
			},
		},
	}

	templateFile := "/var/lib/gravity/resources/pithos-cfg/config.yaml.template"

	configTemplate, err := template.ParseFiles(templateFile)
	if err != nil {
		return trace.Wrap(err)
	}

	dir, err := ioutil.TempDir("", "pithosboot")
	if err != nil {
		return trace.Wrap(err)
	}

	defer os.RemoveAll(dir)

	buffer := &bytes.Buffer{}
	err = configTemplate.Execute(buffer, keys)
	if err != nil {
		return trace.Wrap(err)
	}

	config := filepath.Join(dir, "config.yaml")
	if err := ioutil.WriteFile(config, buffer.Bytes(), 0666); err != nil {
		return trace.Wrap(err)
	}

	out, err := rigging.CreateConfigMap("pithos-cfg", dir)
	if err != nil {
		log.Errorf("%s", out)
		return trace.Wrap(err)
	}

	return nil
}
