#!/bin/bash

# Configuration file for user-specific details.
# This file is gitignore'd and will be sourced by build scripts.

# Note: For passwords or GPG keys, make sure that special characters such
# as $ won't be expanded, by using single quotes to enclose the string,
# or escaping with \$.

# These scripts are designed and tested against podman. They may also work
# with docker, but it's not guaranteed. You can set this variable to the
# relevant tool in your PATH or an absolute path to run it from.
export PODMAN='podman'

# Path to a Git clone of https://github.com/godotengine/godot-builds.
# Only used for uploading official releases.
export GODOT_BUILDS_PATH=''

# SSH hostname to upload Web editor builds to.
# Only used for uploading official releases.
export WEB_EDITOR_HOSTNAME=''

# Registry for build containers.
# The default registry is the one used for official Godot builds.
# Note that some of its images are private and only accessible to selected
# contributors.
# You can build your own registry with scripts at
# https://github.com/godotengine/build-containers
export REGISTRY=''

# Version string of the images to use in build.sh.
export IMAGE_VERSION='BRANCH-DISTRO'

# Default build name used to distinguish between official and custom builds.
export BUILD_NAME='custom_build'

# Default number of parallel cores for each build.
export NUM_CORES=8

# Set up your own signing keystore and relevant details below.
# If you do not fill all SIGN_* fields, signing will be skipped.

# Path to pkcs12 archive.
export SIGN_KEYSTORE=''

# Password for the private key.
export SIGN_PASSWORD=''

# Name and URL of the signed application.
# Use your own when making a thirdparty build.
export SIGN_NAME=''
export SIGN_URL=''

# Hostname or IP address of an OSX host (Needed for signing)
# eg 'user@10.1.0.10'
export OSX_HOST=''
# ID of the Apple certificate used to sign
export OSX_KEY_ID=''
# Bundle id for the signed app
export OSX_BUNDLE_ID=''
# Username/password for Apple's signing APIs (used for notarytool)
export APPLE_TEAM=''
export APPLE_ID=''
export APPLE_ID_PASSWORD=''

# NuGet source for publishing .NET packages
export NUGET_SOURCE='nuget.org'
# API key for publishing NuGet packages to nuget.org
export NUGET_API_KEY=''

# MavenCentral (sonatype) credentials
export OSSRH_GROUP_ID=''
export OSSRH_USERNAME=''
export OSSRH_PASSWORD=''
# Sonatype assigned ID used to upload the generated artifacts
export SONATYPE_STAGING_PROFILE_ID=''
# Used to sign the artifacts after they're built
# ID of the GPG key pair, the last eight characters of its fingerprint
export SIGNING_KEY_ID=''
# Passphrase of the key pair
export SIGNING_PASSWORD=''
# Base64 encoded private GPG key
export SIGNING_KEY=''

# Android signing configs
# Path to the Android keystore file used to sign the release build
export GODOT_ANDROID_SIGN_KEYSTORE=''
# Key alias used for signing the release build
export GODOT_ANDROID_KEYSTORE_ALIAS=''
# Password for the key used for signing the release build
export GODOT_ANDROID_SIGN_PASSWORD=''
