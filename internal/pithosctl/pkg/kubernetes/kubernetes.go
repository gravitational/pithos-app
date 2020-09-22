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

package kubernetes

import (
	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

// Client is the Kubernetes API client
type Client struct {
	*kubernetes.Clientset
	restConfig *rest.Config
}

// NewClient returns a new clientset for Kubernetes APIs
func NewClient(kubeConfig string) (*Client, error) {
	config, err := GetClientConfig(kubeConfig)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	return &Client{
		Clientset:  clientset,
		restConfig: config,
	}, nil
}

// Pods returns pithos pods matching the specified label
func (c *Client) Pods(selector, namespace string) ([]v1.Pod, error) {
	labelSelector, err := labels.Parse(selector)
	if err != nil {
		return nil, trace.Wrap(err, "the provided label selector %s is not valid", selector)
	}

	podList, err := c.CoreV1().Pods(namespace).List(metav1.ListOptions{LabelSelector: labelSelector.String()})
	if err != nil {
		return nil, rigging.ConvertError(err)
	}

	if len(podList.Items) == 0 {
		return nil, trace.NotFound("no pods found matching the specified selector %s", labelSelector)
	}

	return podList.Items, nil
}

// PithosConfigMap return configmap containing pithos configuration
func (c *Client) PithosSecret(secretName, namespace string) (*v1.Secret, error) {
	secret, err := c.CoreV1().Secrets(namespace).Get(secretName, metav1.GetOptions{})
	if err != nil {
		return nil, rigging.ConvertError(err)
	}

	return secret, nil
}

// GetClientConfig returns client configuration,
// if KubeConfig is not specified, in-cluster configuration is assumed
func GetClientConfig(kubeConfig string) (*rest.Config, error) {
	if kubeConfig != "" {
		return clientcmd.BuildConfigFromFlags("", kubeConfig)
	}
	return rest.InClusterConfig()

}
