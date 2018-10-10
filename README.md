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

  ### Scripted

  install the [cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) or go the http://shell.azure.com

* create resourcegroup: __*az group create -n myAKSClusterRG -l westeurope*__
* create aks cluster: __*az aks create -g myAKSClusterRG -n myAKSCluster --node-count 1 --enable-addons monitoring --generate-ssh-keys*__
* install kubectl: __*az aks install-cli*__
* get credentials (needed for connecting to cluster): __*az aks get-credentials -g myAKSClusterRG -n myAKSCluster*__
* test if it is working __*kubectl get nodes -o wide*__

### Desired State:

#### ARM

If you like to use keyvault for storing secrets, please have a look at this [link](https://github.com/Azure/azure-quickstart-templates/tree/master/101-aks)

* cd desired-state/arm
* create resourcegroup: __*az deployment create -l westeurope --template-file rg-azuredeploy.json --parameters rgName=demoRG rgLocation=westeurope*__ of course you can change the parameters to your likings
* get ID of resourcegroup: __*az group show -n testRG --query id*__
* create service principal: __*az ad sp create-for-rbac -n testClusterSP  --role="Contributor" --scopes YOUR_RESOURCEGROUP_ID*__
* copy the password and the name of the id and put these values in the parameter file : aks-azuredeploy-parameters.json
* edit the other values in aks-azuredeploy-parameters.json as well (make sure that all the GEN-UNIQUE values are replaced)
* create cluster with ARM: __*az group deployment create -n testCluster -g testRG --template-file aks-azuredeploy.json --parameters @./aks-azuredeploy-parameters.json*__


#### Terraform


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
