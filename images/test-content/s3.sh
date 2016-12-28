#!/usr/bin/env bash

set -eo pipefail; [[ $TRACE ]] && set -x

die() {
	echo "ERROR: $*" >&2
	exit 1
}

announce_step() {
	echo
	echo "===> $*"
	echo
}

usage() {
	cat >&2 <<EOT
Anypoint backup/restore utility.

Usage: $0 { s3|s3api }

Commands:
	s3                            - Raw s3 actions (see "aws s3 help" for more information)
	s3api                         - Raw s3api actions (see "aws s3api help" for more information)

Requirements:
	- kubectl
	- aws (awscli)

Environment:
Required:
	AWS_S3_ENDPOINT_URL           - The endpoint to make the call against (like https://s3.amazonaws.com)
	AWS_ACCESS_KEY_ID             - AWS access key
	AWS_SECRET_ACCESS_KEY         - AWS secret key
EOT
	exit 2
}

check_prerequisites() {
	kubectl > /dev/null 2>&1 || die "kubectl was not found in PATH."
	aws help > /dev/null 2>&1 || die "aws was not found in PATH."
}

handle_s3_action() {
	aws --endpoint-url "$AWS_S3_ENDPOINT_URL" --ca-bundle "$CLUSTER_CA_BUNDLE_PATH" s3 "$@"
}

handle_s3api_action() {
	aws --endpoint-url "$AWS_S3_ENDPOINT_URL" --ca-bundle "$CLUSTER_CA_BUNDLE_PATH" s3api "$@"
}

main() {
	# ENV
	# We should use pithos DNS name because certificates are signed for *.default.svc
	readonly AWS_S3_ENDPOINT_URL=${AWS_S3_ENDPOINT_URL:?$(usage)}
	readonly AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?$(usage)}
	readonly AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?$(usage)}

	# Parse args
	local arg_action="${1:?$(usage)}"
	local arg_action="${arg_action//-/_}"
	shift || :

	# Sanity checks
	[[ "$arg_action" == "s3" || \
		"$arg_action" == "s3api" \
	]] || die "Invalid action: $arg_action"

	# Constants
	readonly CLUSTER_CA_BUNDLE_PATH="/usr/local/share/ca-certificates/cluster.crt"

	# pass to aws cli
	export AWS_ACCESS_KEY_ID
	export AWS_SECRET_ACCESS_KEY

	# Main logic
	check_prerequisites
	"handle_${arg_action}_action" "$@"
}

main "$@"
