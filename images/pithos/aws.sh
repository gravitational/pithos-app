#!/usr/bin/env bash
# -*- mode: sh; -*-

# File: aws.sh
# Time-stamp: <2018-10-01 18:09:53>
# Copyright (C) 2018 Gravitational Inc.
# Description: Helper for AWS cli

# set -o xtrace
set -o nounset
set -o errexit
set -o pipefail

aws --endpoint $ENDPOINT --ca-bundle /etc/cluster-ssl/default-server-with-chain.pem "$@"
