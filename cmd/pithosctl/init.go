/*
Copyright (C) 2018 Gravitational, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"strings"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/pithos"

	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:          "init",
	Short:        "Initialize pithos application",
	SilenceUsage: true,
	RunE:         initApp,
}

func init() {
	pithosctlCmd.AddCommand(initCmd)
}

func initApp(ccmd *cobra.Command, args []string) error {
	replicas, err := determineReplicationFactor()
	if err != nil {
		return trace.Wrap(err)
	}

	log.Infof("Replication factor: %v.", replicas)
	pithosConfig.Bootstrap.ReplicationFactor = replicas
	if err = pithosConfig.Check(); err != nil {
		return trace.Wrap(err)
	}
	if err = pithosConfig.Bootstrap.Check(); err != nil {
		return trace.Wrap(err)
	}

	log.Info("Creating pithos configmap and secret.")
	pithosControl, err := pithos.NewControl(pithosConfig)
	if err != nil {
		return trace.Wrap(err)
	}

	if err = pithosControl.CreateResources(ctx); err != nil {
		return trace.Wrap(err)
	}

	log.Info("Creating cassandra services/configmaps + statefulset.")
	out, err := rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/cassandra.yaml")
	if err != nil && !isAlreadyExistsError(out) {
		return trace.Wrap(err)
	}

	log.Info("Initializing cassandra tables.")
	if err = pithosControl.InitCassandraTables(ctx); err != nil {
		return trace.Wrap(err)
	}

	log.Info("Creating pithos deployment.")
	out, err = rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/pithos.yaml")
	if err != nil && !isAlreadyExistsError(out) {
		return trace.Wrap(err)
	}
	return nil
}

func determineReplicationFactor() (int, error) {
	nodes, err := rigging.NodesMatchingLabel(pithosConfig.NodeSelector)
	if err != nil {
		return 0, trace.Wrap(err)
	}

	if len(nodes.Items) >= 3 {
		return 3, nil
	}
	return 1, nil
}

func isAlreadyExistsError(output []byte) bool {
	return strings.Contains(string(output), "already exists")
}
