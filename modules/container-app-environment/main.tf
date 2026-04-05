resource "azurerm_container_app_environment" "this" {
  name                           = var.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  infrastructure_subnet_id       = var.infrastructure_subnet_id != null ? var.infrastructure_subnet_id : null
  internal_load_balancer_enabled = var.infrastructure_subnet_id != null ? var.internal_load_balancer_enabled : null
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
