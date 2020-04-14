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

package pithos

import (
	"bytes"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/defaults"

	"github.com/gravitational/trace"
	minio "github.com/minio/minio-go"
)

const (
	defaultBucketLocation = "G1"
	objectName            = "liveness-probe.txt"
)

// HealthzConfig defines access configuration to pithos server for health checks
type HealthzConfig struct {
	// AccessKey defines pithos S3 access key
	AccessKey string
	// SecretAccessKey defines pithos S3 secret key
	SecretAccessKey string
	// Endpoint defines pithos endpoint address
	Endpoint string
}

// Check checks configuration parameters
func (h *HealthzConfig) CheckAndSetDefaults() error {
	if h == nil {
		return nil
	}

	var errors []error
	if h.AccessKey == "" {
		errors = append(errors, trace.BadParameter("access-key is required"))
	}
	if h.SecretAccessKey == "" {
		errors = append(errors, trace.BadParameter("secret-access-key is required"))
	}
	if h.Endpoint == "" {
		h.Endpoint = defaults.HealthzEndpoint
	}
	return trace.NewAggregate(errors...)
}

// Healthz defines configuration for pithos server health checks
type Healthz struct {
	// Bucket defines S3 bucket used for health checks
	Bucket string
	// Client represent minio.io S3 client
	Client *minio.Client
}

func NewHealthz(config HealthzConfig, bucket string) (*Healthz, error) {
	if bucket == "" {
		bucket = defaults.HealthzBucket
	}

	client, err := initClient(config)
	if err != nil {
		return nil, trace.Wrap(err, "failed to create s3 client")
	}

	return &Healthz{
		Bucket: bucket,
		Client: client,
	}, nil
}

func initClient(config HealthzConfig) (*minio.Client, error) {
	insecure := false
	client, err := minio.NewV2(config.Endpoint, config.AccessKey, config.SecretAccessKey, insecure)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	return client, nil
}

// Prepare creates bucket and object if they do not exist
func (h *Healthz) Prepare() error {
	if err := h.createBucketIfNotExist(); err != nil {
		return trace.Wrap(err)
	}

	if err := h.createObject(); err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func (h *Healthz) bucketExists() (bool, error) {
	found, err := h.Client.BucketExists(h.Bucket)
	if err != nil {
		return false, trace.Wrap(err)
	}
	return found, nil
}

func (h *Healthz) createBucketIfNotExist() error {
	bucketFound, err := h.bucketExists()
	if err != nil {
		return trace.Wrap(err)
	}

	if !bucketFound {
		err = h.Client.MakeBucket(h.Bucket, defaultBucketLocation)
		if err != nil {
			return trace.Wrap(err)
		}
	}
	return nil
}

func (h *Healthz) createObject() error {
	var content = []byte("test")
	reader := bytes.NewReader(content)

	_, err := h.Client.PutObject(h.Bucket, objectName, reader, reader.Size(), minio.PutObjectOptions{ContentType: "application/octet-stream"})
	if err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func (h *Healthz) GetObject() error {
	_, err := h.Client.GetObject(h.Bucket, objectName, minio.GetObjectOptions{})
	return trace.Wrap(err)
}
