variable "name" {
  description = "Name of the Container App."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the Container App."
  type        = string
}

variable "container_app_environment_id" {
  description = "Resource ID of the Container App Environment."
  type        = string
}

variable "uami_id" {
  description = "Resource ID of the user assigned identity attached to the Container App."
  type        = string
}

variable "image" {
  description = "Container image to deploy (e.g. nginx:1.27-alpine)."
  type        = string
}

variable "port" {
  description = "Port the container listens on."
  type        = number
}

variable "cpu" {
  description = "CPU allocation per container replica (e.g. 0.25)."
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory allocation per container replica (e.g. '0.5Gi')."
  type        = string
  default     = "0.5Gi"
}

variable "external_enabled" {
  description = "Whether the ingress is externally accessible. Defaults to false (internal only)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the Container App."
  type        = map(string)
  default     = {}
}
