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

package defaults

const (
	// Namespace defines Kubernetes namespace for pithos application
	Namespace = "default"
	// CassandraPodSelector defines label selector to select cassandra pods
	CassandraPodSelector = "app=pithos,component=cassandra"
	// PithosNodeSelector defines label selector to select nodes for pithos application
	PithosNodeSelector = "pithos-role=node"
	// Threshold is minimum bytes to consider load between nodes unevenly distributed
	Threshold int64 = 1073741824 // 1GiB
	// HealthzBucket is the name of the S3 bucket used for health checks
	HealthzBucket = "healthz"
	// HealthzEndpoint is the address of pithos server used for health checks
	HealthzEndpoint = "localhost:18080"
)
