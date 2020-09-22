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
	"context"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cluster"

	"github.com/gravitational/trace"
	v1 "k8s.io/api/core/v1"
)

const (
	masterKeyType = "master"
	tenantKeyType = "tenant"
)

// Update performs update of pithos application
func Update(ctx context.Context, config *cluster.Config) error {
	pithosSecret, err := config.KubeClient.PithosSecret(config.PithosSecret, config.Namespace)
	if err != nil {
		return trace.Wrap(err)
	}

	config.Keystore.Keys = make(map[cluster.KeyString]cluster.AccessKey, 2)
	if err = parseSecret(pithosSecret, config, masterKeyType); err != nil {
		return trace.Wrap(err)
	}
	if err = parseSecret(pithosSecret, config, tenantKeyType); err != nil {
		return trace.Wrap(err)
	}

	if err = createConfigMap(ctx, *config); err != nil {
		return trace.Wrap(err)
	}

	return nil
}

func parseSecret(secret *v1.Secret, config *cluster.Config, keyType string) error {
	keyName := keyType + ".key"
	secretName := keyType + ".secret"
	keyValue, exist := secret.Data[keyName]
	if !exist {
		return trace.Errorf("secret %v does not contain data with the key %v", config.PithosSecret, keyName)
	}
	secretValue, exist := secret.Data[secretName]
	if !exist {
		return trace.Errorf("secret %v does not contain data with the key %v", config.PithosSecret, secretName)
	}

	accessKey := cluster.AccessKey{
		Master: false,
		Tenant: regularTenantName,
		Secret: cluster.KeyString(secretValue),
	}

	if keyType == masterKeyType {
		accessKey.Master = true
		accessKey.Tenant = masterTenantName
	}
	config.Keystore.Keys[cluster.KeyString(keyValue)] = accessKey

	return nil
}
