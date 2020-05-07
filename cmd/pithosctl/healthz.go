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
	"net/http"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/defaults"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/pithos"

	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var (
	healthzCmd = &cobra.Command{
		Use:          "healthz",
		Short:        "Serve pithos health checks",
		SilenceUsage: true,
		RunE:         healthz,
	}
	accessKey       string
	secretAccessKey string
	endpoint        string
	bucket          string
	pithosHealthz   *pithos.Healthz
)

func init() {
	pithosctlCmd.AddCommand(healthzCmd)
	healthzCmd.PersistentFlags().StringVar(&accessKey, "access-key", "", "S3 access key")
	healthzCmd.PersistentFlags().StringVar(&secretAccessKey, "secret-access-key", "", "S3 secret key")
	healthzCmd.PersistentFlags().StringVar(&endpoint, "endpoint", defaults.HealthzEndpoint, "S3 endpoint address")
	healthzCmd.PersistentFlags().StringVar(&bucket, "bucket", defaults.HealthzBucket, "S3 bucket name")

	if err := bindFlagEnv(healthzCmd.PersistentFlags()); err != nil {
		log.WithError(err).Error("Failed to bind environment variables to flags.")
	}
}

func healthz(ccmd *cobra.Command, args []string) error {
	config := &pithos.HealthzConfig{
		AccessKey:       accessKey,
		SecretAccessKey: secretAccessKey,
		Endpoint:        endpoint,
	}

	var err error
	pithosHealthz, err = pithos.NewHealthz(*config, bucket)
	if err != nil {
		return trace.Wrap(err)
	}

	if err := pithosHealthz.Prepare(); err != nil {
		return trace.Wrap(err)
	}

	log.WithField("endpoint", endpoint).Info("Start server.")
	handler := http.NewServeMux()
	server := &http.Server{Addr: ":8081", Handler: handler}

	handler.HandleFunc("/healthz", healthzHandler)

	errChan := make(chan error, 1)
	go func() {
		err := server.ListenAndServe()
		if err == http.ErrServerClosed {
			err = nil
		}
		errChan <- err
	}()

	select {
	case err := <-errChan:
		return err
	case <-ctx.Done():
		return shutdown(server)
	}
}

func healthzHandler(w http.ResponseWriter, r *http.Request) {
	if err := pithosHealthz.GetObject(); err != nil {
		log.Error(err)
		w.WriteHeader(http.StatusServiceUnavailable)
		return
	}

	w.WriteHeader(http.StatusOK)
}
