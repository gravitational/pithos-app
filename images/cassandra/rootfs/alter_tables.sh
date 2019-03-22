#!/usr/bin/env bash
# -*- mode: sh; -*-

# File: alter_table_block.sh
# Time-stamp: <2019-03-14 16:44:30>
# Copyright (C) 2018 Gravatational Inc.
# Description: Update parameters for storage.block table

cqlsh --keyspace storage -f /alter_tables.cql cassandra.default.svc.cluster.local
