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
	"strconv"
	"strings"
	"unicode"

	"github.com/gravitational/trace"
)

const numberOfColumns = 8

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
	// Owns represent percentage of data owned by the cassandra node
	Owns float32
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
	return statuses, nil
}

func processNode(line string) (*Status, error) {
	f := func(c rune) bool {
		return !unicode.IsLetter(c) && !unicode.IsNumber(c) && c != '.' && c != '-'
	}
	fields := strings.FieldsFunc(line, f)

	if len(fields) != numberOfColumns {
		return nil, trace.Errorf("invalid format of nodetool status output, wrong line: %s", line)
	}

	ownsPercentage, err := strconv.ParseFloat(fields[5], 32)
	if err != nil {
		return nil, err
	}

	return &Status{
		Status:  getNodeStatus(fields[0][0]),
		State:   getNodeState(fields[0][1]),
		Address: fields[1],
		Load:    fmt.Sprintf("%s%s", fields[2], fields[3]),
		Owns:    float32(ownsPercentage),
		HostID:  fields[6],
	}, nil
}

func getNodeStatus(b byte) NodeStatus {
	switch b {
	case 85:
		return NodeStatusUp
	case 68:
		return NodeStatusDown
	}
	return NodeStatusUnknown
}

func getNodeState(b byte) NodeState {
	switch b {
	case 78:
		return NodeStateNormal
	case 77:
		return NodeStateMoving
	case 74:
		return NodeStateJoining
	case 76:
		return NodeStateLeaving
	}
	return NodeStateUnknown
}
