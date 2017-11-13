// Copyright 2017 Gravitational, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bytes"
	"flag"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gravitational/trace"
	minio "github.com/minio/minio-go"
	log "github.com/sirupsen/logrus"
)

const (
	defaultEndpoint       = "localhost:18080"
	defaultBucket         = "liveness-check"
	defaultBucketLocation = "G1"
	defaultPrefix         = "liveness"
)

// Config for access to S3 storage
type s3Config struct {
	bucket string
	client *minio.Client
}

func main() {
	s3AccessKeyID := flag.String("access-key", "", "S3 access key")
	s3SecretAccessKey := flag.String("secret-key", "", "S3 secret key")
	s3Endpoint := flag.String("endpoint", defaultEndpoint, "S3 endpoint address")
	s3Bucket := flag.String("bucket", defaultBucket, "S3 Bucket name")

	flag.Parse()
	log.Infof("starting healthz endpoint")

	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		if err := livenessProbe(*s3Endpoint, *s3Bucket, *s3AccessKeyID, *s3SecretAccessKey); err != nil {
			log.Error(err)
			w.WriteHeader(http.StatusInternalServerError)
		}
		w.WriteHeader(http.StatusOK)
	})
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func livenessProbe(s3Endpoint, s3Bucket, s3AccessKeyID, s3SecretAccessKey string) error {
	var err error
	var client *minio.Client

	if s3AccessKeyID == "" && s3SecretAccessKey == "" {
		log.Fatal("s3AccessKey and s3SecretAccessKey is undefined")
		os.Exit(1)
	}

	client, err = initClient(s3Endpoint, s3AccessKeyID, s3SecretAccessKey)
	if err != nil {
		return trace.Wrap(err)
	}

	s3Config := &s3Config{
		bucket: s3Bucket,
		client: client,
	}

	log.Info("checking creating of S3 bucket")
	if err := s3Config.createBucket(); err != nil {
		return trace.Wrap(err)
	}

	log.Info("checking creating of object")
	if err := s3Config.createObject(); err != nil {
		return trace.Wrap(err)
	}

	log.Info("teardown bucket and objects")
	if err := s3Config.deleteBucket(); err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func initClient(endpoint, accessKeyID, secretAccessKey string) (*minio.Client, error) {
	client, err := minio.NewV2(endpoint, accessKeyID, secretAccessKey, false)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	return client, nil
}

func (s3c *s3Config) createBucket() error {
	found, err := s3c.client.BucketExists(s3c.bucket)
	if err != nil {
		return trace.Wrap(err)
	}

	if !found {
		err = s3c.client.MakeBucket(s3c.bucket, defaultBucketLocation)
		if err != nil {
			return trace.Wrap(err)
		}
	}
	return nil
}

func (s3c *s3Config) createObject() error {
	var content = []byte("test")
	reader := bytes.NewReader(content)

	t := time.Now()
	objectName := fmt.Sprintf("%s-%v", defaultPrefix, t.Unix())
	_, err := s3c.client.PutObject(s3c.bucket, objectName, reader, "application/octet-stream")
	if err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func (s3c *s3Config) deleteBucket() error {
	// Create a done channel to control 'ListObjectsV2' go routine.
	doneCh := make(chan struct{})

	// Indicate to our routine to exit cleanly upon return.
	defer close(doneCh)

	isRecursive := false
	objectCh := s3c.client.ListObjectsV2(s3c.bucket, defaultPrefix, isRecursive, doneCh)
	for object := range objectCh {
		if object.Err != nil {
			return trace.Wrap(object.Err)
		}

		if err := s3c.client.RemoveObject(s3c.bucket, object.Key); err != nil {
			return trace.Wrap(err)
		}
	}

	if err := s3c.client.RemoveBucket(s3c.bucket); err != nil {
		return trace.Wrap(err)
	}
	return nil
}
