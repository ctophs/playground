# ---------------------------------------------------------------------------
# Code generation — applies to ALL stacks.
# Files prefixed with _tm_ are Terramate-managed; do not edit them manually.
# ---------------------------------------------------------------------------

generate_hcl "_tm_provider.tf" {
  content {
    terraform {
      required_version = global.terraform.version

      required_providers {
        azurerm = {
          source  = global.terraform.providers.azurerm.source
          version = global.terraform.providers.azurerm.version
        }
      }
    }

    provider "azurerm" {
      subscription_id = global.azure.subscription_id
      tenant_id       = global.azure.tenant_id
      use_cli         = true

      features {}
    }
  }
}

generate_hcl "_tm_backend.tf" {
  content {
    terraform {
      backend "local" {
        # Unique state path per stack, stored outside the stack directory.
        path = "${terramate.root.path.fs.absolute}/.terraform-state/${terramate.stack.path.relative}/terraform.tfstate"
      }
    }
  }
}
