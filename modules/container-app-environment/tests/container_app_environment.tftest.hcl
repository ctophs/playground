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

  assert {
    condition     = azurerm_container_app_environment.this.internal_load_balancer_enabled == false
    error_message = "Internal LB should default to false."
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

  assert {
    condition     = azurerm_container_app_environment.this.infrastructure_subnet_id != null
    error_message = "Subnet ID should be set."
  }
}
