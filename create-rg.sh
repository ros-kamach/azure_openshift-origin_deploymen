#!/bin/bash
LIGHT_GREAN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'
# REGION='East US'
REGION='West Europe'
# RESOURCE_GROUP="openshift-project"
RESOURCE_GROUP="openshift"
SPN="openshiftcloudprovider"
# KEYVAULT_NAME="openshift-kv-demo"
KEYVAULT_NAME="openshift-kv-demo"
# KEYVAULT_SECRET_NAME="openshift-kv-demo-secret"
KEYVAULT_SECRET_NAME="openshift-kv-demo-secret"
CLUSTER_PREFIX="openshift-demo"
# CLUSTER_PREFIX="ocpcluster"
CN=OpenShift-Cluster

#az login -u obryg@sofserveinc.com -p BuduSupu45
printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Creating Resource Group${NC}\n"
az group create -n $RESOURCE_GROUP -l "$REGION" 
sleep 10

printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Creating keyvault${NC}\n"
az keyvault create -n $KEYVAULT_NAME -g $RESOURCE_GROUP -l "$REGION" --enabled-for-template-deployment true 
sleep 5

printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Create SSH Key${NC}\n"
FILE="./ssh-pair/id_rsa"
if test -f "$FILE"
    then
        printf "${RED}$FILE exist${NC}\n"
        printf "${RED}Do you want to regenerate?${NC}\n"
        while true; do
            read -p "yes(Yy) to regenetate or no(Nn) to use existed : " yn
            case $yn in
                [Yy]* ) rm -rf ./ssh-pair/id_rsa* ;
                        printf "${RED}Removed old SSH-Key pair Pair${NC}\n";
                        ssh-keygen -f ./ssh-pair/id_rsa -t rsa -N '';
                        printf "${LIGHT_GREAN}New SSH-KEY pair created${NC}\n";break;;
                [Nn]* ) printf "${RED}Continue with exist SSH-Key pair${NC}\n";break;;
                * )     echo "Please answer yes(Yy) to regenerate or no(Nn) to skip generating.";;
            esac
        done
    else
        printf "${RED}$FILE doesn't exist${NC}\n"
        printf "${RED}Creating...${NC}\n"
        ssh-keygen -f ./ssh-pair/id_rsa -t rsa -N ''
        printf "${LIGHT_GREAN}New SSH-KEY pair created${NC}\n"
fi


printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Create keyvault secret${NC}\n"
az keyvault secret set --vault-name $KEYVAULT_NAME -n $KEYVAULT_SECRET_NAME --file ./ssh-pair/id_rsa 
sleep 5

printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Create Service principal for openshift${NC}\n"
ACCOUNT_ID=$( az account list | grep -o '"id": *"[^"]*"' | grep -o '"[^"]*"$' | head -1 | awk '{gsub(/\"/,"")}1' )
SERVICE_PRINCIPAL=$( az ad sp create-for-rbac -n $SPN --role contributor --scopes /subscriptions/$ACCOUNT_ID/resourceGroups/$RESOURCE_GROUP )
# sleep 15
APPID=$(echo $SERVICE_PRINCIPAL | awk -F '"' '{print $4}')
SP_PASSWORD=$(echo $SERVICE_PRINCIPAL | awk -F '"' '{print $16}')

printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Assign Contributor role for SP${NC}\n"
az role assignment create --assignee $APPID --role contributor 
az role assignment list --assignee $APPID | grep roleDefinitionName 

printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Paramatrize template${NC}\n"

FILE="./azuredeploy.parameters.json"
if test -f "$FILE"; then
    printf "${RED}$FILE exist${NC}\n"
    printf "${RED}Removing it${NC}\n"	
    rm ./azuredeploy.parameters.* 	
fi
printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Configuring template with new parameters${NC}\n"
SSH_PUBLIC_KEY=$( cat ./ssh-pair/id_rsa.pub )
OPENSHIFT_PASS=$( openssl rand -base64 21 )
cp ./template.azuredeploy.parameters.json ./azuredeploy.parameters.json 
sed -i'.bak' -e "s/CLUSTER_PREFIX/$CLUSTER_PREFIX/g" ./azuredeploy.parameters.json
sed -i'.bak' -e "s/ADMIN_USER/$SPN/g" ./azuredeploy.parameters.json
sed -i'.bak' -e "s%\OPENSHIFT_PASS%$OPENSHIFT_PASS%" ./azuredeploy.parameters.json
sed -i'.bak' -e "s%\SSH_PUBLIC_KEY%$SSH_PUBLIC_KEY%" ./azuredeploy.parameters.json
sed -i'.bak' -e "s/RESOURCE_GROUP/$RESOURCE_GROUP/g" ./azuredeploy.parameters.json
sed -i'.bak' -e "s/KEYVAULT_NAME/$KEYVAULT_NAME/g" ./azuredeploy.parameters.json
sed -i'.bak' -e "s/KEYVAULT_SECRET_NAME/$KEYVAULT_SECRET_NAME/g" ./azuredeploy.parameters.json
sed -i'.bak' -e "s/APPID/$APPID/g" ./azuredeploy.parameters.json
sed -i'.bak' -e "s/SP_PASSWORD/$SP_PASSWORD/g" ./azuredeploy.parameters.json
rm ./*.bak


provision_yes_no () {
while true; do
    read -p "yes(Yy) to process or no(Nn) to skip Template : " yn
    case $yn in
        [Yy]* ) printf "${3}Start Deploying!!!${4}\n";
                az group deployment create -g $RESOURCE_GROUP \
                --template-uri https://raw.githubusercontent.com/ros-kamach/azure_openshift-origin_deploymen/azure_deployment/azuredeploy.json \
                --parameters @./azuredeploy.parameters.json \
                --no-wait;break;;
        [Nn]* ) printf "${2}Step Skipped!!!${4}\n";break;;
        * )     echo "Please answer yes(Yy) to Deploy or no(Nn) to skip Deploying.";;
    esac
done
}

printf "${RED}#########################${NC}\n"
printf "${LIGHT_GREAN}Do you want to Deploy it into Azure${NC}\n"
provision_yes_no ./start.sh $RED $LIGHT_GREAN $NC