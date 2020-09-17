package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cluster"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/defaults"

	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	flag "github.com/spf13/pflag"
)

var (
	pithosConfig cluster.Config
	ctx          context.Context

	pithosctlCmd = &cobra.Command{
		Use:   "",
		Short: "Utility to manage pithos application",
		Run: func(ccmd *cobra.Command, args []string) {
			ccmd.HelpFunc()(ccmd, args)
		},
	}

	envs = map[string]string{
		"AWS_ACCESS_KEY_ID":     "access-key",
		"AWS_SECRET_ACCESS_KEY": "secret-access-key",
		"ENDPOINT":              "endpoint",
		"BUCKET":                "bucket",
	}
)

func main() {
	if err := pithosctlCmd.Execute(); err != nil {
		log.Error(trace.DebugReport(err))
		os.Exit(255)
	}
}

func init() {
	pithosctlCmd.PersistentFlags().StringVarP(&pithosConfig.Namespace, "namespace", "n", defaults.Namespace, "Kubernetes namespace for pithos application.")
	pithosctlCmd.PersistentFlags().StringVar(&pithosConfig.NodeSelector, "nodeSelector", defaults.PithosNodeSelector, "Label(s) to select nodes for pithos application.")
	pithosctlCmd.PersistentFlags().StringVar(&pithosConfig.CassandraPodSelector, "cassandraPodsSelector",
		defaults.CassandraPodSelector, "Label(s) to select cassandra pods. Format is the same as used in `kubectl --selector`.")

	var cancel context.CancelFunc
	ctx, cancel = context.WithCancel(context.TODO())
	go func() {
		exitSignals := make(chan os.Signal, 1)
		signal.Notify(exitSignals, syscall.SIGTERM, syscall.SIGINT, syscall.SIGQUIT)

		sig := <-exitSignals
		log.Infof("Caught signal: %v.", sig)
		cancel()
	}()
}

// bindFlagEnv binds environment variables to command flags
func bindFlagEnv(flagSet *flag.FlagSet) error {
	for env, flag := range envs {
		cmdFlag := flagSet.Lookup(flag)
		if cmdFlag != nil {
			if value := os.Getenv(env); value != "" {
				if err := cmdFlag.Value.Set(value); err != nil {
					return trace.Wrap(err)
				}
			}
		}
	}
	return nil
}

func setReplicationFactor(config *cluster.Config) (err error) {
	nodes, err := rigging.NodesMatchingLabel(pithosConfig.NodeSelector)
	if err != nil {
		return trace.Wrap(err)
	}

	replicationFactor := 1
	if len(nodes.Items) >= 3 {
		replicationFactor = 3
	}

	log.Infof("Replication factor: %v.", replicationFactor)
	config.ReplicationFactor = replicationFactor
	return nil
}
