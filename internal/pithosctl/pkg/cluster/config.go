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

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/kubernetes"

	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
)

// Config describes pithos application configuration
type Config struct {
	// KubeClient defines kubernetes client
	KubeClient *kubernetes.Client
	// Namespace defines kubernetes namespace for pithos application components
	Namespace string
	// NodeSelector defines the filter for kubernetes nodes where cassandra should start
	NodeSelector string
	// CassandraPodSelector defines labels to select cassandra pods
	CassandraPodSelector string
	// PithosSecret defines secret name storing S3 keys
	PithosSecret string
	// ReplicationFactor defines replication factor for cassandra keyspace
	ReplicationFactor int
	// Keystore represents configuration for S3 keys storage
	Keystore Keystore `yaml:"keystore"`
}

// Keystore represents configuration for S3 keys storage
type Keystore struct {
	Keys map[KeyString]AccessKey `yaml:"keys"`
}

// CheckAndSetDefaults checks configuration parameters and set defaults
func (p *Config) CheckAndSetDefaults() error {
	var errors []error
	if p.KubeClient == nil {
		// explicitly return early here because having kubernetes client is crucial
		return trace.BadParameter("kubernetes client is not initialized")

	}
	if p.Namespace == "" {
		errors = append(errors, trace.BadParameter("namespace is required"))
	}
	if p.NodeSelector == "" {
		errors = append(errors, trace.BadParameter("nodes label selector is required"))
	}

	replicationFactor, err := p.determineReplicationFactor()
	if err != nil {
		errors = append(errors, trace.Wrap(err, "can not determine replication factor"))
	} else if replicationFactor < 1 {
		errors = append(errors, trace.BadParameter("replication factor must be greater than 0; nodes label selector is misconfigured"))
	}
	p.ReplicationFactor = replicationFactor

	return trace.NewAggregate(errors...)
}

// AccessKey defines S3 key configuration
type AccessKey struct {
	// Secret defines S3 secret access key
	Secret KeyString `yaml:"secret"`
	// Master parameter for key will allow access to all buckets
	Master bool `yaml:"master"`
	// Tenant defines S3 user name
	Tenant string `yaml:"tenant"`
}

// KeyString is helper type for converting string into base64-encoded format
type KeyString string

// EncodeBase64 encodes source string to base64 format
func (k KeyString) EncodeBase64() string {
	return base64.StdEncoding.EncodeToString([]byte(k))
}

// String is a string representation of KeyString type
func (k KeyString) String() string {
	return string(k)
}

func (c *Config) determineReplicationFactor() (int, error) {
	nodes, err := c.KubeClient.NodesMatchingLabel(c.NodeSelector)
	if err != nil {
		return 0, trace.Wrap(err)
	}

	replicationFactor := 1
	if len(nodes.Items) >= 3 {
		replicationFactor = 3
	}

	log.Debugf("Replication factor: %v.", replicationFactor)
	return replicationFactor, nil
}
