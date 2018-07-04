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
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
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

	pithosBootCfg.ReplicationFactor = replicas
	if err = pithosBootCfg.Check(); err != nil {
		return trace.Wrap(err)
	}

	if err = pithos.CreateConfig(pithosBootCfg); err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func determineReplicationFactor() (int, error) {
	nodes, err := rigging.NodesMatchingLabel(pithosBootCfg.NodeLabel)
	if err != nil {
		return 0, trace.Wrap(err)
	}

	if len(nodes.Items) >= 3 {
		return 3, nil
	}
	return 1, nil
}
