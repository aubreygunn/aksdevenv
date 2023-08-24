# Terraform - Azure Kubernetes Service deployment

Setting up an Azure Kubernetes Service (AKS) using terraform, is fairly easy. Setting up a full-fledged AKS cluster that can read images from Azure Container Registry (ACR), fetch secrets from Azure Key Vault using Pod Identity while all traffic is routed via an AKS managed Application Gateway is much harder.

This repository serves as a boilerplate for the scenario described above, and fully deploys and configures your Azure Kubernetes Service in the cloud using a single terraform deployment.

## Architecture

![Architecture Diagram AKS deployment](images/archdiagram_k8s.png?raw=true "Architecture Diagram AKS deployment")

The architecture consists of the following components:

__Public IP__ —
 Public IP addresses enable Azure resources to communicate to Internet and public-facing Azure services.

__Application Gateway__ —
Azure Application Gateway is a web traffic load balancer that enables you to manage traffic to your web applications.

All traffic that accesses the AKS cluster is routed via an Azure Application Gateway. The Application Gateway acts as a Load Balancer and routes the incoming traffic to the corresponding services in AKS.

Specifically, Application Gateway Ingress Controller (AGIC) is used. This Ingress Controller is deployed on the AKS Cluster on its own pod. AGIC monitors the Kubernetes cluster it is hosted on and continuously updates an Application Gateway, so that selected services are exposed to the Internet on the specified URL paths & ports straight from the Ingress rules defined in AKS.

__Azure Kubernetes Service (AKS)__ —
AKS is an Azure service that deploys a managed Kubernetes cluster.

Azure Kubernetes Service (AKS) makes it simple to deploy a managed Kubernetes cluster in Azure. Kubernetes is an open-source container orchestration platform that automates many of the manual processes involved in deploying, managing, and scaling containerized applications. Having this cluster is ideal when you want to run multiple containerized services and don't want to worry about managing and scaling them.

__Virtual Network__ —
An Azure Virtual Network (VNet) is used to securely communicate between AKS and Application Gateway and control all outbound connections.

__Virtual Network subnets__ —
Application Gateway and AKS are deployed in their own subnets within the same virtual network.

__External Data Sources__ —
Microservices are typically stateless and write state to external data stores, such as CosmosDB.

__Azure Key Vault__ —
Azure Key Vault is a cloud service for securely storing and accessing secrets and certificates.

Some of the services in the AKS cluster connect to external services. The connection strings and other secret values that are needed by the pods are stored in Azure Key Vault. By storing these variables in Key Vault, we ensure that these secrets are not versioned in the git repository as code, and not accessible to anyone that has access to the AKS cluster.

To securely mount these connection strings, pod identity is used to mount these secrets in the pods and make them available to the container as environment variables.

__Pod Identity__ —
Pod Identity enables Kubernetes applications to access cloud resources securely with Azure Active Directory.

AAD Pod Identity enables Kubernetes applications to access cloud resources securely with Azure Active Directory. It's best practice to not use fixed credentials within pods or container images, as they are at risk of exposure or abuse. Instead, we're using pod identities to request access using Azure AD.

When a pod needs access to other Azure services, such as Cosmos DB, Key Vault, or Blob Storage, the pod needs access credentials. You don't manually define credentials for pods, instead they request an access token in real time, and can use it to only access their assigned services that are defined for that identity.

Pod Identity is fully configured on the AKS cluster when the Terraform script is deployed, and pods inside the AKS cluster can use the preconfigured pod identity by specifying the corresponding aadpodidbinding pod label.

__Azure Active Directory__ —
Azure Active Directory (Azure AD) is Microsoft's cloud-based identity and access management service. Pod Identity uses Azure AD to create and manage other Azure resources such as Azure Application Gateway and Azure Key Vault.

__Azure Container Registry__ —
Container Registry is used to store private Docker images, which are deployed to the cluster. AKS can authenticate with Container Registry using its Azure AD identity.

Azure Container Registry (ACR) is a managed Docker registry service, and it allows you to store and manage images for all types of container deployments. Every service can be pushed to its own repository in Azure Container Registry and every codebase change in a specific service can trigger a pipeline that pushes a new version for that container to ACR with a unique tag.

AKS and ACR integration is setup during the deployment of the AKS cluster with Terraform. This allows the AKS cluster to interact with ACR, using an Azure Active Directory service principal. The Terraform deployment automatically configures RBAC permissions for the ACR resources with an appropriate ACRPull role for the service principal.

With this integration in place, AKS pods can fetch any of the Docker images that are pushed to ACR, even though ACR is setup as a private docker registry. Don't forget to add the azurecr.io prefix for the container and specify a tag. It is best practice to not use that :latest tag since this image always points to the latest image pushed to your repository and might introduce unwanted changes. Always pinpoint the container to a specific version and update that version in your yaml file when you want to upgrade.

__KEDA__ —
KEDA is a Kubernetes-based Event Driven Autoscaler that (horizontally) scales a container by adding additional pods based on the number of events needing to be processed.

## Input Variables

| Name | Description | Default |
|------|-------------|---------|
| `app_name` | Application name (used as suffix in all resources) |  | 
| `location` | Azure region where to create resources | West Europe | 
| `domain_name_label` | Unique domain name label for AKS Cluster |  | 
| `kubernetes_version` | Kubernetes version of the node pool | 1.19.7 | 
| `vm_size_node_pool` | VM Size of the node pool | Standard_D2s_v3 | 
| `node_pool_min_count` | VM minimum amount of nodes for the node pool | 3 | 
| `node_pool_max_count` | VM maximum amount of nodes for the node pool | 5 | 
| `helm_pod_identity_version` | Helm chart version of aad-pod-identity | 4.1.1 | 
| `helm_csi_secrets_version` | Helm chart version of secrets-store-csi-driver-provider-azure | 0.0.18 | 
| `helm_agic_version` | Helm chart version of ingress-azure-helm-package | 1.4.0 | 
| `helm_keda_version` | Helm chart version of keda helm package | 2.3.2 | 

## Output variables

| Name | Description |
|------|-------------|
| `aks_name` | Name of the AKS cluster |
| `appgw_name` | Name of the Application Gateway used by AKS |
| `appgw_fqdn` | Domain name of the cluster (e.g. `label.westeurope.cloudapp.azure.com`) |
| `acr_name` | Name of the Azure Container Registry |
| `keyvault_name` | Name of the Azure Key Vault |
| `log_analytics_name` | Name of the Log Analytics workspace |
| `vnet_name` | Name of the Virtual Network |
| `rg_name` | Name of the Resource Group |