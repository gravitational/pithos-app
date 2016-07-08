package main

import (
	"fmt"
	"os/exec"

	log "github.com/Sirupsen/logrus"
	"github.com/gravitational/trace"
)

func kubeCommand(args ...string) *exec.Cmd {
	return exec.Command("/usr/local/bin/kubectl", args...)
}

func bootCluster() error {
	err := createConfigMap("cassandra-cfg")
	if err != nil {
		return trace.Wrap(err)
	}

	err = createConfigMap("pithos-cfg")
	if err != nil {
		return trace.Wrap(err)
	}

	err = createResources()
	if err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func createConfigMap(name string) error {
	log.Infof("creating ConfigMap/%s", name)
	path := fmt.Sprintf("/var/lib/gravity/resources/%s", name)
	cmd := kubeCommand("create", "configmap", name, "--from-file="+path)
	out, err := cmd.CombinedOutput()
	log.Infof("cmd output: %s", string(out))
	if err != nil {
		return trace.Wrap(err)
	}
	return nil
}

func createResources() error {
	log.Infof("creating pithos resources")
	path := "/var/lib/gravity/resources/pithos.yaml"
	cmd := kubeCommand("create", "-f", path)
	out, err := cmd.CombinedOutput()
	log.Infof("cmd output: %s", string(out))
	if err != nil {
		return trace.Wrap(err)
	}
	return nil
}
