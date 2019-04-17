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

package cluster

import (
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cassandra"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/kubernetes"

	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
	"k8s.io/api/core/v1"
)

// GetStatus returns the status of cassandra cluster
func GetStatus(config Config) (*Status, error) {
	client, err := kubernetes.NewClient(config.KubeConfig)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	podsList, err := getPods(client, config)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	var (
		podsStatus              []kubernetes.PodStatus
		isCassandraStatusParsed bool
		nodesStatus             map[string]*cassandra.Status
	)

	for _, pod := range podsList {
		podIP := pod.Status.PodIP
		if podIP == "" {
			podIP = "<none>"
		}

		podState, containers, readyContainers := kubernetes.DeterminePodStatus(pod)
		podStatus := kubernetes.PodStatus{
			Name:              pod.ObjectMeta.Name,
			HostIP:            pod.Spec.NodeName,
			PodIP:             podIP,
			Status:            podState,
			TotalContainers:   containers,
			ReadyContainers:   readyContainers,
			CreationTimestamp: pod.Status.StartTime,
		}
		podsStatus = append(podsStatus, podStatus)

		if !isCassandraStatusParsed {
			nodesStatus, err = getCassandraStatus(client, pod)
			if err != nil {
				return nil, trace.Wrap(err)
			}
			isCassandraStatusParsed = true
		}
	}

	return &Status{
		PodsStatus:  podsStatus,
		NodesStatus: nodesStatus,
	}, nil
}

// Status represents status of cassandra cluster
type Status struct {
	// PodsStatus is a list of statuses for cassandra pods
	PodsStatus []kubernetes.PodStatus
	// NodesStatus is a list of cassandra node statuses
	NodesStatus map[string]*cassandra.Status
}

// getPods returns list of keeper and sentinel pods
func getPods(client *kubernetes.Client, config Config) ([]v1.Pod, error) {

	pods, err := client.Pods(config.CassandraPodSelector, config.Namespace)
	if err != nil {
		return nil, rigging.ConvertError(err)
	}

	return pods, nil
}

func getCassandraStatus(client *kubernetes.Client, pod v1.Pod) (nodesStatus map[string]*cassandra.Status, err error) {
	var statusCommand = []string{"nodetool", "status"}
	statusOut, err := client.Exec(pod, statusCommand...)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	nodesStatus, err = cassandra.GetStatus(statusOut)
	if err != nil {
		log.Errorf("Output of nodetool status command: \n%v", statusOut)
		return nil, trace.Wrap(err)
	}

	return nodesStatus, nil
}
