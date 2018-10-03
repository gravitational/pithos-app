#!/usr/bin/env bash
# -*- mode: sh; -*-

# File: alter_table_block.sh
# Time-stamp: <2018-10-01 17:32:16>
# Copyright (C) 2018 Gravatational Inc.
# Description: Update parameters for storage.block table

cqlsh --keyspace storage -f /alter_table_block.cql cassandra.default.svc.cluster.local
