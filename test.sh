#!/bin/bash

os_builds=("linux windows macos web ios android")

if [ ! -z "$1" ]; then
	os_builds=("$1")
fi

if printf '%s\0' "${os_builds[@]}" | grep -Fqwz -- "macos" || printf '%s\0' "${os_builds[@]}" | grep -Fqwz -- "ios"; then
	echo true
fi

echo $4

BUILD_LINUX=$(if printf '%s\0' "${OPERATING_SYSTEMS[@]}" | grep -Fqwz -- "linux"; then echo 1; else echo 0; fi;)
echo $BUILD_LINUX

if [ $BUILD_LINUX == 1 ] ; then echo "here"; fi;
