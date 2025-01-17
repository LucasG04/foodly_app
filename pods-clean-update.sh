#!/bin/sh

# This script is used to clean and update the flutter project and the pods in the iOS project
# Mostly necessary after updating dependencies that require pod updates
# Run this script in the root of the flutter project

set -e

flutter clean
flutter pub get

cd ios
pod repo update
pod update

cd ..