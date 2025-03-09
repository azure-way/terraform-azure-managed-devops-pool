variable "azure_devops_organization_name" {
  type        = string
  description = "Azure DevOps Organisation Name"
}

variable "region" {
  type        = string
  description = "The region in which the resources will be deployed."
  default     = "swedencentral"

}

variable "enable_telemetry" {
  type        = bool
  description = "Enable telemetry for the module."
  default     = false
}

variable "maximum_concurrency" {
  type        = number
  description = "The maximum number of concurrent jobs that can run on the pool."
  default     = 4

}
variable "address_space" {
  type        = list(string)
  description = "The address space that is used the virtual network."
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "The address prefixes that are used for the subnets."
  default     = ["10.0.1.0/24"]

}

variable "azure_devops_project_names" {
  type        = list(string)
  description = "The names of the Azure DevOps projects to be created."
  default     = ["basic-pipelines"]
}

variable "azure_devops_build_definition_name" {
  type        = string
  description = "The name of the build definition."
  default     = "basic-pipelines"

}

variable "ado_project_id" {
  type        = string
  description = "The Azure DevOps project ID"
}

variable "spn-client-id" {
  description = "Client ID of the service principal"
}

variable "spn-client-secret" {
  description = "Secret for service principal"
}

variable "spn-tenant-id" {
  description = "Tenant ID for service principal"
}

variable "subscription-id" {

}

variable "pipeline_ids" {
  description = "The ID of the pipeline"
  type        = list(string)
}

variable "agent_profile_resource_predictions" {
  description = "Values for agents scheduling"
  type        = map(object({
    time_zone = string
    days_data = list(map(string))
  }))
  default  = {
    time_zone = "UTC"
    days_data = [
      # Sunday
      {},
      # Monday
      {
        "06:00:00" = 1
        "08:00:00" = 2
        "18:00:00" = 0
      },
      # Tuesday
      {
        "06:00:00" = 4
        "08:00:00" = 2
        "18:00:00" = 1
        "20:00:00" = 0
      },
      # Wednesday
      {
        "06:00:00" = 1
        "08:00:00" = 2
        "19:00:00" = 1
        "22:00:00" = 0
      },
      # Thursday
      {
        "06:00:00" = 1
        "08:00:00" = 2
        "17:00:00" = 0
      },
      # Friday
      {
        "06:00:00" = 1
        "08:00:00" = 2
        "18:00:00" = 1
        "20:00:00" = 0
      },
      # Saturday
      {}
    ]
  }
}