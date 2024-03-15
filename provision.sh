#!/bin/bash

rg_name="CloToDoRG"
deployment_name="deployment01"
app_name="CloToDo"
gh_user="superellips"
gh_repo=$app_name

cloud_init=$(mktemp)
trap "rm -f $app_cloud_init" EXIT

env_file=$(mktemp)
trap "rm -f $env_file" EXIT

# Get the registration token for the deployment runner
function getRunnerToken () {
  local gh_token_response=$(gh api --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    repos/$gh_user/$gh_repo/actions/runners/registration-token)

  echo $(echo $gh_token_response | jq -r '.token')
}

# Get a temporary cloud init file for the application Server
function getAppCloudInit () {
  cat cloud-init-app.sh > $cloud_init

  local token=$(getRunnerToken)

  sed -i "3i token=$(getRunnerToken)" $cloud_init
  echo $cloud_init
}

function getEnvFile () {
  local blob_constring=$(az storage account show-connection-string \
    -n $(echo $deployment_output | jq -r '.blobStorageAccountName.value') -g $rg_name | jq -r '.connectionString')
  local blob_container=$(echo $deployment_output | jq -r '.blobStorageContainerName.value')
  local mongo_constring=$(az cosmosdb keys list -n \
    $(echo $deployment_output | jq -r '.cosmosDbAccoutName.value') -g $rg_name --type connection-strings \
    | jq -r '.connectionStrings[0].connectionString')

  cat .env > $env_file

  sed -i "\$a MongoDBSettings__ConnectionString=\"$mongo_constring\"" $env_file
  sed -i "\$a BlobStorageSettings__ConnectionString=\"$blob_constring\"" $env_file
  sed -i "\$a BlobStorageSettings__ContainerName=$blob_container" $env_file

  echo $env_file
}

function deployTemplate () {
  az group create --location swedencentral --name $rg_name

  local deployment_result=$(az deployment group create \
    -g $rg_name -f deployment.json -n $deployment_name \
    --parameters \
      applicationName=$app_name \
      sshKey="$(cat ~/.ssh/id_rsa.pub)" \
      reverseProxyCustomData=@cloud-init-reverse.sh \
      appServerCustomData=@$(getAppCloudInit) | jq -r '.status')

  if [ "$deployment_result" == "Failed" ]; then
    return 1
  else
    return 0
  fi
}

function configAppServer () {
  cp ~/.ssh/known_hosts ~/.ssh/known_hosts_temp.bak
  rm -f ~/.ssh/known_hosts
  eval $(ssh-agent)
  ssh-add
  ssh -o StrictHostKeyChecking=no -A -N -L 2222:10.0.0.10:22 azureuser@$bastion_ip &
  tunnel_pid=$!
  scp -o StrictHostKeyChecking=no -P 2222 $(getEnvFile) azureuser@localhost:/tmp/.env
  ssh -o StrictHostKeyChecking=no -p 2222 azureuser@localhost "sudo mkdir /etc/$app_name && \
    sudo mv /tmp/.env /etc/$app_name/$app_name.env && sudo chown -R root:root /etc/$app_name \
    && sudo chmod 400 /etc/$app_name/$app_name.env"
  kill $tunnel_pid
  rm -f ~/.ssh/known_hosts
  mv ~/.ssh/known_hosts_temp.bak ~/.ssh/known_hosts
  ssh-agent -k
}

# Ensure that the user is signed in with the GitHub CLI
gh auth status || exit 1

# Deploy the template
deployTemplate

# Exit if deployment failed
if [ $? -gt 0 ]; then
  echo "Deployment failed"
  exit 1
fi

deployment_output=$(az deployment group show \
  --name $deployment_name --resource-group $rg_name \
  --query properties.outputs)

bastion_ip=$(az vm show -g $rg_name -n $(echo $deployment_output | jq -r '.bastionName.value') \
  --show-details --query "publicIps" -o tsv)

configAppServer
