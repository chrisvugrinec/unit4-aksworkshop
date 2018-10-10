# unit4-aksworkshop

The goal of this workshop is to get familiar with AKS and learn some basic troubleshooting, topics will be:

* Setup AKS cluster
  * by script
  * by desired state config: ARM or Terraform
* Deploy  Game of Thrones Application
  * Setup application logging with EFK
  * Install OSBA, move REDIS to PAAS
* Deploy Cats and Dogs application
  * package application in Helm
* Implement basic Security
  * Namespace management
  * Exposure of services
* Infrastructure logging
  * Setup prometheus
  * Look at Integrated logging (Application Insights)
* Config Autoscaling
  * Chatbot scaler


## Setup AKS cluster
  ### by script

  install the [cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) or go the http://shell.azure.com

* create resourcegroup: __*az group create -n myAKSClusterRG -l westeurope*__
* create aks cluster: __*az aks create -g myAKSClusterRG -n myAKSCluster --node-count 1 --enable-addons monitoring --generate-ssh-keys*__
* install kubectl: __*az aks install-cli*__
* get credentials (needed for connecting to cluster): __*az aks get-credentials -g myAKSClusterRG -n myAKSCluster*__
* test if it is working __*kubectl get nodes -o wide*__

### by desired state config: ARM or Terraform


## Deploy  Game of Thrones Application
  ### Setup application logging with EFK
  ### Install OSBA, move REDIS to PAAS
## Deploy Cats and Dogs application
  ### package application in Helm
## Implement basic Security
  ### Namespace management
  ### Exposure of services
## Infrastructure logging
  ### Setup prometheus
  ### Look at Integrated logging (Application Insights)
## Config Autoscaling
  ### Chatbot scaler
