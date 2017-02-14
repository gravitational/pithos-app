#!/usr/bin/env bash

echo "renaming local database"
cqlsh -f /rename.cql localhost

echo "flushing node"
nodetool flush system
