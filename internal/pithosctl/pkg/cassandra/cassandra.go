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

package cassandra

import (
	"bufio"
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/gravitational/trace"
)

// NodeState represents the phase/state of the cassandra node in the ring
type NodeState string

// NodeStates enumerated
const (
	NodeStateUnknown NodeState = "Unknown"
	NodeStateNormal  NodeState = "Normal"
	NodeStateLeaving NodeState = "Leaving"
	NodeStateJoining NodeState = "Joining"
	NodeStateMoving  NodeState = "Moving"
)

// NodeStatus represents the status of the cassandra node in the ring
type NodeStatus string

// NodeStatus enumerated
const (
	NodeStatusUnknown NodeStatus = "Unknown"
	NodeStatusUp      NodeStatus = "Up"
	NodeStatusDown    NodeStatus = "Down"
)

// Status represents status of cassandra node
type Status struct {
	// Status represents the status of the cassandra node in the ring
	Status NodeStatus
	// State represents the phase/state of the cassandra node in the ring
	State NodeState
	// Address of cassandra node in the ring
	Address string
	// Load represents disk usage for data of the cassandra node
	Load string
	// Owns represents percentage of data owned by the cassandra node
	Owns float64
	// HostID represents unique ID of the cassandra node in the ring
	HostID string
}

// GetStatus returns statuses of cassandra nodes in the ring
func GetStatus(statusOutput string) (map[string]*Status, error) {
	scanner := bufio.NewScanner(strings.NewReader(statusOutput))

	var statuses = make(map[string]*Status)
	lineCount := 0
	for scanner.Scan() {
		lineCount++
		/*
			Skip the first 5 lines
			Datacenter: datacenter1
			======================
			Status=Up/Down
			|/ State=Normal/Leaving/Joining/Moving
			--  Address          Load       Tokens       Owns (effective)  Host ID           Rack
		*/
		if lineCount <= 5 {
			continue
		}

		line := scanner.Text()
		if line == "" {
			continue
		}

		/*
		   Example of output
		   UN  10.244.46.7  110.64 KiB  32           100.0%            ee7e7620-58a4-4d9c-a75a-49dbc0647877  rack1
		   UN  10.244.42.8  119.49 KiB  32           100.0%            4a5b6fbb-412c-4a5e-af19-e4d241f3988b  rack1
		   UN  10.244.20.9  140.14 KiB  32           100.0%            d71a49b2-bdfd-4180-a525-0e9b7396131a  rack1
		*/
		nodeStatus, err := processNode(line)
		if err != nil {
			return nil, trace.Wrap(err)
		}

		statuses[nodeStatus.Address] = nodeStatus
	}
	if err := scanner.Err(); err != nil {
		return nil, trace.Wrap(err)
	}

	return statuses, nil
}

func processNode(line string) (*Status, error) {
	reNodeStatus := regexp.MustCompile(`^(?P<status>[A-Z])(?P<state>[A-Z])\s+?(?P<ip>(?:[0-9]{1,3}\.){3}[0-9]{1,3})\s+(?P<load>[0-9\.\?]+)\s+(?P<load_units>[A-Za-z]+)?\s+(?P<tokens>[0-9]+)\s+(?P<owns>[0-9\.%]+)\s+(?P<uuid>[a-f\-0-9]+)\s+(?P<rack>.*)$`)
	fields := reNodeStatus.FindAllStringSubmatch(line, -1)

	ownsPercentage, err := strconv.ParseFloat(fields[0][7], 32)
	if err != nil {
		return nil, trace.Wrap(err)
	}

	return &Status{
		Status:  getNodeStatus(fields[0][1]),
		State:   getNodeState(fields[0][2]),
		Address: fields[0][3],
		Load:    getNodeLoad(fields[0][4], fields[0][5]),
		Owns:    ownsPercentage,
		HostID:  fields[0][8],
	}, nil
}

func getNodeLoad(load, unit string) string {
	if load == "?" {
		return "0KiB"
	}
	return fmt.Sprintf("%s%s", load, unit)
}

func getNodeStatus(status string) NodeStatus {
	switch status {
	case "U":
		return NodeStatusUp
	case "D":
		return NodeStatusDown
	}
	return NodeStatusUnknown
}

func getNodeState(state string) NodeState {
	switch state {
	case "N":
		return NodeStateNormal
	case "M":
		return NodeStateMoving
	case "J":
		return NodeStateJoining
	case "L":
		return NodeStateLeaving
	}
	return NodeStateUnknown
}
