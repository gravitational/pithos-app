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

package healthz

import "github.com/gravitational/trace"

// Config defines configuration of healthz endpoint
type Config struct {
	// AccessKey defines S3 access key
	AccessKey string
	// SecretAccessKey defines S3 secret access key
	SecretAccessKey string
	// Endpoint defines S3 endpoint address connects to
	Endpoint string
	// Bucket defines bucket name
	Bucket string
}

// Check checks configuration parameters
func (c *Config) Check() error {
	var errors []error
	if c.AccessKey == "" {
		errors = append(errors, trace.BadParameter("access-key-id is required"))
	}
	if c.SecretAccessKey == "" {
		errors = append(errors, trace.BadParameter("secret-access-key is required"))
	}
	if c.Bucket == "" {
		errors = append(errors, trace.BadParameter("bucket is required"))
	}
	if c.Endpoint == "" {
		errors = append(errors, trace.BadParameter("endpoint address is required"))
	}
	return trace.NewAggregate(errors...)
}
