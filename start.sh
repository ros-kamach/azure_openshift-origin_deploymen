#!/bin/bash
RESOURCE_GROUP=east-openshift-project
CN=OpenShift-Cluster

az group deployment create -g $RESOURCE_GROUP \
      --template-uri https://raw.githubusercontent.com/ros-kamach/azure_openshift-origin_deploymen/azure_deployment/azuredeploy.json \
      --parameters @./azuredeploy.parameters.json \
      --debug
      # --no-wait
