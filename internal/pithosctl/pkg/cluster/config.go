/*
Copyright (C) 2019 Gravitational, Inc.

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

package cluster

import (
	"encoding/base64"

	"github.com/gravitational/trace"
)

// Config describes pithos application configuration
type Config struct {
	// KubeConfig defines path to kubernetes config file
	KubeConfig string
	// Namespace defines kubernetes namespace for pithos application components
	Namespace string
	// NodeSelector defines the filter for kubernetes nodes where cassandra should start
	NodeSelector string
	// Keys defines list of S3 keys which should be created during bootstrap
	Keys []AccessKey
	// CassandraPodSelector defines labels to select cassandra pods
	CassandraPodSelector string
	// Bootstrap represents bootstrapping configuration for pithos application
	Bootstrap Bootstrap
}

// Check checks configuration parameters
func (p *Config) Check() error {
	var errors []error
	if p.Namespace == "" {
		errors = append(errors, trace.BadParameter("namespace is required"))
	}
	if p.NodeSelector == "" {
		errors = append(errors, trace.BadParameter("label is required"))
	}
	return trace.NewAggregate(errors...)
}

// Bootstrap represents bootstrapping configuration for pithos application
type Bootstrap struct {
	// ReplicationFactor defines replication factor for cassandra keyspace
	ReplicationFactor int
}

// Check checks configuration parameters
func (b *Bootstrap) Check() error {
	if b.ReplicationFactor < 1 {
		return trace.BadParameter("replication factor must be >= 1")
	}
	return nil
}

// AccessKey defines pithos S3 access key configuration
type AccessKey struct {
	// Key defines S3 access key
	Key KeyString
	// Secret defines S3 secret access key
	Secret KeyString
	// Master parameter for key will allow access to all buckets
	Master bool
	// Tenant defines S3 user name
	Tenant string
}

// KeyString is a string
type KeyString string

// EncodeBase64 encodes source string to base64 format
func (k *KeyString) EncodeBase64() string {
	return base64.StdEncoding.EncodeToString([]byte(*k))
}

// String is a string representation of KeyString type
func (k *KeyString) String() string {
	return string(*k)
}
