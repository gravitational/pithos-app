#!/usr/bin/env bash
# -*- mode: sh; -*-

# File: endpoint.sh
# Time-stamp: <2017-11-07 22:03:58>
# Copyright (C) 2017 Gravitational Inc
# Description: Endpoint for healthz container

# set -o xtrace

/usr/local/bin/healthz -access-key $AWS_ACCESS_KEY_ID -secret-key $AWS_SECRET_ACCESS_KEY
