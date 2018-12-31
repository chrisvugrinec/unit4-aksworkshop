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

clone the repository: __*git clone https://github.com/chrisvugrinec/unit4-aksworkshop.git*__


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

You can also follow the instructions [here](https://docs.microsoft.com/en-us/azure/terraform/terraform-create-k8s-cluster-with-tf-and-aks?toc=%2Fen-us%2Fazure%2Faks%2FTOC.json&bc=%2Fen-us%2Fazure%2Fbread%2Ftoc.json)

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

#### Install OSBA

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

#### Install svcat cli

* Have a look at: https://github.com/Azure/service-catalog-cli
* See available classes: __*svcat get classes*__

#### Move from redis k8 to redis PAAS

* create redis cache: __*az redis create -g [name of resourcegroup] -n [name of redis] -l [location] --sku Basic --vm-size C0*__
* go to the portal and copy the hostname and key
* add secret.yaml to charts/python/templates/
* add the following part to: charts/python/values.yaml
```
secret:
  name: redissecret
  redishost: xxxREDIS HOSTxxx
  rediskey: xxxREDIS KEYxxxx
```

* Change the sourcecode so that it is using the environment variables
* Add the following part to: charts/python/templates/deployment.yaml, this should be within the container indentation

```
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        env:
          - name: REDIS_HOST
            valueFrom:
              secretKeyRef:
                name: redissecret
                key: redisHost
          - name: REDIS_KEY
            valueFrom:
              secretKeyRef:
                name: redissecret
                key: redisKey
        imagePullPolicy: {{ .Values.image.pullPolicy }}
```
Check the portal, the redis cli, you should be able to see the values with the following command: keys ```*```

## Implement basic Security

https://docs.bitnami.com/kubernetes/how-to/configure-rbac-in-your-kubernetes-cluster/

## Infrastructure logging

### Setup prometheus

* add the helm repo: __*helm repo add coreos*__  https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
* install helm prometheus operator package: __*helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring*__
* install kubernetes specific metrics: __*helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring*__
* checkout grafana: __*kubectl port-forward $(kubectl get  pods --selector=app=kube-prometheus-grafana -n  monitoring --output=jsonpath="{.items..metadata.name}") -n monitoring  3000*__

### Look at Integrated logging (Application Insights)

If aks cluster has no monitoring (app insights enabled) do so in the portal, have a look in the monitoring tab...it will contain AKS cluster monitoring as well...please note initial data will take a while to appear

## Config and test Autoscaling

Instructions from: https://docs.microsoft.com/en-us/azure/aks/autoscaler

* create the secret 
  * __*cd autoscaler*__
  * __*./createSecret.sh > secret.yaml*__
  * __*create -f secret.yaml*__
* do the autoscaler deployment: __*kubectl create -f aks-cluster-autoscaler.yaml*__
* check scaler status: __*kubectl -n kube-system describe configmap cluster-autoscaler-status*__
* if metrics is not installed:
  * __*git clone https://github.com/kubernetes-incubator/metrics-server.git*__
  * __*kubectl create -f metrics-server/deploy/1.8+/*__


Test it:

* Horizontal Pod Autoscaler:
  * deploy the cats and the dogs app: __*create -f cats-and-dogs.yaml*__
  * create autoscaling rule for frontend deployment: __*kubectl autoscale deployment azure-vote-front --cpu-percent=50 --min=3 --max=10*__
  * check hpa: __*kubectl get hpa*__




Bonus: Autoscale and app using the [aci-connector](https://azure.microsoft.com/en-us/resources/samples/virtual-kubelet-aci-burst/)

## Troubeshooting

### RBAC issue

* Error: release catalog failed: namespaces "catalog" is forbidden: User "system:serviceaccount:kube-system:default" cannot get namespaces in the namespace "catalog"
  * __*kubectl create clusterrolebinding kube-catalog -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:default*__
* nodes is forbidden: User "system:serviceaccount:kube-system:kubernetes-dashboard" cannot list nodes at the cluster scope
  * __*kubectl create clusterrolebinding kube-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard*__
