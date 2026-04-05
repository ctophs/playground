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
