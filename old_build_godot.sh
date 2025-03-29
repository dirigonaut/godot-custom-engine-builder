#!/bin/bash
set -e

basedir=$(cd $(dirname "$0"); pwd)

branch="4.4"
distro="41"

os=""
arch=""
sub_build=""

setup=${1:-0}
build=${1:-0}
release=${1:-0}

while getopts "h?o:a:s:cbr" opt; do
  case "$opt" in
  h|\?)
    echo "Usage: $0 [OPTIONS...]"
    echo
	echo "  -g github branch for the godot repo"
	echo "  -d the fedora distro version to use"
    echo "  -o the os to build godot for (windows|linux|mac|ios|web|andriod)"
	echo "  -a the architecture to package releases for (all|x32|x64|arm)"
	echo "  -s build godot (all|classical|mono)"
    echo "  -c create the godot podman images"
    echo "  -b run the godot build scripts"
    echo "  -r package the godot built executables"
    echo
    exit 1
    ;;
  g)
	branch="$OPTARG"
  	;;
  d)
	distro="$OPTARG"
  	;;
  o)
	if   [ "$OPTARG" == "windows" ]; then
      os="windows"
    elif [ "$OPTARG" == "linux" ]; then
      os="linux"
	elif [ "$OPTARG" == "mac" ]; then
      os="mac"
	elif [ "$OPTARG" == "ios" ]; then
      os="ios"
	elif [ "$OPTARG" == "web" ]; then
      os="web"
	elif [ "$OPTARG" == "andriod" ]; then
      os="andriod"
	else
		echo "$OPTARG is not a valid environment"
		exit 1
    fi
    ;;
  a)
    if   [ "$OPTARG" == "x32" ]; then
      arch="x32"
	elif [ "$OPTARG" == "x64" ]; then
      arch="x64"
	elif [ "$OPTARG" == "arm" ]; then
      arch="arm"
	else
		echo "$OPTARG is not a valid architecture"
		exit 1
    fi
    ;;
  s)
    if   [ "$OPTARG" == "classical" ]; then
      sub_build="classical"
	elif [ "$OPTARG" == "mono" ]; then
      sub_build="mono"
	else
		echo "$OPTARG is not a valid sub-build."
		exit 1
    fi
    ;;
  c)
    setup=1
    ;;
  b)
    build=1
    ;;
  r)
    release=1
    ;;
  esac
done

function build_containers() {
	# Get the line numbers to omit the mac/ios library imports if we are not build for mac/ios
	local line_num=""
	if [[ "$env" == "mac" || "$env" == "ios" ]]; then 
		line_num=$(wc -l "$basedir/modules/build-containers/build.sh" | head -n 1 | cut -d " " -f1)
	else
		line_num=$(grep -n "XCODE_SDK" "$basedir/modules/build-containers/build.sh" | head -n 1 | cut -d: -f1)
		line_num=$(( $line_num - 1 ))
	fi
	
	# Remove the lines determined above
	sed -n "1,${line_num}p" "$basedir/modules/build-containers/build.sh" > "$basedir/modules/build-containers/build_temp.sh"

	# Massage the env name to match as they use ios in containers and mac in build-scripts
	local build="$env"
	if [ "$build" == "mac" ]; then
		build="osx"
	fi
	
	# Filter out all the podman_build commands
	local filtered_file=$(grep -v "^podman_build\s" "$basedir/modules/build-containers/build_temp.sh")
	echo "$filtered_file" > "$basedir/modules/build-containers/build_temp.sh"

	# Add back in the commands to build the env we want 
	echo "podman_build base" >> "$basedir/modules/build-containers/build_temp.sh"
	echo "podman_build $build" >> "$basedir/modules/build-containers/build_temp.sh"

	# The linux build is used to build the mono C# support so it will always be needed
	if [[ ! "$build" == "linux" ]]; then
		echo "podman_build linux" >> "$basedir/modules/build-containers/build_temp.sh"
	fi

	# Removing \r from files as they came that way
	tr -d '\r' < $basedir/modules/build-containers/build_temp.sh > $basedir/modules/build-containers/build_$env.sh
	tr -d '\r' < $basedir/modules/build-containers/setup.sh > $basedir/modules/build-containers/setup_staging.sh
	mv -f $basedir/modules/build-containers/setup_staging.sh $basedir/modules/build-containers/setup.sh

	# Removing staging files as most bash operations do not allow editing in place
	rm $basedir/modules/build-containers/build_temp.sh

	# Allow the custom build file we created to be executed
	chmod +x "$basedir/modules/build-containers/build_${env}.sh"

	# If this is a mac/ios build then symlink the files dir for it to have access to the dependencies it needs
	if [[ "$env" == "mac" || "$env" == "ios" ]]; then 
		ln -sf $basedir/modules/files $basedir/modules/build-containers/files
	fi

	# Run the build_$env.sh script we constructed
	cd "$basedir/modules/build-containers/"
	echo "bash build_${env}.sh $godot_branch $base_distro"
	bash build_$env.sh "$godot_branch" "$base_distro"
}

