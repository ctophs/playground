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
    error_message = "Ingress should default to internal (external_enabled = false)."
  }

  assert {
    condition     = azurerm_container_app.this.ingress[0].target_port == 8080
    error_message = "Target port mismatch."
  }
}

run "creates_external_container_app" {
  command = plan

  variables {
    name                         = "ca-nginx-monitoring-test"
    resource_group_name          = "rg-monitoring-test-apps"
    container_app_environment_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-test-apps/providers/Microsoft.App/managedEnvironments/cae-monitoring-test"
    uami_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-test-identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-ca-nginx-monitoring-test"
    image                        = "nginx:1.27-alpine"
    port                         = 80
    external_enabled             = true
    tags                         = { environment = "test" }
  }

  assert {
    condition     = azurerm_container_app.this.ingress[0].external_enabled == true
    error_message = "External ingress should be enabled."
  }
}
