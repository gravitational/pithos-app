package main

import (
	"context"
	"strings"
	"time"

	"github.com/gravitational/rigging"
	"github.com/gravitational/trace"
	log "github.com/sirupsen/logrus"
)

const (
	retryTimes  = 20
	retryPeriod = 5 * time.Second
)

func bootCluster() error {
	err := createPithosConfig()
	if err != nil {
		return trace.Wrap(err)
	}

	log.Infof("creating cassandra services + statefulset")
	out, err := rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/cassandra.yaml")
	if err != nil && !strings.Contains(string(out), "already exists") {
		return trace.Wrap(err)
	}

	log.Infof("initializing pithos")
	out, err = rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/pithos-initialize.yaml")

	if err != nil && !strings.Contains(string(out), "already exists") {
		return trace.Wrap(err)
	}

	log.Infof("waiting for pithos to be initialized")
	if err := retry(context.TODO(), retryTimes, retryPeriod, func() error {
		return rigging.WaitForJobSuccess("pithos-initialize", 10*time.Minute)
	}); err != nil {
		return trace.Wrap(err)
	}

	log.Infof("creating pithos replication controller")
	out, err = rigging.FromFile(rigging.ActionCreate, "/var/lib/gravity/resources/pithos.yaml")
	if err != nil && !strings.Contains(string(out), "already exists") {
		return trace.Wrap(err)
	}

	return nil
}

// retry will retry function X times until period is reached
func retry(ctx context.Context, times int, period time.Duration, fn func() error) error {
	if times < 1 {
		return nil
	}
	err := fn()
	for i := 1; i < times && err != nil; i++ {
		log.Infof("Attempt %v, result: %v, retry in %v.", i+1, trace.Wrap(err), period)
		select {
		case <-ctx.Done():
			log.Infof("Context is closing, return")
			return err
		case <-time.After(period):
		}
		err = fn()
	}
	return err
}
