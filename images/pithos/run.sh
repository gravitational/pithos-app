#!/bin/sh

java -jar /pithos.jar -f /etc/pithos/config.yaml -a install-schema

dumb-init java -jar /pithos.jar -f /etc/pithos/config.yaml

