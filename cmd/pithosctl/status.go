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

package main

import (
	"fmt"
	"io"
	"math"
	"os"
	"text/tabwriter"
	"time"

	"github.com/alecthomas/units"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cassandra"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/cluster"
	"github.com/gravitational/pithos-app/internal/pithosctl/pkg/defaults"

	"github.com/gravitational/trace"
	"github.com/spf13/cobra"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

var (
	statusCmd = &cobra.Command{
		Use:          "status",
		Short:        "HTTP listener exposing cluster status",
		SilenceUsage: true,
		RunE:         status,
	}
	shortOutput          bool
	minimumLoadThreshold int64
)

func init() {
	const defaultShortOutput = false

	pithosctlCmd.AddCommand(statusCmd)
	statusCmd.PersistentFlags().BoolVarP(&shortOutput, "short", "s", defaultShortOutput, "Output only overall cluster status and reason if unhealthy")
	statusCmd.PersistentFlags().Int64Var(&minimumLoadThreshold, "threshold", defaults.Threshold,
		`Minimum threshold (in bytes) to compute load across the cluster.
Setting it to a too small value might result in frequent status failures on smaller clusters.`)
}

func status(ccmd *cobra.Command, args []string) error {
	replicationFactor, err := determineReplicationFactor(pithosConfig)
	if err != nil {
		return trace.Wrap(err)
	}
	pithosConfig.ReplicationFactor = replicationFactor

	if err := pithosConfig.Check(); err != nil {
		return trace.Wrap(err)
	}

	clusterStatus, err := Status()
	if err != nil {
		return trace.Wrap(err)
	}
	if err := printStatus(clusterStatus); err != nil {
		return trace.Wrap(err)
	}
	return nil
}

// Status returns status of cassandra cluster
func Status() (*cluster.Status, error) {
	status, err := cluster.GetStatus(pithosConfig)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	return status, nil
}

func printStatus(status *cluster.Status) error {
	output := os.Stdout
	if !shortOutput {
		printClusterStatus(status, output)
		fmt.Fprintln(output)
	}
	if err := printOverallStatus(status, output); err != nil {
		return trace.Wrap(err)
	}
	return nil
}

func printClusterStatus(status *cluster.Status, output io.Writer) {
	w := new(tabwriter.Writer)

	var (
		minwidth int
		tabwidth = 8
		padding  = 2
		flags    uint
		padchar  byte = '\t'
	)
	w.Init(output, minwidth, tabwidth, padding, padchar, flags)
	fmt.Fprintln(w, "NAME\tREADY\tSTATUS\tIP\tNODE\tAGE")

	for _, pod := range status.PodsStatus {
		fmt.Fprintf(w, "%s\t%v/%v\t%s\t%s\t%s\t%v\n", pod.Name,
			pod.ReadyContainers, pod.TotalContainers, pod.Status, pod.PodIP, pod.HostIP,
			translateTimestamp(*pod.CreationTimestamp))
	}

	fmt.Fprintln(w, "\nSTATUS\tSTATE\tADDRESS\tLOAD\tOWNS\tHOSTID")
	for _, node := range status.NodesStatus {
		fmt.Fprintf(w, "%s\t%s\t%s\t%v\t%v%%\t%s\n", node.Status, node.State,
			node.Address, node.Load, node.Owns, node.HostID)
	}

	w.Flush()
}

func printOverallStatus(status *cluster.Status, output io.Writer) error {
	reason, isHealthy := isClusterHealthy(status)
	fmt.Fprintf(output, "Cluster status: %s\n", getStatusString(isHealthy))
	if !isHealthy {
		return trace.Errorf("Cluster is unhealthy. Reason: %s", reason)
	}
	return nil
}

// shortHumanDuration represents pod creation timestamp in
// human readable format
func shortHumanDuration(d time.Duration) string {
	if seconds := int(d.Seconds()); seconds < -1 {
		return fmt.Sprintf("<invalid>")
	} else if seconds < 0 {
		return fmt.Sprintf("0s")
	} else if seconds < 60 {
		return fmt.Sprintf("%ds", seconds)
	} else if minutes := int(d.Minutes()); minutes < 60 {
		return fmt.Sprintf("%dm", minutes)
	} else if hours := int(d.Hours()); hours < 24 {
		return fmt.Sprintf("%dh", hours)
	} else if hours < 24*364 {
		return fmt.Sprintf("%dd", hours/24)
	}
	return fmt.Sprintf("%dy", int(d.Hours()/24/365))
}

// translateTimestamp returns the elapsed time since timestamp in
// human-readable approximation.
func translateTimestamp(timestamp metav1.Time) string {
	if timestamp.IsZero() {
		return "<unknown>"
	}
	return shortHumanDuration(time.Since(timestamp.Time))
}

func isClusterHealthy(status *cluster.Status) (unhealthyReason string, healthy bool) {
	const podStatusRunning = "Running"

	if len(status.PodsStatus) <= 1 {
		return "cluster is running with less than 2 nodes", false
	}

	if len(status.PodsStatus) != len(status.NodesStatus) {
		return "number of pods does not match the number of cassandra nodes", false
	}

	for _, pod := range status.PodsStatus {
		if pod.Status != podStatusRunning {
			return fmt.Sprintf("pod %s is in %s state", pod.Name, pod.Status), false
		}

		if pod.ReadyContainers != pod.TotalContainers {
			return fmt.Sprintf("%d container(s) are not ready in pod %s", pod.TotalContainers-pod.ReadyContainers, pod.Name), false
		}

		node, ok := status.NodesStatus[pod.PodIP]
		if !ok {
			return fmt.Sprintf("cassandra node (pod %s/%s) is not present in the cluster", pod.PodIP, pod.Name), false
		}

		if node.Status != cassandra.NodeStatusUp {
			return fmt.Sprintf("cassandra node (pod %s/%s) isn't up, current status: %s", pod.PodIP, pod.Name, node.Status), false
		}

		if node.State != cassandra.NodeStateNormal {
			return fmt.Sprintf("cassandra node (pod %s/%s) isn't in expected state, current state: %s", pod.PodIP, pod.Name, node.State), false
		}
	}

	var nodes []*cassandra.Status
	for _, status := range status.NodesStatus {
		nodes = append(nodes, status)
	}
	for i, nodeI := range nodes {
		for _, nodeJ := range nodes[i+1:] {
			loadI, err := units.ParseStrictBytes(nodeI.Load)
			if err != nil {
				return fmt.Sprintf("cannot parse load from cassandra node %s", nodeI.Address), false
			}
			loadJ, err := units.ParseStrictBytes(nodeJ.Load)
			if err != nil {
				return fmt.Sprintf("cannot parse load from cassandra node %s", nodeJ.Address), false
			}
			if isLoadOverThreshold(loadI, loadJ) {
				return reasonUnequalLoad(nodeI, nodeJ), false
			}
		}
	}

	return "", true
}

func isLoadOverThreshold(loadA, loadB int64) bool {
	if math.Min(float64(loadA), float64(loadB)) > float64(minimumLoadThreshold) {
		if math.Abs((float64(loadA-loadB))/math.Max(float64(loadA), float64(loadB))) > 0.2 {
			return true
		}
	}
	return false
}

func reasonUnequalLoad(nodeA, nodeB *cassandra.Status) string {
	return fmt.Sprintf("cassandra load on node (pod %s, %s) is not equal to load on node (pod %s, %s)", nodeA.Address, nodeA.Load, nodeB.Address, nodeB.Load)
}

func getStatusString(status bool) string {
	if status {
		return "Healthy"
	}
	return "Unhealthy"
}
