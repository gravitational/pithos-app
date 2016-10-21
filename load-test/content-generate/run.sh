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

check_prerequisites() {
	announce_step "Check prerequisites"

	kubectl > /dev/null 2>&1 || die "kubectl was not found in PATH."
}

setup_cluster_ca() {
	announce_step "Setup cluster CA"

	mkdir -p /usr/share/ca-certificates/extra
	get_field_from_secret "$CLUSTER_CA_BUNDLE_SECRET_NAME" "$CLUSTER_CA_BUNDLE_SECRET_FIELD_NAME" > "$CLUSTER_CA_BUNDLE_PATH"
	update-ca-certificates
}

get_field_from_secret() {
	local usage="$FUNCNAME <secret> <field>"
	local secret=${1:?$usage}
	local field=${2:?$usage}

	kubectl get secret "$secret" --output yaml | grep "$field" | awk '{print $2}' | base64 -d
}

dump_environment_variables() {
	announce_step "Dump environment variables"

	env
}

generate_objects() {
	announce_step "Generate dummy objects"

	local temp_dir=

	temp_dir=$(mktemp --directory)
	dd if=/dev/urandom of="$temp_dir/1Kb" bs=1K count=1 &
	dd if=/dev/urandom of="$temp_dir/10Kb" bs=1024 count=10 &
	dd if=/dev/urandom of="$temp_dir/100Kb" bs=1024 count=100 &
	dd if=/dev/urandom of="$temp_dir/1Mb" bs=1024 count=1024 &
	dd if=/dev/urandom of="$temp_dir/10Mb" count=10 bs=1048576 &
	dd if=/dev/urandom of="$temp_dir/100Mb" count=100 bs=1048576 &
	dd if=/dev/urandom of="$temp_dir/1Gb" bs=1048576 count=1024 &
	wait

	bash "$SCRIPT_DIR/s3.sh" "s3api" "create-bucket" "--bucket" "1Kb" &
	bash "$SCRIPT_DIR/s3.sh" "s3api" "create-bucket" "--bucket" "10Kb" &
	bash "$SCRIPT_DIR/s3.sh" "s3api" "create-bucket" "--bucket" "100Kb" &
	bash "$SCRIPT_DIR/s3.sh" "s3api" "create-bucket" "--bucket" "1Mb" &
	bash "$SCRIPT_DIR/s3.sh" "s3api" "create-bucket" "--bucket" "10Mb" &
	bash "$SCRIPT_DIR/s3.sh" "s3api" "create-bucket" "--bucket" "100Mb" &
	bash "$SCRIPT_DIR/s3.sh" "s3api" "create-bucket" "--bucket" "1Gb" &
	wait
}

main() {
	readonly SCRIPT_DIR="$(dirname "$0")"
	readonly CLUSTER_CA_BUNDLE_SECRET_NAME="cluster-ca"
	readonly CLUSTER_CA_BUNDLE_SECRET_FIELD_NAME="ca.pem"
	readonly CLUSTER_CA_BUNDLE_PATH="/usr/local/share/ca-certificates/cluster.crt"

	dump_environment_variables
	check_prerequisites

	setup_cluster_ca
}

main
