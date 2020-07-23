#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

CLUSTER_ID="$1"
INSTANCE_ID="$2"
INGESTION_KEY="$3"

echo "Configuring Sysdig for ${CLUSTER_ID} cluster and ${INSTANCE_ID} Sysdig instance"

if ibmcloud ob monitoring config ls --cluster "${CLUSTER_ID}" | grep -q "Instance ID"; then
  EXISTING_INSTANCE_ID=$(ibmcloud ob monitoring config ls --cluster "${CLUSTER_ID}" | grep "Instance ID" | sed -E "s/Instance ID: +([^ ]+)/\1/g")
  if [[ "${EXISTING_INSTANCE_ID}" == "${INSTANCE_ID}" ]]; then
    echo "Sysdig configuration already exists on this cluster"
    exit 0
  else
    echo "Existing Sysdig configuration found on this cluster for a different Sysdig instance: ${EXISTING_INSTANCE_ID}."
    echo "Removing the config before creating the new one"
    ibmcloud ob monitoring config delete \
      --cluster "${CLUSTER_ID}" \
      --instance "${INSTANCE_ID}" \
      --force
  fi
fi

set -e

echo "Creating Sysdig configuration for ${CLUSTER_ID} cluster and ${INSTANCE_ID} Sysdig instance"
ibmcloud ob monitoring config create \
  --cluster "${CLUSTER_ID}" \
  --instance "${INSTANCE_ID}" \
  --logdna-ingestion-key "${INGESTION_KEY}"
