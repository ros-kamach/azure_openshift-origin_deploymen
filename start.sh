#!/bin/bash
RESOURCE_GROUP=east-openshift-project
CN=OpenShift-Cluster

#rm -rf openshift-origin/ 
#git clone https://github.com/Microsoft/openshift-origin
# cp -r azuredeploy.parameters.json openshift-origin/
az group deployment create -g $RESOURCE_GROUP \
      --template-uri https://raw.githubusercontent.com/ros-kamach/azure-openshift-deployment/master/azuredeploy.json \
      --parameters @./azuredeploy.parameters.json --debug
      # --no-wait
#cd openshift-origin/
# az group deployment create --resource-group $RESOURCE_GROUP --name $CN --template-file azuredeploy.json --parameters @./azuredeploy.parameters.json