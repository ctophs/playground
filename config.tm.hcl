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
  # Modules live in this repo under modules/. Terraform fetches them via git
  # using the // subdirectory syntax. Bump the version tag to roll out changes.
  resource_group = {
    source  = "git::https://github.com/ctophs/playground.git//modules/resource-group"
    version = "v1.0.0"
  }
  user_assigned_identity = {
    source  = "git::https://github.com/ctophs/playground.git//modules/user-assigned-identity"
    version = "v1.0.0"
  }
  container_app_environment = {
    source  = "git::https://github.com/ctophs/playground.git//modules/container-app-environment"
    version = "v1.0.0"
  }
  container_app = {
    source  = "git::https://github.com/ctophs/playground.git//modules/container-app"
    version = "v1.0.0"
  }
}
