#!/usr/bin/env bash

set -eo pipefail; [[ $TRACE ]] && set -x

usage() {
    cat >&2 <<EOT
Generate HTTP headers for auth request to S3

Usage: $0 { download | upload }

Commands:
	download <bucket-name> <object-name>
	upload <file> <bucket-name> <object-name> <acl-rule>

Environment:
	AWS_ACCESS_KEY_ID           -- required
	AWS_SECRET_ACCESS_KEY       -- required
	AWS_S3_ENDPOINT_URL         -- optional, default: s3.amazonaws.com
EOT
    exit 2
}

main() {
	# Env
	readonly AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?$(usage)}
	readonly AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?$(usage)}
	readonly AWS_S3_ENDPOINT_URL=${AWS_S3_ENDPOINT_URL:-"s3.amazonaws.com"}

	local arg_action="${1:?$(usage)}"
	arg_action="${arg_action//-/_}"
	shift || :

	"handle_${arg_action}_action" "$@"
}

handle_download_action() {
	local usage="$FUNCNAME <bucket-name> <object-name>"
	local bucket=${1:?$usage}
	local object=${2:?$usage}
	local resource="/${bucket}/${object}"

	get_signature <<-EOF
		GET


		S3_DATE
		${resource}
	EOF
}

handle_upload_action() {
	local usage="$FUNCNAME <file> <bucket-name> <object-name> <acl-rule>"
	local src=${1:?$usage}
	local bucket=${2:?$usage}
	local object=${3:?$usage}
	# http://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
	local acl=${4:?$usage}

	local resource="/${bucket}/${object}"
	local src_digest=

	src_digest=$(openssl md5 -binary < "${src}" | openssl base64)

	echo "$src_digest"
	echo "$acl"

	get_signature <<-EOF
		PUT
		${src_digest}

		S3_DATE
		x-amz-acl:${acl}
		${resource}
	EOF
}

get_signature() {
	local date=
	local signature=
	local auth=

	date=$(get_http_date)

	signature=$(
		sed "s/S3_DATE/${date}/" |
		strip_trailing_newline |
		openssl sha1 -hmac "$AWS_SECRET_ACCESS_KEY" -binary |
		openssl base64
	)
	auth="AWS ${AWS_ACCESS_KEY_ID}:${signature}"

	echo "$AWS_S3_ENDPOINT_URL"
	echo "$date"
	echo "$auth"
}

strip_trailing_newline () {
	awk 'NR > 1 { printf "\n" } { printf "%s", $0 }' || return 0
}

get_http_date() {
	date -u -R
}

main "$@"
