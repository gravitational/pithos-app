package main

import (
	"context"
	"io"
	"os"
	"os/signal"
	"syscall"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cluster"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/defaults"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/kubernetes"

	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	flag "github.com/spf13/pflag"
)

var (
	// kubeConfigPath defines path to kubernetes configuration file
	kubeConfigPath string
	pithosConfig   cluster.Config
	ctx            context.Context
	// verbosity determines verbosity level for output
	verbosity string

	pithosctlCmd = &cobra.Command{
		Use:   "",
		Short: "Utility to manage pithos application",
		PersistentPreRunE: func(ccmd *cobra.Command, args []string) error {
			if err := setUpLogs(os.Stdout, verbosity); err != nil {
				return err
			}
			return nil
		},
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
	cobra.OnInitialize(initKubeClient)

	pithosctlCmd.PersistentFlags().StringVar(&kubeConfigPath, "kubeconfig", "", "Path to Kubernetes configuration file.")
	pithosctlCmd.PersistentFlags().StringVarP(&pithosConfig.Namespace, "namespace", "n", defaults.Namespace, "Kubernetes namespace for pithos application.")
	pithosctlCmd.PersistentFlags().StringVar(&pithosConfig.NodeSelector, "nodeSelector", defaults.PithosNodeSelector, "Label(s) to select nodes for pithos application.")
	pithosctlCmd.PersistentFlags().StringVar(&pithosConfig.CassandraPodSelector, "cassandraPodsSelector",
		defaults.CassandraPodSelector, "Label(s) to select cassandra pods. Format is the same as used in `kubectl --selector`.")
	pithosctlCmd.PersistentFlags().StringVarP(&verbosity, "verbosity", "v", log.InfoLevel.String(), "Log level (debug, info).")

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

func exitWithError(err error) {
	log.Error(trace.DebugReport(err))
	os.Exit(255)
}

func initKubeClient() {
	client, err := kubernetes.NewClient(kubeConfigPath)
	if err != nil {
		exitWithError(err)
	}
	pithosConfig.KubeClient = client
}

// setUpLogs sets the log output and the log level
func setUpLogs(out io.Writer, level string) error {
	log.SetOutput(out)
	lvl, err := log.ParseLevel(level)
	if err != nil {
		return trace.Wrap(err)
	}
	log.SetLevel(lvl)
	return nil
}
