#!/bin/bash

set -e

BASEDIR="$(cd $(dirname $0) && cd .. && pwd)"

TAG_PREFIX="test_image_"
TAG_INFIX="_openjdk_"

function line() {
	echo -e "\e[91m-----\e[0m $@ \e[91m-----\e[0m"
}

function build_docker() {
	local tag_name="${1}"; shift

	local debian_version="$(echo "${tag_name}" | sed "s/${TAG_PREFIX}//")"

	line "Building '${tag_name}'"
	docker build --quiet \
		--build-arg BASE_IMAGE="debian:${debian_version}-slim" \
		--tag "${tag_name}" \
		${BASEDIR}/docker
}

function test_docker() {
	local tag_name="${1}"; shift

	test_image "${tag_name}" docker info
	test_image "${tag_name}" docker run --rm hello-world
}

function build_openjdk() {
	local tag_name="${1}"; shift

	local openjdk_version="$(echo "${tag_name}" | sed "s/${TAG_PREFIX}.*${TAG_INFIX}//")"
	local from_image="$(echo "${tag_name}" | sed "s/${TAG_INFIX}${openjdk_version}//")"

	line "Building '${tag_name}'"
	docker build --quiet \
		--build-arg FROM_IMAGE="${from_image}" \
		--build-arg OPENJDK_VERSION=${openjdk_version} \
		--tag "${tag_name}" \
		${BASEDIR}/docker-openjdk
}

function test_openjdk() {
	local tag_name="${1}"; shift

	local openjdk_version="$(echo "${tag_name}" | sed "s/${TAG_PREFIX}.*${TAG_INFIX}//")"
	local openjdk_image="eclipse-temurin:${openjdk_version}-jre"

	test_image "${tag_name}" java --version
	test_image "${tag_name}" docker run --rm ${openjdk_image} java --version
}

function test_image() {
	local tag_name="${1}"; shift
	local container_name="$(echo "${tag_name}" | sed 's/_image_/_container_/')"

	line "Running '${container_name}' as user '$(id -u):$(id -g)' ($@)"
	docker run -it --rm --privileged \
		--env USER_ID=$(id -u) \
		--env GROUP_ID=$(id -g) \
		--name "${container_name}" \
		"${tag_name}" "$@"

	line "Running '${container_name}' ($@)"
	docker run -it --rm --privileged --name "${container_name}" "${tag_name}" "$@"
}

case "${1}" in
	quickest)
		docker_image="${TAG_PREFIX}bullseye"
		build_docker "${docker_image}"
		test_image "${docker_image}" docker info
		;;

	quick)
		docker_image="${TAG_PREFIX}bullseye"
		build_docker "${docker_image}"
		test_image "${docker_image}" docker info
		openjdk_image="${docker_image}${TAG_INFIX}11"
		build_openjdk "${openjdk_image}"
		build_openjdk "${openjdk_image}"
		test_image "${openjdk_image}" java --version
		;;

	*)
		for debian_version in bullseye bookworm; do
			docker_image="${TAG_PREFIX}${debian_version}"
			build_docker "${docker_image}"
			test_docker "${docker_image}"
			for openjdk_version in 11 17; do
				openjdk_image="${docker_image}${TAG_INFIX}${openjdk_version}"
				build_openjdk "${openjdk_image}"
				test_openjdk "${openjdk_image}"
			done
		done
		;;
esac
