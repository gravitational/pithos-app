#!/bin/sh

set -e

dumb-init java -jar /pithos.jar -f /etc/pithos/config.yaml
