#!/bin/bash

sudo apt install unzip zip -y

cd modules
git clone -b main https://github.com/godotengine/godot-build-scripts.git build-scripts

cd git
git clone -b 4.4 https://github.com/godotengine/godot.git git

cd ..
git clone -b main https://github.com/godotengine/build-containers.git build-containers