function join_by { local IFS="$1"; shift; echo "$*"; }
function build_executables() {
	local godot_version="$godot_branch-$env-custom"

	# Since we are going to skip a checkout we call the godot make_tarball.sh script
	# Then we will move the file into the correct location it is expected in 
	cd "$basedir/modules/build-scripts"
	pushd git
	sh misc/scripts/make_tarball.sh -v ${godot_version}
	popd
	cd "$basedir"

	# Now build the regex necessary to filter out all the other build commands in:
	# - "$basedir/modules/build-scripts/build.sh"
	local entries=(windows linux web macos android ios)
	entries=( "${entries[@]/$env}" )      # Removes the env from the array that is being built
	entries=( ${entries[@]} )             # Remove extra spaces
	entries=$(join_by \| "${entries[@]}") # Delimit with | for regex or
	local regex="/out/($entries)"

	# Use the the regex to remove all the other build commands and then trim out any \r
	grep -E -v "$regex" "$basedir/modules/build-scripts/build.sh" | tr -d '\r' > "$basedir/modules/build-scripts/build_$env.sh"
	chmod +x "$basedir/modules/build-scripts/build_${env}.sh"

	# Trim out any \r in the $basedir/modules/build-scripts/build-${env}/build.sh
	tr -d '\r' < "$basedir/modules/build-scripts/build-${env}/build.sh" > "$basedir/modules/build-scripts/build-${env}/build_temp.sh"
	mv -f "$basedir/modules/build-scripts/build-${env}/build_temp.sh" "$basedir/modules/build-scripts/build-${env}/build.sh"

	# Copy over the config in this repo into the build-script module repo
	# Then inject the built IMAGE_VERSION for the process versioning
	cp "$basedir/vars/config.sh" "$basedir/modules/build-scripts/config.sh"
	sed -i -e "s/BRANCH-DISTRO/$godot_branch-$base_distro/g" $basedir/modules/build-scripts/config.sh

	# Run the build script we have formatted to build the desired env executable
	cd "$basedir/modules/build-scripts/"
	bash build_$env.sh -c -s -v $godot_version
}

function package_executables() {
	local godot_version="$godot_branch-$env-custom"
	local godot_template="$godot_branch.$env.custom"

	raw_sections=($(awk '/##\s\w+\s\(\w+\)\s##/{gsub(/##/, "", $0); gsub(/^\s*|\s*$/, "", $0); gsub(/\s+/, "_", $0); print NR":"$0}' $basedir/modules/build-scripts/build-release.sh))
	declare -A sections

	for i in "${raw_sections[@]}"
	do
		IFS=':' read -ra section <<< "$i"
		sections[line]=${section[0]}
		sections[name]=${section[1]}
		echo "${sections[line]} -> ${sections[name]}"
	done

	#local entries=(windows linux web macos android ios)
	#entries=( "${entries[@]/$env}" )      # Removes the env from the array that is being built

	# Run the build script we have formatted to build the desired env executable
	#cd "$basedir/modules/build-scripts"
	#bash build-release.sh -v "$godot_version" -t "$godot_template" -b "classical"
}

if [ "$setup" == 1 ]; then
	echo "build_containers"
	#build_containers
fi

if [ "$build" == 1 ]; then
	echo "build_executables"
	#build_executables
fi

if [ "$release" == 1 ]; then
	echo "package_executables"
	package_executables
fi