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

package pithos

import (
	"bufio"
	"bytes"
	"context"
	"os"
	"text/template"
	"time"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cluster"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/kubernetes"

	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"k8s.io/api/core/v1"
)

const (
	templateFile      = "/var/lib/gravity/resources/pithos-cfg/config.yaml.template"
	initJobFile       = "/var/lib/gravity/resources/pithos-initialize.yaml"
	masterTenantName  = "ops@gravitational.io"
	regularTenantName = "pithos"
	configMapName     = "pithos-cfg"
	retryAttempts     = 60
	retryPeriod       = 5 * time.Second
)

// Control defines configuration for operations
type Control struct {
	cfg    cluster.Config
	client kubernetes.Client
}

// NewControl creates new pithos bootstrap controller
func NewControl(pithosConfig cluster.Config) (*Control, error) {
	client, err := kubernetes.NewClient(pithosConfig.KubeConfig)
	if err != nil {
		return nil, trace.Wrap(err)
	}
	return &Control{cfg: pithosConfig, client: *client}, nil
}

// CreateResources creates kubernetes resources for pithos application
func (c *Control) CreateResources(ctx context.Context) error {
	log.Infoln("Creating pithos-cfg configmap.")

	masterKey, err := generateAccessKey(masterTenantName, true)
	if err != nil {
		return trace.Wrap(err)
	}
	c.cfg.Keys = append(c.cfg.Keys, *masterKey)

	tenantKey, err := generateAccessKey(regularTenantName, false)
	if err != nil {
		return trace.Wrap(err)
	}
	c.cfg.Keys = append(c.cfg.Keys, *tenantKey)

	configTemplate, err := template.ParseFiles(templateFile)
	if err != nil {
		return trace.Wrap(err)
	}

	buffer := &bytes.Buffer{}
	if err = configTemplate.Execute(buffer, c.cfg); err != nil {
		return trace.Wrap(err)
	}

	configMap, err := rigging.ParseConfigMap(bytes.NewReader(buffer.Bytes()))
	if err != nil {
		return trace.Wrap(err)
	}

	if err = createConfigMap(ctx, configMap, c.client); err != nil {
		return trace.Wrap(err)
	}

	buffer.Reset()
	if err = secretTemplate.Execute(buffer, c.cfg); err != nil {
		return trace.Wrap(err)
	}

	secret, err := rigging.ParseSecret(bytes.NewReader(buffer.Bytes()))
	if err != nil {
		return trace.Wrap(err)
	}

	if err = createSecret(ctx, secret, c.client); err != nil {
		return trace.Wrap(err)
	}
	return nil
}

// InitCassandraTables creates underlying cassandra tables for object store
func (c *Control) InitCassandraTables(ctx context.Context) error {
	file, err := os.Open(initJobFile)
	if err != nil {
		return trace.ConvertSystemError(err)
	}
	defer file.Close()

	job, err := rigging.ParseJob(bufio.NewReader(file))
	if err != nil {
		return trace.Wrap(err)
	}

	jobConfig := rigging.JobConfig{
		job,
		c.client.Clientset,
	}

	jobControl, err := rigging.NewJobControl(jobConfig)
	if err != nil {
		return trace.Wrap(err)
	}

	if err := jobControl.Upsert(ctx); err != nil {
		return trace.Wrap(err)
	}

	return rigging.PollStatus(ctx, retryAttempts, retryPeriod, jobControl)
}

func createConfigMap(ctx context.Context, configMap *v1.ConfigMap, client kubernetes.Client) error {
	configMapConfig := rigging.ConfigMapConfig{
		ConfigMap: configMap,
		Client:    client.Clientset,
	}
	configMapControl, err := rigging.NewConfigMapControl(configMapConfig)
	if err != nil {
		return trace.Wrap(err)
	}

	if err := configMapControl.Upsert(ctx); err != nil {
		return trace.Wrap(err)
	}
	return nil
}

func createSecret(ctx context.Context, secret *v1.Secret, client kubernetes.Client) error {
	secretConfig := rigging.SecretConfig{
		Secret: secret,
		Client: client.Clientset,
	}
	secretControl, err := rigging.NewSecretControl(secretConfig)
	if err != nil {
		return trace.Wrap(err)
	}

	if err := secretControl.Upsert(ctx); err != nil {
		return trace.Wrap(err)
	}
	return nil
}

var secretTemplate = template.Must(
	template.New("pithos_secret").Parse(`apiVersion: v1
kind: Secret
metadata:
  name: pithos-keys
  namespace: {{.Namespace}}
type: Opaque
data:
{{- range .Keys}}
  {{if .Master}}master.key: {{.Key.EncodeBase64}}
  master.secret: {{.Secret.EncodeBase64}}{{else -}}
  tenant.key: {{.Key.EncodeBase64}}
  tenant.secret: {{.Secret.EncodeBase64}}{{end}}
{{- end}}
`))
