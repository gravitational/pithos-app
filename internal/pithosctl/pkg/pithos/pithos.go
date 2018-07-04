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
	"bytes"
	"html/template"
	"strings"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/config"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/kubernetes"
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"

	log "github.com/sirupsen/logrus"
)

const (
	templateFile  = "/var/lib/gravity/resources/pithos-cfg/config.yaml.template"
	masterTenant  = "ops@gravitational.io"
	regularTenant = "pithos"
	configMapName = "pithos-cfg"
)

// CreateConfig generates configuration file for pithos application
func CreateConfig(pithosConfig config.Pithos) error {
	log.Infoln("Creating pithos-cfg configmap.")

	masterKey, err := generateAccessKey(masterTenant, true)
	if err != nil {
		return trace.Wrap(err)
	}
	pithosConfig.Keys = append(pithosConfig.Keys, *masterKey)

	tenantKey, err := generateAccessKey(regularTenant, false)
	if err != nil {
		return trace.Wrap(err)
	}
	pithosConfig.Keys = append(pithosConfig.Keys, *tenantKey)

	configTemplate, err := template.ParseFiles(templateFile)
	if err != nil {
		return trace.Wrap(err)
	}

	buffer := &bytes.Buffer{}
	err = configTemplate.Execute(buffer, pithosConfig)
	if err != nil {
		return trace.Wrap(err)
	}

	configMap, err := rigging.ParseConfigMap(bytes.NewReader(buffer.Bytes()))
	if err != nil {
		return trace.Wrap(err)
	}

	client, err := kubernetes.NewClient(pithosConfig.KubeConfig)
	if err != nil {
		return trace.Wrap(err)
	}

	out, err := rigging.GenerateConfigMap(configMapName, pithosConfig.Namespace)
	if err != nil && !strings.Contains(string(out), "already exists") {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	keyMap := map[string]string{
		"master.key":    masterKey.Key,
		"master.secret": masterKey.Secret,
		"tenant.key":    tenantKey.Key,
		"tenant.secret": tenantKey.Secret,
	}

	out, err = rigging.CreateSecretFromMap("pithos-keys", keyMap)
	if err != nil && !strings.Contains(string(out), "already exists") {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	return nil
}
