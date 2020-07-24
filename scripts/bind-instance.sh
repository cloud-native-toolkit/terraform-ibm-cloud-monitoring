#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

CLUSTER_ID="$1"
INSTANCE_NAME="$2"
ACCESS_KEY="$3"

echo "Configuring Sysdig for ${CLUSTER_ID} cluster and ${INSTANCE_NAME} Sysdig instance"

ibmcloud target
if ibmcloud ob monitoring config ls --cluster "${CLUSTER_ID}" | grep -q "Instance name"; then
  EXISTING_INSTANCE_NAME=$(ibmcloud ob monitoring config ls --cluster "${CLUSTER_ID}" | grep "Instance name" | sed -E "s/Instance name: +([^ ]+)/\1/g")
  if [[ "${EXISTING_INSTANCE_NAME}" == "${INSTANCE_NAME}" ]]; then
    echo "Sysdig configuration already exists on this cluster"
    exit 0
  else
    echo "Existing Sysdig configuration found on this cluster for a different Sysdig instance: ${EXISTING_INSTANCE_NAME}."
    echo "Removing the config before creating the new one"
    ibmcloud ob monitoring config delete \
      --cluster "${CLUSTER_ID}" \
      --instance "${EXISTING_INSTANCE_NAME}" \
      --force
  fi
else
  echo "No existing binding found for cluster ${CLUSTER_ID}"
  ibmcloud ob monitoring config ls --cluster "${CLUSTER_ID}"
fi

set -e

echo "Creating Sysdig configuration for ${CLUSTER_ID} cluster and ${INSTANCE_NAME} Sysdig instance"
ibmcloud ob monitoring config create \
  --cluster "${CLUSTER_ID}" \
  --instance "${INSTANCE_NAME}" \
  --sysdig-access-key "${ACCESS_KEY}"
