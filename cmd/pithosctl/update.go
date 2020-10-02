/*
Copyright (C) 2020 Gravitational, Inc.

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
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/defaults"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/pithos"

	"github.com/gravitational/trace"
	"github.com/spf13/cobra"
)

var updateCmd = &cobra.Command{
	Use:          "update",
	Short:        "Update pithos application components",
	SilenceUsage: true,
	RunE:         updateApp,
}

func init() {
	pithosctlCmd.AddCommand(updateCmd)
	pithosctlCmd.PersistentFlags().StringVar(&pithosConfig.PithosSecret, "secret", defaults.PithosSecret, "Secret name storing S3 keys.")
}

func updateApp(ccmd *cobra.Command, args []string) error {
	if err := pithosConfig.CheckAndSetDefaults(); err != nil {
		return trace.Wrap(err)
	}

	if err := pithos.Update(ctx, &pithosConfig); err != nil {
		return trace.Wrap(err)
	}
	return nil
}
