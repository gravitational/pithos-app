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
	"crypto/rand"
	"crypto/sha256"
	"fmt"
	"strings"

	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cluster"

	"github.com/gravitational/trace"
)

const (
	keyLength       = 40
	secretKeyLength = 20
)

func generateAccessKey(tenant string, master bool) (keyName cluster.KeyString, key *cluster.AccessKey, err error) {
	accessKey := &cluster.AccessKey{
		Master: master,
		Tenant: tenant,
	}

	keyName, accessKey.Secret, err = generateKeyAndSecret()
	if err != nil {
		return "", nil, trace.Wrap(err)
	}

	return keyName, accessKey, nil
}

func generateKeyAndSecret() (key cluster.KeyString, secret cluster.KeyString, err error) {
	key, err = randomHex(keyLength)
	if err != nil {
		return "", "", trace.Wrap(err)
	}
	secret, err = randomHex(secretKeyLength)
	if err != nil {
		return "", "", trace.Wrap(err)
	}
	return cluster.KeyString(strings.ToUpper(key.String())), cluster.KeyString(strings.ToUpper(secret.String())), nil
}

func randomHex(length int) (cluster.KeyString, error) {
	const maxLength = 32 << 1
	if length > maxLength {
		length = maxLength
	}
	data := make([]byte, 32)
	_, err := rand.Read(data)
	if err != nil {
		return "", trace.Wrap(err)
	}
	return cluster.KeyString(fmt.Sprintf("%x", sha256.Sum256(data))[:length]), nil
}
