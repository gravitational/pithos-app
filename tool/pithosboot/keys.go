package main

import (
	"bytes"
	"crypto/rand"
	"crypto/sha256"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	log "github.com/Sirupsen/logrus"
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
)

type AccessKeyList struct {
	Keys []AccessKey
}

type AccessKey struct {
	Key    string
	Master bool
	Tenant string
	Secret string
}

func generateAccessKey(tenant string, master bool) (*AccessKey, error) {
	ak := &AccessKey{
		Master: master,
		Tenant: tenant,
	}

	var err error
	ak.Key, ak.Secret, err = generateKeyAndSecret()
	if err != nil {
		return ak, trace.Wrap(err)
	}

	return ak, nil
}

func generateKeyAndSecret() (key string, secret string, err error) {
	key, err = randomHex(20)
	if err != nil {
		return key, secret, trace.Wrap(err)
	}
	secret, err = randomHex(40)
	if err != nil {
		return key, secret, trace.Wrap(err)
	}
	return strings.ToUpper(key), strings.ToUpper(secret), nil
}

func randomHex(length int) (string, error) {
	data := make([]byte, 32)
	_, err := rand.Read(data)
	if err != nil {
		return "", trace.Wrap(err)
	}
	return fmt.Sprintf("%x", sha256.Sum256(data))[:length], nil
}

func createPithosConfig() error {
	log.Infof("creating ConfigMap/pithos-cfg")

	keys := AccessKeyList{
		Keys: []AccessKey{},
	}

	masterKey, err := generateAccessKey("ops@gravitational.io", true)
	if err != nil {
		return trace.Wrap(err)
	}
	keys.Keys = append(keys.Keys, *masterKey)

	tenantKey, err := generateAccessKey("pithos", false)
	if err != nil {
		return trace.Wrap(err)
	}
	keys.Keys = append(keys.Keys, *tenantKey)

	templateFile := "/var/lib/gravity/resources/pithos-cfg/config.yaml.template"

	configTemplate, err := template.ParseFiles(templateFile)
	if err != nil {
		return trace.Wrap(err)
	}

	dir, err := ioutil.TempDir("", "pithosboot")
	if err != nil {
		return trace.Wrap(err)
	}

	defer os.RemoveAll(dir)

	buffer := &bytes.Buffer{}
	err = configTemplate.Execute(buffer, keys)
	if err != nil {
		return trace.Wrap(err)
	}

	config := filepath.Join(dir, "config.yaml")
	if err := ioutil.WriteFile(config, buffer.Bytes(), 0666); err != nil {
		return trace.Wrap(err)
	}

	out, err := rigging.CreateConfigMapFromPath("pithos-cfg", dir)
	if err != nil {
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
	if err != nil {
		log.Errorf("%s", string(out))
		return trace.Wrap(err)
	}

	return nil
}
