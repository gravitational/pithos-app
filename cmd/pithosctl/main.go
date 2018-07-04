package main

import (
	"os"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/config"

	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var (
	pithosBootCfg config.Pithos
	pithosctlCmd  = &cobra.Command{
		Use:   "",
		Short: "Utility to bootstrap pithos application",
		Run: func(ccmd *cobra.Command, args []string) {
			ccmd.HelpFunc()(ccmd, args)
		},
	}
)

const (
	namespace = "default"
	nodeLabel = "pithos-role=node"
)

func main() {
	if err := pithosctlCmd.Execute(); err != nil {
		log.Error(trace.DebugReport(err))
		os.Exit(255)
	}
}

func init() {
	pithosctlCmd.PersistentFlags().StringVarP(&pithosBootCfg.Namespace, "namespace", "n", namespace, "Kubernetes namespace for pithos application")
	pithosctlCmd.PersistentFlags().StringVar(&pithosBootCfg.NodeLabel, "label", nodeLabel, "Label to select nodes for pithos")
}
