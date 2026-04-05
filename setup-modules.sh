#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# setup-modules.sh
# Creates and pushes all 4 Terraform module repos to GitHub.
# Usage: ./setup-modules.sh <github-org>
#   e.g. ./setup-modules.sh ctophs
# Requires: git, a GitHub account with push access to the 4 repos.
# ---------------------------------------------------------------------------
set -euo pipefail

ORG="${1:-ctophs}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Working in $WORK_DIR"
echo "GitHub org/user: $ORG"
echo ""

# ---------------------------------------------------------------------------
# Helper: init repo, commit, tag, push
# ---------------------------------------------------------------------------
push_module() {
  local name="$1"
  local dir="$WORK_DIR/$name"
  mkdir -p "$dir/tests"

  echo "=== $name ==="
  write_files_$name "$dir"

  cd "$dir"
  git init
  git checkout -b main
  git add .
  git commit -m "feat: initial module implementation"
  git tag v1.0.0
  git remote add origin "https://github.com/$ORG/$name.git"
  git push -u origin main
  git push origin v1.0.0
  cd -
  echo ""
}

# ---------------------------------------------------------------------------
# versions.tf shared content
# ---------------------------------------------------------------------------
versions_tf() {
  cat <<'EOF'
terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}
EOF
}

# ===========================================================================
# Module: terraform-azure-resource-group
# ===========================================================================
write_files_terraform-azure-resource-group() {
  local d="$1"

  versions_tf > "$d/versions.tf"

  cat > "$d/variables.tf" <<'EOF'
variable "name" {
  description = "Name of the resource group."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region for the resource group."
  type        = string
}

variable "tags" {
  description = "Tags applied to the resource group."
  type        = map(string)
  default     = {}
}
EOF

  cat > "$d/main.tf" <<'EOF'
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
EOF

  cat > "$d/outputs.tf" <<'EOF'
output "name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "id" {
  description = "Resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "location" {
  description = "Location of the resource group."
  value       = azurerm_resource_group.this.location
}
EOF

  cat > "$d/tests/resource_group.tftest.hcl" <<'EOF'
mock_provider "azurerm" {}

run "creates_resource_group_with_correct_attributes" {
  command = plan

  variables {
    name     = "rg-monitoring-test-apps"
    location = "westeurope"
    tags     = { environment = "test", workload = "monitoring" }
  }

  assert {
    condition     = azurerm_resource_group.this.name == "rg-monitoring-test-apps"
    error_message = "Resource group name mismatch."
  }

  assert {
    condition     = azurerm_resource_group.this.location == "westeurope"
    error_message = "Location mismatch."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["environment"] == "test"
    error_message = "Tag 'environment' mismatch."
  }
}

run "rejects_empty_name" {
  command = plan

  variables {
    name     = ""
    location = "westeurope"
    tags     = {}
  }

  expect_failures = [var.name]
}
EOF
}

# ===========================================================================
# Module: terraform-azure-user-assigned-identity
# ===========================================================================
write_files_terraform-azure-user-assigned-identity() {
  local d="$1"

  versions_tf > "$d/versions.tf"

  cat > "$d/variables.tf" <<'EOF'
variable "name" {
  description = "Name of the user assigned identity."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the identity."
  type        = string
}

variable "location" {
  description = "Azure region for the identity."
  type        = string
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
  default     = {}
}
EOF

  cat > "$d/main.tf" <<'EOF'
resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
EOF

  cat > "$d/outputs.tf" <<'EOF'
output "id" {
  description = "Resource ID of the user assigned identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Principal ID — used for role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID — used to configure SDK authentication."
  value       = azurerm_user_assigned_identity.this.client_id
}
EOF

  cat > "$d/tests/user_assigned_identity.tftest.hcl" <<'EOF'
mock_provider "azurerm" {}

run "creates_identity_with_correct_attributes" {
  command = plan

  variables {
    name                = "id-cae-monitoring-test"
    resource_group_name = "rg-monitoring-test-identities"
    location            = "westeurope"
    tags                = { environment = "test" }
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.name == "id-cae-monitoring-test"
    error_message = "Identity name mismatch."
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.resource_group_name == "rg-monitoring-test-identities"
    error_message = "Resource group name mismatch."
  }
}
EOF
}

