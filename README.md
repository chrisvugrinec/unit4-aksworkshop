# unit4-aksworkshop

The goal of this workshop is to get familiar with AKS and learn some basic troubleshooting, topics will be:

* Setup AKS cluster
* Setup ACR
* Deploy  Game of Thrones Application
* Implement basic Security
* Infrastructure logging
* Config Autoscaling
* Troubkeshooting


## Setup AKS cluster

Make sure you clone this repo with the following command:
__*git clone https://github.com/chrisvugrinec/unit4-aksworkshop.git*__

### Scripted

  install the [cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) or go the http://shell.azure.com

* create resourcegroup: __*az group create -n myAKSClusterRG -l westeurope*__
* create aks cluster: __*az aks create -g myAKSClusterRG -n myAKSCluster --node-count 1 --node-vm-size Standard_D2s_v3 --enable-addons monitoring --generate-ssh-keys*__
* install kubectl: __*az aks install-cli*__
* get credentials (needed for connecting to cluster): __*az aks get-credentials -g myAKSClusterRG -n myAKSCluster*__
* test if it is working: __*kubectl get nodes -o wide*__

Please note the VM Size, for this lab we need nodes/machines with more than 4GB mem

### Desired State:

#### ARM

If you like to use keyvault for storing secrets, please have a look at this [link](https://github.com/Azure/azure-quickstart-templates/tree/master/101-aks)

* cd aks/arm
* create resourcegroup: __*az deployment create -l westeurope --template-file rg-azuredeploy.json --parameters rgName=demoRG rgLocation=westeurope*__ of course you can change the parameters to your likings
* get ID of resourcegroup: __*az group show -n testRG --query id*__
* create service principal: __*az ad sp create-for-rbac -n testClusterSP  --role="Contributor" --scopes YOUR_RESOURCEGROUP_ID*__
* copy the password and the name of the id and put these values in the parameter file : aks-azuredeploy-parameters.json
* edit the other values in aks-azuredeploy-parameters.json as well (make sure that all the GEN-UNIQUE values are replaced)
* create cluster with ARM: __*az group deployment create -n testCluster -g testRG --template-file aks-azuredeploy.json --parameters @./aks-azuredeploy-parameters.json*__


#### Terraform

make sure you have terraform cli installed and that you have an active session (az login)

* cd aks/terraform
* change the values in variables.tfvars (mandatory) other variables, for eg. in variables.tf are optional
* terraform init 
* terraform plan -var-file=variables.tfvars
* terraform apply -var-file=variables.tfvars

## Setup Azure Container Registry

### Scripted

* Create Registry: __*az acr create -n [name of container registry] -g [name of resourcegroup] --admin-enable true --sku Basic*__

### Desired State

#### ARM

* cd aks/arm
* create ACR: __*az group deployment create --template-file acr-azuredeploy.json -g [name of resourcegroup] --parameters acrName=[acr name] acrStorageAccountName=[storage account name] location=[location]*__

#### Terraform

* cd aks/terraform
* change values in main.tf
* __*terraform init*__
* __*terraform plan*__
* __*terraform apply -auto-aprove*__

### Scale cluster with additional nodes

* list current nodes: __*kubectl get nodes*__
* list current aks cluster: __*az aks list -o table*__
* scale: az aks scale --node-count [desired amount of nodes] -g [resourcegroup] -n [name of cluster]

## Basic Kubernetes

### Watch Kubernetes Console

* list clusters: __*az aks list -o table*__
* tunnel console: __*az aks browse -n [name of cluster] -g [name of resourcegroup]*__ 

### Namespace

* list namespaces: __*kubectl get ns*__
* create namespace: __*kubectl create ns [name of namespace]*__
* list deployments in the kube-system namespace: __*kubectl get deploy -n kube-system*__
* list pods over all namespace: __*kubectl get pods --all-namespaces*__

### Context

* List contexts: __*kubectl config get-contexts*__
* Switch context: __*kube config set-context [context name]*__
* Switch default namespace: __*kubectl config set-context [context name] --namespace [namespace name]*__


## Deploy  Game of Thrones Application

This application depends on redis:
* deploy: __*kubectl run redis --image redis*__
* expose as service __*kubectl expose deployment redis --port 6379*__

Bonus: make redis part of the GOT application (hint use helm)

### Install GOT app with kubectl

* change code...or not
* cd got-app
* create image __*docker build -t [your dockerhub account]/[your image name] .*__
* push image to dockerhub __*docker push [your dockerhub account]/[your image name]*__
* Deploy __*kubectl run [deployment name] --image [your dockerhub account]/[your image name]*__
* check if deployment is up and running: __*kubectl get pods -w*__ or __*kubectl get deploy*__
* check logs/ troubleshoot
  * __*kubectl logs -f [pod name]*__
  * __*kubectl describe [pod name]*__
* expose app as service to internet: __*kubectl expose deployment [name of deployment]  --type LoadBalancer*__

### Install GOT app with DRAFT

Install draft cli: https://draft.sh/

* change code...or not
* cd got-app
* __*draft init*__
* list your registries: __*az acr list -o table*__
* setup your registry: __*draft config set registry [ fqd of your registry ]*__
* login to your registry: __*az acr login -n [ name of your acr ]*__
* create required files: __*draft create*__
* review the draft.toml file
* review the charts (is helm)
* change the values in charts/python/values.yaml
  * change service.type from ClusterIP to LoadBalancer
  * change internalPort from 8080 to 5000
* deploy app to kubernetes: __*draft up*__

### Setup application logging with EFK

* Go to new folder, for eg __*cd /tmp*__
* Clone repo: git clone this repo: __*git clone https://github.com/chrisvugrinec/aks-logging.git*__
* cd elastic-fluentd-kibana
* label all the nodes in the cluster: __*1_labelNodes.sh*__
* create the namespace, storage types and install elastic search __*2_elasticSearch.sh*__
* create config and installation of fluentd: __*3_fluentd.sh*__
* install kibana: __*4_kibana.sh*__

Bonus: Expose Kibana service to private VNET, tip test locally first with: kubectl port-forward [name of kibana pod] -n efk-demo :5601

Check if everything is up and running: __*kubectl get pods -n efk-demo*__

Connect to the public IP addres: __*kubectl get svc -n efk-demo*__
Create the index (can take a while) and play with some logging/ reports....
* create query
* create visualization
* create dashboard

### Install OSBA, move REDIS to PAAS

Install and config helm: https://helm.sh/

* helm init --upgrade
* helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
* helm repo update
* helm install svc-cat/catalog --name catalog --namespace catalog --set controllerManager.healthcheck.enabled=false
* helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
* helm repo update
* SERVICE_PRINCIPAL=$(az ad sp create-for-rbac)
* AZURE_CLIENT_ID=$(echo $SERVICE_PRINCIPAL | cut -d '"' -f 4)
* AZURE_CLIENT_SECRET=$(echo $SERVICE_PRINCIPAL | cut -d '"' -f 16)
* AZURE_TENANT_ID=$(echo $SERVICE_PRINCIPAL | cut -d '"' -f 20)
* AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
* helm install azure/open-service-broker-azure --name osba --namespace osba \
    --set azure.subscriptionId=$AZURE_SUBSCRIPTION_ID \
    --set azure.tenantId=$AZURE_TENANT_ID \
    --set azure.clientId=$AZURE_CLIENT_ID \
    --set azure.clientSecret=$AZURE_CLIENT_SECRET


## Implement basic Security
### Namespace management
### Exposure of services
## Infrastructure logging
### Setup prometheus
### Look at Integrated logging (Application Insights)
## Config Autoscaling
### Chatbot scaler

## Troubeshooting

### RBAC issue

* Error: release catalog failed: namespaces "catalog" is forbidden: User "system:serviceaccount:kube-system:default" cannot get namespaces in the namespace "catalog"
  * kubectl create clusterrolebinding kube-catalog -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:default
