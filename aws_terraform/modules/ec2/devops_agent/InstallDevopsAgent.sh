#!/bin/bash
# Version 1.0
# Installs and configures Azure DevOps, Docker, Kubectl and az cli

# Command usage: InstallDevopsAgent.sh $VSTS_AGENT_INPUT_TOKEN $VSTS_AGENT_INPUT_POOL
export DEVOPS_DOWNLOAD_URL="https://vstsagentpackage.azureedge.net/agent/2.141.1/vsts-agent-linux-x64-2.141.1.tar.gz"
export ADMINUSER=${vm_username}

# Environment variables used in Azure DevOps configuration 
export VSTS_AGENT_INPUT_URL="https://dev.azure.com/${devops_organisation}"
export VSTS_AGENT_INPUT_AUTH="pat"
export VSTS_AGENT_INPUT_TOKEN=${devops_pat}
export VSTS_AGENT_INPUT_POOL=${devops_pool_name}
export VSTS_AGENT_INPUT_AGENT=$(hostname)

sudo apt-get update -y
sudo apt-get upgrade -y

if [ ! $(which curl) ]; then
  sudo apt-get install -y curl
fi

if [ ! -a /etc/systemd/system/vsts.agent.${devops_organisation}.$VSTS_AGENT_INPUT_AGENT.service ]; then
  # Download, extract and configure the agent
  curl $DEVOPS_DOWNLOAD_URL --output /tmp/vsts-agent-linux.x64.tar.gz
  mkdir /home/$ADMINUSER/agent
  cd /home/$ADMINUSER/agent
  tar zxf /tmp/vsts-agent-linux.x64.tar.gz
  sudo chown -R $ADMINUSER:999 /home/$ADMINUSER/agent
  # Install dependencies
  sudo ./bin/installdependencies.sh
  # TODO: Config needs to be configured for unattended access
  su --command "./config.sh --unattended --acceptTeeEula" $ADMINUSER
  # Configure the agent as a service
  sudo ./svc.sh install
  sudo ./svc.sh enable
  sudo ./svc.sh start
  cd /home/$ADMINUSER
fi

# Install dependencies and install Docker
if [ ! $(which docker) ]; then
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update -y 
  sudo apt-get install -y docker-ce
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker $ADMINUSER
  # Install crontab for user to clear down images
  echo "30 8 * * * docker images | egrep 'azurecr|none' | awk '{print "'$3'"}' | xargs docker rmi --force" | crontab -
fi

# Install AZ CLI and Kubectl
if [ ! $(which az) ]; then
  curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main"
  sudo apt-get -y update
  sudo apt-get -y install apt-transport-https azure-cli
  sudo az aks install-cli
fi