# Azure Managed DevOps Pool with Terraform

This repository provides a fully functional Terraform script for creating an **Azure Managed DevOps Pool**. By leveraging Microsoft-hosted runner images (or your own custom images), you can streamline your CI/CD pipelines without maintaining Azure Virtual Machine Scale Sets. For more details and context, check out the [article on AzureWay.cloud](https://azureway.cloud).

## Prerequisites
- Adequate **Resource Quotas** in your Azure subscription. The default setting is to create 4 agents, so you need at least 8 vCPUs
- **Azure Subscription** access to register providers
- **Administrator Role** on the desired Agent Pools in Azure DevOps in the Organization and Project level

## Getting Started

1. **Clone this repository**.  
2. **Configure your environment** by creating a `main.auto.tfvars` file with values for these variables:

    ```hcl
    spn-client-id                  = "PRINCIPAL_CLIENT_ID"
    spn-tenant-id                  = "TENANT_ID"
    azure_devops_organization_name = "ADO_ORGANIZATION"
    subscription-id                = "SUBSCRIPTION_ID"
    ado_project_id                 = "ADO_PROJECT_ID"
    pipeline_ids                   = ["PIPELINE_ID"]
    ```
3. **Initialize Terraform**:

    ```bash
    terraform init
    ```

4. **Review your plan**:

    ```bash
    terraform plan
    ```

5. **Apply the changes**:

    ```bash
    terraform apply -var="spn-client-secret=$SPN_CLIENT_SECRET}}"
    ```
