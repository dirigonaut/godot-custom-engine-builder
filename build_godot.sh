#!/bin/bash
set -e

basedir=$(cd $(dirname "$0"); pwd)

branch="4.4"
distro="41"

os="windows"

setup=${1:-0}
build=${2:-0}
release=${3:-0}

if [ $setup == 1 ]; then
	chmod +x $basedir/script_overrides/build-containers/build.sh
	cp "$basedir/script_overrides/build-containers/build.sh" "$basedir/modules/build-containers/build.sh"

	ln -sf $basedir/modules/files $basedir/modules/build-containers/files

	# Run the build_$env.sh script we constructed
	cd "$basedir/modules/build-containers/"
	echo "bash build.sh $branch $distro"
	bash build.sh "$branch" "$distro" "$os"
fi

cd $basedir

if [ $build == 1 ]; then
	chmod +x $basedir/script_overrides/build-scripts/build.sh
	cp "$basedir/script_overrides/build-scripts/build.sh" "$basedir/modules/build-scripts/build.sh"

	chmod +x $basedir/script_overrides/build-scripts/build-${os}/build.sh
	cp "$basedir/script_overrides/build-scripts/build-${os}/build.sh" "$basedir/modules/build-scripts/build-${os}/build.sh"

	chmod +x $basedir/script_overrides/build-scripts/config.sh
	cp "$basedir/script_overrides/build-scripts/config.sh" "$basedir/modules/build-scripts/config.sh"
	sed -i -e "s/BRANCH-DISTRO/$branch-$distro/g" $basedir/modules/build-scripts/config.sh

	# Run the build_$env.sh script we constructed
	cd "$basedir/modules/build-scripts/"
	echo "bash build.sh -c -s -v $branch"
	bash build.sh -c -s -v 4.4-windows
fi

cd $basedir

if [ $release == 1 ]; then
	chmod +x $basedir/script_overrides/build-scripts/build-release.sh
	cp "$basedir/script_overrides/build-scripts/build-release.sh" "$basedir/modules/build-scripts/build-release.sh"

	# Run the build_$env.sh script we constructed
	cd "$basedir/modules/build-scripts/"
	echo "bash build-release.sh $branch $distro"
	#bash build-release.sh "$branch" "$distro"
fi