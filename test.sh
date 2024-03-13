#!/bin/bash

rg_name="Test6RG"

# Ensure that the user is signed in with the GitHub CLI
gh auth status || exit 1

# Get the registration token for the deployment runner
gh_user="superellips"
gh_repo="GithubActionsDemo"
gh_token_response=$(gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  repos/$gh_user/$gh_repo/actions/runners/registration-token)

runner_token=$(echo $gh_token_response | jq -r '.token')

if [ -z "$runner_token" ]; then
  echo "No token found."
  exit 1
fi

sed -i "3i token=$runner_token" cloud-init-app.sh

az group create --location swedencentral --name $rg_name
az deployment group create \
  -g $rg_name -f deployment.json \
  --parameters \
    applicationName=GithubActionsDemo \
    sshKey="$(cat ~/.ssh/id_rsa.pub)" \
    reverseProxyCustomData=@cloud-init-reverse.sh \
    appServerCustomData=@cloud-init-app.sh

sed -i "3d" cloud-init-app.sh
