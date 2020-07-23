#!/usr/bin/env bash

if ibmcloud plugin list | grep -q observe-service; then
  echo "The ibmcloud cli observe-service plugin is already installed"
else
  set -e
  echo "Installing the ibmcloud cli observe-service"
  ibmcloud plugin install observe-service -f
fi
