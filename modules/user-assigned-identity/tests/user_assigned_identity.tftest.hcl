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
