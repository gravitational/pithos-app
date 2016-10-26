#!/usr/bin/env bash

set -eo pipefail; [[ $TRACE ]] && set -x

main() {
	local usage="$0 <bucket-name> <object-name>
	Env:
	AWS_ACCESS_KEY_ID
	AWS_SECRET_ACCESS_KEY
	AWS_S3_ENDPOINT_URL
	"
	# Env
	readonly AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?$usage}
	readonly AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?$usage}
	readonly AWS_S3_ENDPOINT_URL=${AWS_S3_ENDPOINT_URL:-"s3.amazonaws.com"}

	# Args
	local usage="$0 <bucket-name> <object-name>"
	local bucket=${1:?$usage}
	local object=${2:?$usage}

	local resource="/${bucket}/${object}"

	get_signature <<-EOF
			GET


			S3_DATE
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
