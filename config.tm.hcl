# ---------------------------------------------------------------------------
# Root-level globals — inherited by every stack in the project.
# ---------------------------------------------------------------------------

globals "azure" {
  tenant_id = "00000000-0000-0000-0000-000000000000" # replace with your tenant ID
  location  = "westeurope"
}

globals "azure" "tags" {
  managed_by  = "terraform"
  provisioner = "terramate"
}

globals "terraform" {
  version = "~> 1.9"
}

globals "terraform" "providers" "azurerm" {
  source  = "hashicorp/azurerm"
  version = "~> 4.0"
}

globals "terraform" "modules" {
  # Each module lives in its own repo, versioned independently via Git tags.
  resource_group = {
    source  = "git::https://github.com/org/terraform-azure-resource-group.git"
    version = "v1.0.0"
  }
  user_assigned_identity = {
    source  = "git::https://github.com/org/terraform-azure-user-assigned-identity.git"
    version = "v1.0.0"
  }
  container_app_environment = {
    source  = "git::https://github.com/org/terraform-azure-container-app-environment.git"
    version = "v1.0.0"
  }
  container_app = {
    source  = "git::https://github.com/org/terraform-azure-container-app.git"
    version = "v1.0.0"
  }
}
