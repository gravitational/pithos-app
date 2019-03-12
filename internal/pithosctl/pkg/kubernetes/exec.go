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

package kubernetes

import (
	"bytes"
	"strings"

	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"k8s.io/api/core/v1"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/tools/remotecommand"
)

const containerName = "cassandra"

// Exec executes command in pod
func (c *Client) Exec(pod v1.Pod, command ...string) (string, error) {
	log.Debugf("Executing command \"%s\" in pod %s", strings.Join(command, " "), pod.ObjectMeta.Name)

	// iterate through all containers looking for one running cassandra
	targetContainer := -1
	for i, cr := range pod.Spec.Containers {
		if cr.Name == containerName {
			targetContainer = i
			break
		}
	}

	if targetContainer < 0 {
		return "", trace.NotFound("container %s not found in pod %s", containerName, pod.ObjectMeta.Name)
	}

	req := c.Clientset.CoreV1().RESTClient().Post().
		Resource("pods").
		Name(pod.ObjectMeta.Name).
		Namespace(pod.ObjectMeta.Namespace).
		SubResource("exec")

	req.VersionedParams(&v1.PodExecOptions{
		Container: pod.Spec.Containers[targetContainer].Name,
		Command:   command,
		Stdout:    true,
		Stderr:    true,
	}, scheme.ParameterCodec)

	exec, err := remotecommand.NewSPDYExecutor(c.restConfig, "POST", req.URL())
	if err != nil {
		return "", rigging.ConvertError(err)
	}

	var (
		execOut bytes.Buffer
		execErr bytes.Buffer
	)

	err = exec.Stream(remotecommand.StreamOptions{
		Stdout: &execOut,
		Stderr: &execErr,
		Tty:    false,
	})
	if err != nil {
		return "", trace.Wrap(err, "could not execute command \"%s\"", strings.Join(command, " "))
	}
	if execErr.Len() > 0 {
		return "", trace.Errorf("error during execution of command \"%s\", stderr: %v", strings.Join(command, " "), execErr.String())
	}

	return execOut.String(), nil
}
