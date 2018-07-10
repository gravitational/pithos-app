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
	"bytes"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/healthz"

	"github.com/gravitational/trace"
	minio "github.com/minio/minio-go"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

const (
	defaultEndpoint       = "localhost:18080"
	defaultBucket         = "liveness-check"
	defaultBucketLocation = "G1"
	defaultPrefix         = "liveness"
)

var (
	healthzConfig healthz.Config

	healthzCmd = &cobra.Command{
		Use:          "healthz",
		Short:        "Healthz endpoint for pithos application",
		SilenceUsage: true,
		RunE:         serveHealthz,
	}
)

// s3Config describes configuration to access an s3 bucket
type s3Config struct {
	bucket string
	client *minio.Client
}

func init() {
	pithosctlCmd.AddCommand(healthzCmd)
	healthzCmd.Flags().StringVar(&healthzConfig.AccessKey, "access-key-id", "", "S3 access key")
	healthzCmd.Flags().StringVar(&healthzConfig.SecretAccessKey, "secret-access-key", "", "S3 secret key")
	healthzCmd.Flags().StringVar(&healthzConfig.Endpoint, "endpoint", defaultEndpoint, "S3 endpoint address")
	healthzCmd.Flags().StringVar(&healthzConfig.Bucket, "bucket", defaultBucket, "S3 bucket name")
}

func serveHealthz(ccmd *cobra.Command, args []string) error {
	if err := healthzConfig.Check(); err != nil {
		return trace.Wrap(err)
	}

	client, err := initClient(healthzConfig.Endpoint, healthzConfig.AccessKey, healthzConfig.SecretAccessKey)
	if err != nil {
		return trace.Wrap(err, "failed to create s3 client")
	}

	s3Config := &s3Config{
		bucket: healthzConfig.Bucket,
		client: client,
	}

	log.Info("Starting healthz endpoint.")

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		if err := livenessProbe(s3Config); err != nil {
			log.Error(err)
			w.WriteHeader(http.StatusServiceUnavailable)
		} else {
			w.WriteHeader(http.StatusOK)
		}
	})
	return http.ListenAndServe(":8080", nil)
}

func livenessProbe(s3Config *s3Config) error {
	// verify that can create S3 bucket
	if err := s3Config.createBucket(); err != nil {
		return trace.Wrap(err)
	}

	// change object name to be based on time.Now and POD hostname
	now := time.Now()
	hostname, err := os.Hostname()
	if err != nil {
		return trace.Wrap(err)
	}
	objectPrefix := fmt.Sprintf("%s-%s", defaultPrefix, hostname)
	objectName := fmt.Sprintf("%s-%v", objectPrefix, now.Unix())

	// verify that can create S3 object
	if err := s3Config.createObject(objectName); err != nil {
		return trace.Wrap(err)
	}

	// teardown
	if err := s3Config.cleanBucket(objectPrefix); err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func initClient(endpoint, accessKeyID, secretAccessKey string) (*minio.Client, error) {
	insecure := false
	client, err := minio.NewV2(endpoint, accessKeyID, secretAccessKey, insecure)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	return client, nil
}

func (s3c *s3Config) bucketExists() (bool, error) {
	found, err := s3c.client.BucketExists(s3c.bucket)
	if err != nil {
		return false, trace.Wrap(err)
	}
	return found, nil
}

func (s3c *s3Config) createBucket() error {
	bucketFound, err := s3c.bucketExists()
	if err != nil {
		return trace.Wrap(err)
	}

	if !bucketFound {
		err = s3c.client.MakeBucket(s3c.bucket, defaultBucketLocation)
		if err != nil {
			return trace.Wrap(err)
		}
	}
	return nil
}

func (s3c *s3Config) createObject(objectName string) error {
	var content = []byte("test")
	reader := bytes.NewReader(content)

	_, err := s3c.client.PutObject(s3c.bucket, objectName, reader, "application/octet-stream")
	if err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func (s3c *s3Config) cleanBucket(objectPrefix string) error {
	// Create a done channel to control 'ListObjectsV2' goroutine.
	doneCh := make(chan struct{})
	defer close(doneCh)

	recursive := false
	objectCh := s3c.client.ListObjectsV2(s3c.bucket, objectPrefix, recursive, doneCh)
	for object := range objectCh {
		if object.Err != nil {
			return trace.Wrap(object.Err)
		}

		if err := s3c.client.RemoveObject(s3c.bucket, object.Key); err != nil {
			return trace.Wrap(err)
		}
	}

	return nil
}
