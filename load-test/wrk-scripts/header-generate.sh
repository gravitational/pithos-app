#!/usr/bin/env bash

set -eo pipefail; [[ $TRACE ]] && set -x

main() {
    local usage="$0
    Env:
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_S3_ENDPOINT_URL
    "
    readonly AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:?$usage}
    readonly AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:?$usage}
    readonly AWS_S3_ENDPOINT_URL=${AWS_S3_ENDPOINT_URL:-"s3.amazonaws.com"}

    get_signature
}

get_signature() {
	local date=
    local signature=
    local auth=

	date=$(get_http_date)
	signature=$(
		echo "$date" |
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
    date -R
}

main "$@"
