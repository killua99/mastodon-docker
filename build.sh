#!/usr/bin/env bash

set -e

POSITIONAL=()

while [[ $# -gt 0 ]]; do
    key="$1"

    case "$key" in
        -h|--help)
            cat <<EOF

Comman usage:

./build.sh [<version>] [<full_tag>] [<major_tag>] [<path/Dockerfile>] --latest -d|--debug -h|--help

Arguments:

  🔰 version        Version number mastodon. Ex: 2.9.3
  🔰 full_tag       Version number mastodon. Ex: 2.9.3-13.14-2.7.1
  🔰 major_tag      Version number mastodon. Ex: 2.9-13-2.7

Options:

  🔰 latest         Tag build latest
  🔰 d|--debug      Print run time commands
  🔰 h|--help       Print this message

Help:

  This bash script is a helper to tag new mastodon build using alpine as base
  full usage example:

    ``./build.sh 2.9.3 2.9.3-12.16-2.6.6-alpine3.11 2.9.3-12.16-2.6.6-alpine alpine/2.9.3 --latest``
    ``./build.sh 2.9.3 2.9 buster-slim/2.9.3 --latest``
    ``./build.sh 2.9.3 --debug``

EOF
            exit 0
            ;;
        --latest)
            LATEST="-t killua99/mastodon:latest"
            shift
            ;;
        -d|--debug)
            set -x
            shift
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL[@]}"

MASTODON_VERSION="v${1:-2.9.3}"
FULL_TAG="${2:-2.9.3-13.14-2.7.1}"
MAJOR_TAG="${3:-2.9.3-13.14-2.7.1}"
PATH_DOCKERFILE="${4:-buster-slim/node13.14/ruby2.7.1/2.9.3}"
LATEST=${LATEST:-""}

cat <<EOF

We're about to build docker 🚢 image for the next platforms:

    📌 linux/amd64
    📌 linux/arm64
    📌 linux/arm/v7

If you wish to build for only one platform please ask for help: ``./build.sh -h|--help``

EOF

git submodule update --init --recursive
cd mastodon-upstream
git fetch --all && git checkout ${MASTODON_VERSION}
cd ..
cp -r mastodon-upstream ${PATH_DOCKERFILE}/mastodon-upstream

docker buildx build \
    --push \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    ${LATEST} \
    -t killua99/mastodon:${FULL_TAG} \
    -t killua99/mastodon:${MAJOR_TAG} ${PATH_DOCKERFILE}

rm -rf ${PATH_DOCKERFILE}/mastodon-upstream

if test ! -z ${PUSHOVER_API_KEY}; then
    curl -s \
        --form-string "token=${PUSHOVER_API_KEY}" \
        --form-string "user=${PUSHOVER_USER_KEY}" \
        --form-string "message=Mastodon docker build 🚢

Build ${MAJOR_TAG} complete" \
        https://api.pushover.net/1/messages.json
fi
