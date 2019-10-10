#!/usr/bin/env bash
# -*- mode: sh; -*-

# File: start-telegraf.sh
# Time-stamp: <2018-12-10 17:16:10>
# Copyright (C) 2018 Gravitational Inc
# Description:

# set -o xtrace
set -o nounset
set -o errexit
set -o pipefail

# start telegraf
/usr/bin/telegraf --config /etc/telegraf/telegraf.conf
