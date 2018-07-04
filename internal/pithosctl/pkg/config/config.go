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

package config

import "github.com/gravitational/trace"

// Pithos describes pithos application configuration
type Pithos struct {
	// KubeConfig defines path to Kubernetes config file
	KubeConfig string
	// ReplicationFactor defines replication factor for cassandra keyspace
	ReplicationFactor int
	// Namespace defines kubernetes namespace for pithos application components
	Namespace string
	// NodeLabel defines the filter for kubernetes nodes where cassandra should start
	NodeLabel string
	// Keys defines list of S3 keys which should be created during bootstrap
	Keys []AccessKey
}

// AccessKey defines pithos S3 access key
type AccessKey struct {
	Key    string
	Secret string
	// Master parameter for key will allow access to all buckets
	Master bool
	Tenant string
}

// Check checks configuration parameters
func (p *Pithos) Check() error {
	var errors []error
	if p.ReplicationFactor < 1 {
		errors = append(errors, trace.BadParameter("replication factor should be equal or great than 1"))
	}
	if p.Namespace == "" {
		errors = append(errors, trace.BadParameter("namespace is required"))
	}
	if p.NodeLabel == "" {
		errors = append(errors, trace.BadParameter("label is required"))
	}

	return trace.NewAggregate(errors...)
}
