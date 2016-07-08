package main

import (
	"flag"
	"os"

	log "github.com/Sirupsen/logrus"
)

func main() {
	flag.Parse()

	log.Infof("starting pithosboot")

	err := bootCluster()
	if err != nil {
		log.Error(err.Error())
		os.Exit(1)
	}

	os.Exit(0)
}
