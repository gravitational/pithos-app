package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/config"

	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var (
	pithosBootCfg config.Pithos
	ctx           context.Context

	pithosctlCmd = &cobra.Command{
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

	var cancel context.CancelFunc
	ctx, cancel = context.WithCancel(context.TODO())
	go func() {
		exitSignals := make(chan os.Signal, 1)
		signal.Notify(exitSignals, syscall.SIGTERM, syscall.SIGINT, syscall.SIGQUIT)

		select {
		case sig := <-exitSignals:
			log.Infof("Caught signal: %v.", sig)
			cancel()
		}
	}()
}