# ===========================================================================
# Module: terraform-azure-container-app-environment
# ===========================================================================
write_files_terraform-azure-container-app-environment() {
  local d="$1"

  versions_tf > "$d/versions.tf"

  cat > "$d/variables.tf" <<'EOF'
variable "name" {
  description = "Name of the Container App Environment."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the environment."
  type        = string
}

variable "location" {
  description = "Azure region for the environment."
  type        = string
}

variable "uami_id" {
  description = "Resource ID of the user assigned identity attached to the environment."
  type        = string
}

variable "infrastructure_subnet_id" {
  description = <<-EOT
    Resource ID of the subnet for VNet integration.
    Required when internal_load_balancer_enabled = true.
    The subnet must be at least /27 and delegated to Microsoft.App/environments.
  EOT
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Whether the environment uses an internal load balancer. Requires infrastructure_subnet_id."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the environment."
  type        = map(string)
  default     = {}
}
EOF

  cat > "$d/main.tf" <<'EOF'
resource "azurerm_container_app_environment" "this" {
  name                           = var.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  tags                           = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_id]
  }
}
EOF

  cat > "$d/outputs.tf" <<'EOF'
output "id" {
  description = "Resource ID of the Container App Environment."
  value       = azurerm_container_app_environment.this.id
}

output "name" {
  description = "Name of the Container App Environment."
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "Default domain of the Container App Environment."
  value       = azurerm_container_app_environment.this.default_domain
}
EOF

  cat > "$d/tests/container_app_environment.tftest.hcl" <<'EOF'
mock_provider "azurerm" {}

run "creates_environment_with_consumption_profile" {
  command = plan

  variables {
    name                = "cae-monitoring-test"
    resource_group_name = "rg-monitoring-test-apps"
    location            = "westeurope"
    uami_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-test-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-cae-monitoring-test"
    tags                = { environment = "test" }
  }

  assert {
    condition     = azurerm_container_app_environment.this.name == "cae-monitoring-test"
    error_message = "Environment name mismatch."
  }

  assert {
    condition     = azurerm_container_app_environment.this.workload_profile[0].name == "Consumption"
    error_message = "Workload profile name must be 'Consumption'."
  }

  assert {
    condition     = azurerm_container_app_environment.this.workload_profile[0].workload_profile_type == "Consumption"
    error_message = "Workload profile type must be 'Consumption'."
  }
}

run "creates_internal_environment_with_subnet" {
  command = plan

  variables {
    name                           = "cae-monitoring-prod"
    resource_group_name            = "rg-monitoring-prod-apps"
    location                       = "westeurope"
    uami_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-prod-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-cae-monitoring-prod"
    infrastructure_subnet_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-cae"
    internal_load_balancer_enabled = true
    tags                           = { environment = "prod" }
  }

  assert {
    condition     = azurerm_container_app_environment.this.internal_load_balancer_enabled == true
    error_message = "Internal LB should be enabled."
  }
}
EOF
}

# ===========================================================================
# Module: terraform-azure-container-app
# ===========================================================================
write_files_terraform-azure-container-app() {
  local d="$1"

  versions_tf > "$d/versions.tf"

  cat > "$d/variables.tf" <<'EOF'
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
EOF

  cat > "$d/main.tf" <<'EOF'
resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_id]
  }

  template {
    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory
    }
  }

  ingress {
    external_enabled = var.external_enabled
    target_port      = var.port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
EOF

  cat > "$d/outputs.tf" <<'EOF'
output "id" {
  description = "Resource ID of the Container App."
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "Name of the Container App."
  value       = azurerm_container_app.this.name
}

output "fqdn" {
  description = "Fully qualified domain name of the Container App ingress."
  value       = azurerm_container_app.this.ingress[0].fqdn
}
EOF

  cat > "$d/tests/container_app.tftest.hcl" <<'EOF'
mock_provider "azurerm" {}

run "creates_internal_container_app" {
  command = apply

  variables {
    name                         = "ca-gatus-monitoring-test"
    resource_group_name          = "rg-monitoring-test-apps"
    container_app_environment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-test-apps/providers/Microsoft.App/managedEnvironments/cae-monitoring-test"
    uami_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-test-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-ca-gatus-monitoring-test"
    image                        = "ghcr.io/twinproduction/gatus:latest"
    port                         = 8080
    tags                         = { environment = "test" }
  }

  assert {
    condition     = azurerm_container_app.this.name == "ca-gatus-monitoring-test"
    error_message = "Container App name mismatch."
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].image == "ghcr.io/twinproduction/gatus:latest"
    error_message = "Container image mismatch."
  }

  assert {
    condition     = azurerm_container_app.this.ingress[0].external_enabled == false
    error_message = "Ingress should default to internal."
  }

  assert {
    condition     = azurerm_container_app.this.ingress[0].target_port == 8080
    error_message = "Target port mismatch."
  }
}
EOF
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
push_module "terraform-azure-resource-group"
push_module "terraform-azure-user-assigned-identity"
push_module "terraform-azure-container-app-environment"
push_module "terraform-azure-container-app"

echo "Done. All 4 modules pushed to github.com/$ORG with tag v1.0.0."
